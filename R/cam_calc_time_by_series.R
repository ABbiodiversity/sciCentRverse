#' Calculate time-in-front-of-camera by series (in seconds)
#'
#' @description
#' Groups consecutive images into per-species "series" at each deployment using a
#' time-gap threshold, then converts image timestamps into *time-in-front-of-camera*
#' (TIFC) in seconds. Bookend images of a series get an extra `tbp/2` to account
#' for shutter cadence; interior images receive half the time to previous and next.
#'
#' @details
#' **Inputs & filtering**
#' * Excludes rows with `species_common_name` in `c("STAFF/SETUP","NONE")` and
#'   any with `individual_count == "VNA"`.
#' * `image_date_time` must be POSIXct; the function stops if not.
#' * Rows are de-duplicated on (`project`,`location`,`image_id`,`species_common_name`,
#'   `image_date_time`,`individual_count`) to avoid double-counting.
#'
#' **Series definition**
#' * Within each `project × location × species_common_name`, rows are sorted by
#'   `image_date_time` (then `image_id`) and the previous-gap (seconds) is computed.
#' * A new series starts at the first image or when the gap exceeds `split_gap_secs`
#'   (default 120 s). `series_num` is the cumulative count of such starts.
#' * [cam_obtain_n_gap_class()] is called internally to detect NONE-bridged gaps —
#'   cases where an animal image is separated from the next same-species image by one
#'   or more `NONE` rows. These boundaries also force a new series regardless of the
#'   time gap, preventing a NONE-bridged pair from inflating a single series duration.
#'
#' **Per-image time allocation**
#' * For each image, `diff_prev_s` is the elapsed time since the previous image in
#'   the same series; `diff_next_s` is the time until the next image in the same
#'   series. Bookends get zeros on the missing side.
#' * Interior image time: `(diff_prev_s + diff_next_s)/2`.
#' * Bookend image time: `((diff_prev_s + diff_next_s)/2) + (tbp/2)`.
#' * Image time is multiplied by `individual_count` (coerced numeric) to obtain
#'   `image_time_ni_s`.
#' * Note: a single-image series receives `tbp/2` (not `tbp`) unless you choose to
#'   post-adjust downstream.
#'
#' **Probabilistic gap adjustment** (`adjust_gap_prob = TRUE`)
#'
#' Within-series gaps of 20–120 s fall in an ambiguous zone: the gap is too short
#' to confidently split into a new series, but long enough that the animal may
#' have temporarily left the camera's field of view (FOV). To account for this,
#' a species-group-specific probability of FOV departure (`pred`) is looked up from
#' the internal `leave_prob_pred` table (derived from empirical gap-length models)
#' and applied to both sides of the gap:
#'
#' \deqn{diff\_prev\_adj = diff\_prev \times (1 - pred)}
#' \deqn{diff\_next\_adj = diff\_next \times (1 - pred)}
#'
#' This reduces the time credited across the gap proportionally to how likely it
#' is the animal was absent. A gap of exactly 20 s receives only a small reduction;
#' a gap near 120 s receives a much larger one.
#'
#' Species are assigned to gap groups via the internal `gap_groups` lookup. Any
#' species not present in that lookup (e.g., uncommonly detected taxa) receives
#' no adjustment — their within-series gaps are treated as though the animal was
#' continuously present. If this concerns you for a given analysis, set
#' `adjust_gap_prob = FALSE` to disable the adjustment entirely and inspect
#' results under both assumptions.
#'
#' **Time-between-photos (tbp)**
#' * Supply `tbp_lookup` with columns `species_common_name`, `tbp` (seconds),
#'   or let the function try to use an internal package object `tbi` (from
#'   `R/sysdata.rda`). If neither is available, a warning is issued and `tbp = 6`
#'   seconds is used as a fallback.
#' * If `tbp_lookup` uses a different tbp column name (e.g., `time_between_photos`,
#'   `tbi`, `tbp_seconds`), it is re-mapped to `tbp`.
#'
#' @param cons_main_report Data frame (after [cam_consolidate_tags()]) with at least:
#'   project, location, image_id, image_date_time (POSIXct),
#'   species_common_name, individual_count
#' @param split_gap_secs Gap threshold to start a new series (seconds). Default 120.
#' @param tbp_lookup Optional tibble with per-species time-between-photos `tbp` (seconds).
#'   Columns required: `species_common_name`, `tbp`. If `NULL`, the function will
#'   try to use the internal package object `tbi` (from R/sysdata.rda). If that is
#'   not available, it falls back to tbp = 6 seconds for all species and warns.
#' @param adjust_gap_prob Logical. If `TRUE` (default), applies a species-specific
#'   probability-of-leaving-FOV correction to within-series gaps of 20–120 s, using
#'   the internal `gap_groups` and `leave_prob_pred` lookup tables. Set to `FALSE`
#'   to skip the adjustment and treat all within-series gaps as fully occupied — for
#'   example, to compare results under both assumptions or when working primarily
#'   with species not covered by the gap-group lookup.
#'
#' @return Tibble with one row per series and species:
#'   project, location, species_common_name, series_num, n_images,
#'   series_total_time (seconds), series_start, series_end
#'
#' @examples
#' \dontrun{
#' # cons_report is the output of cam_consolidate_tags()
#'
#' # Standard usage — N-gap detection and probabilistic gap adjustment applied automatically
#' series <- cam_calc_time_by_series(cons_report)
#'
#' # Disable probabilistic adjustment to compare results under both assumptions
#' series_unadj <- cam_calc_time_by_series(cons_report, adjust_gap_prob = FALSE)
#' }
#'
#' @seealso [cam_sum_total_time()], [cam_obtain_n_gap_class()],
#'   [cam_get_op_days()], [cam_summarise_op_by_season()]
#' @author Marcus Becker
#'
#' @export
cam_calc_time_by_series <- function(
    cons_main_report,
    split_gap_secs  = 120,
    tbp_lookup      = NULL,
    adjust_gap_prob = TRUE
) {

  # Resolve tbi lookup: prefer user-supplied, else internal `tbi`, else fallback
  if (is.null(tbp_lookup)) {
    tbp_lookup <- if (exists("tbi", inherits = TRUE)) {
      get("tbi", inherits = TRUE)
    } else {
      warning("No `tbp_lookup` provided and internal `tbi` not found; using tbp = 6s for all species.")
      tibble::tibble(species_common_name = unique(cons_main_report$species_common_name), tbp = 6)
    }
  }
  # Keep only needed cols; tolerate alternative column names `time_between_photos` -> `tbp`
  if (!"tbp" %in% names(tbp_lookup)) {
    alt <- intersect(c("time_between_photos", "tbi", "tbp_seconds"), names(tbp_lookup))
    if (length(alt) == 1) tbp_lookup <- dplyr::rename(tbp_lookup, tbp = !!alt)
  }
  tbp_lookup <- tbp_lookup |>
    dplyr::select(species_common_name, tbp) |>
    dplyr::mutate(tbp = as.numeric(tbp))

  # Resolve leave-probability lookups from internal data
  gap_groups_lkp      <- get("gap_groups",      envir = asNamespace("sciCentRverse"))
  leave_prob_pred_lkp <- get("leave_prob_pred",  envir = asNamespace("sciCentRverse"))

  # Animals only, counts numeric
  d <- cons_main_report |>
    dplyr::filter(!species_common_name %in% c("STAFF/SETUP", "NONE"),
                  individual_count != "VNA") |>
    dplyr::mutate(individual_count = suppressWarnings(as.numeric(individual_count))) |>
    dplyr::distinct(project, location, image_id, species_common_name,
                    image_date_time, individual_count, .keep_all = TRUE)

  # Ensure POSIXct
  if (!inherits(d$image_date_time, "POSIXt")) {
    stop("`image_date_time` must be POSIXct. Parse before calling.", call. = FALSE)
  }

  # Detect N-gap boundaries internally: images whose next same-species detection
  # is separated by a NONE block. These force a new series regardless of time gap.
  n_gap_df <- cam_obtain_n_gap_class(cons_main_report)

  if (nrow(n_gap_df) > 0L) {
    n_gap_keys <- dplyr::distinct(n_gap_df, image_id, species_common_name) |>
      dplyr::mutate(.is_n_gap = TRUE)
    d <- dplyr::left_join(d, n_gap_keys, by = c("image_id", "species_common_name")) |>
      dplyr::mutate(.is_n_gap = dplyr::coalesce(.is_n_gap, FALSE))
  } else {
    d$.is_n_gap <- FALSE
  }

  # Sort & compute gaps within camera and species
  d <- d |>
    dplyr::arrange(project, location, species_common_name, image_date_time, image_id) |>
    dplyr::group_by(project, location, species_common_name) |>
    dplyr::mutate(
      dt_prev    = dplyr::lag(image_date_time),
      gap_prev_s = as.numeric(difftime(image_date_time, dt_prev, units = "secs")),
      # Start a new series if: first image, time gap exceeded, or previous image
      # was an N-gap boundary (animal left FOV through a NONE-bridged gap).
      new_series = dplyr::if_else(
        dplyr::row_number() == 1L |
          gap_prev_s > split_gap_secs |
          dplyr::lag(.is_n_gap, default = FALSE),
        1L, 0L
      ),
      series_num = cumsum(new_series)
    ) |>
    dplyr::ungroup()

  # Within-series prev/next diffs (seconds); bookends get 0 here
  d <- d |>
    dplyr::group_by(project, location, species_common_name, series_num) |>
    dplyr::mutate(
      prev_ts     = dplyr::lag(image_date_time),
      next_ts     = dplyr::lead(image_date_time),
      diff_prev_s = dplyr::if_else(dplyr::row_number() == 1L, 0,
                                   as.numeric(difftime(image_date_time, prev_ts, units = "secs"))),
      diff_next_s = dplyr::if_else(dplyr::row_number() == dplyr::n(), 0,
                                   as.numeric(difftime(next_ts, image_date_time, units = "secs"))),
      is_bookend  = dplyr::row_number() == 1L | dplyr::row_number() == dplyr::n()
    ) |>
    dplyr::ungroup()

  # --- Probabilistic time adjustment for within-series gaps of 20-120 s -------
  # For gaps in this range, the animal may have temporarily left the field of
  # view. The probability of leaving (`pred`) is species-group-specific and
  # gap-length-specific. Both sides of the gap are scaled by (1 - pred).
  if (adjust_gap_prob) {
    d <- d |>
      dplyr::left_join(gap_groups_lkp, by = "species_common_name") |>
      dplyr::mutate(.diff_time_int = as.integer(round(diff_prev_s))) |>
      dplyr::left_join(
        leave_prob_pred_lkp,
        by = c("gap_group" = "gap_group", ".diff_time_int" = "diff_time")
      ) |>
      # pred is NA when gap is outside 20-120 s range or species has no gap group
      dplyr::mutate(
        pred     = dplyr::coalesce(pred, 1),          # default pred=1 -> no adjustment
        gap_prob = diff_prev_s >= 20 & diff_prev_s <= split_gap_secs & !is.na(gap_group),
        # Adjust the gap on this image's "previous" side
        diff_prev_s_adj = dplyr::if_else(gap_prob, diff_prev_s * (1 - pred), diff_prev_s),
        # Adjust the same gap on the next image's "next" side (lead)
        diff_next_s_adj = dplyr::if_else(
          dplyr::lead(gap_prob, default = FALSE),
          diff_next_s * (1 - dplyr::lead(pred, default = 1)),
          diff_next_s
        ),
        diff_next_s_adj = dplyr::if_else(is.na(diff_next_s_adj), 0, diff_next_s_adj)
      ) |>
      dplyr::select(-.diff_time_int)
  } else {
    d <- d |>
      dplyr::mutate(diff_prev_s_adj = diff_prev_s,
                    diff_next_s_adj = diff_next_s)
  }
  # ---------------------------------------------------------------------------

  # Attach tbp (seconds) and warn if any species missing in lookup
  d <- d |>
    dplyr::left_join(tbp_lookup, by = "species_common_name") |>
    dplyr::mutate(tbp = dplyr::coalesce(tbp, 6.0))
  missing_tbp <- d |>
    dplyr::filter(is.na(tbp)) |>
    dplyr::distinct(species_common_name)
  if (nrow(missing_tbp)) {
    warning("Missing `tbp` for species: ",
            paste(utils::head(missing_tbp$species_common_name, 10), collapse = ", "),
            if (nrow(missing_tbp) > 10) " ..." else "",
            ". Using tbp = 6s for those.", call. = FALSE)
    d$tbp[is.na(d$tbp)] <- 6
  }

  # Image-level time (seconds) using adjusted diffs; bookends add tbp/2
  d <- d |>
    dplyr::mutate(
      image_time_s    = dplyr::if_else(
        is_bookend,
        ((diff_prev_s_adj + diff_next_s_adj) / 2) + (tbp / 2),
        (diff_prev_s_adj + diff_next_s_adj) / 2
      ),
      image_time_ni_s = image_time_s * dplyr::coalesce(individual_count, 1)
    )

  # Series roll-up
  out <- d |>
    dplyr::group_by(project, location, species_common_name, series_num) |>
    dplyr::summarise(
      n_images          = dplyr::n(),
      series_total_time = sum(image_time_ni_s, na.rm = TRUE),  # seconds
      series_start      = min(image_date_time),
      series_end        = max(image_date_time),
      .groups = "drop"
    )

  out
}
