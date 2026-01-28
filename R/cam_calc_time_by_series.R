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
#'
#' **Per-image time allocation**
#' * For each image, `diff_prev_s` is the elapsed time since the previous image in
#'   the same series; `diff_next_s` is the time until the next image in the same
#'   series. Bookends get zeros on the missing side.
#' * Interior image time: `(diff_prev_s + diff_next_s)/2`.
#' * Bookend image time: `((diff_prev_s + diff_next_s)/2) + (tbp/2)`.
#' * Image time is multiplied by `individual_count` (coerced numeric) to obtain
#'   `image_time_ni_s`.
#'
#' **Time-between-photos (tbp)**
#' * Supply `tbi_lookup` with columns `species_common_name`, `tbp` (seconds),
#'   or let the function try to use an internal package object `tbi` (from
#'   `R/sysdata.rda`). If neither is available, a warning is issued and `tbp = 6`
#'   seconds is used as a fallback.
#' * If `tbi_lookup` uses a different tbp column name (e.g., `time_between_photos`,
#'   `tbi`, `tbp_seconds`), it is re-mapped to `tbp`.
#'
#' **Output**
#' * One row per `project × location × species_common_name × series_num`, with:
#'   `n_images`, `series_total_time` (seconds), `series_start`, and `series_end`.
#' * Note: a single-image series receives `tbp/2` (not `tbp`) unless you choose to
#'   post-adjust downstream.
#'
#' @param cons_main_report Data frame (after cam_consolidate_tags()) with at least:
#'   project, location, image_id, image_date_time (POSIXct),
#'   species_common_name, individual_count
#' @param split_gap_secs Gap threshold to start a new series (seconds). Default 120.
#' @param tbi_lookup Optional tibble with per-species time-between-photos `tbp` (seconds).
#'   Columns required: `species_common_name`, `tbp`. If `NULL`, the function will
#'   try to use the internal package object `tbi` (from R/sysdata.rda). If that is
#'   not available, it falls back to tbp = 6 seconds for all species and warns.
#'
#' @return Tibble with one row per series and species:
#'   project, location, species_common_name, series_num, n_images,
#'   series_total_time (seconds), series_start, series_end
#'
#' @seealso [cam_sum_total_time()], [cam_get_op_days()], [cam_summarise_op_by_season()]
#' @author Marcus Becker
#'
#' @export
cam_calc_time_by_series <- function(
    cons_main_report,
    split_gap_secs = 120,
    tbi_lookup = NULL
) {

  # Resolve tbi lookup: prefer user-supplied, else internal `tbi`, else fallback
  if (is.null(tbi_lookup)) {
    tbi_lookup <- if (exists("tbi", inherits = TRUE)) {
      get("tbi", inherits = TRUE)
    } else {
      warning("No `tbi_lookup` provided and internal `tbi` not found; using tbp = 6s for all species.")
      tibble::tibble(species_common_name = unique(cons_main_report$species_common_name), tbp = 6)
    }
  }
  # Keep only needed cols; tolerate alternative column names `time_between_photos` -> `tbp`
  if (!"tbp" %in% names(tbi_lookup)) {
    alt <- intersect(c("time_between_photos", "tbi", "tbp_seconds"), names(tbi_lookup))
    if (length(alt) == 1) tbi_lookup <- dplyr::rename(tbi_lookup, tbp = !!alt)
  }
  tbi_lookup <- tbi_lookup |>
    dplyr::select(species_common_name, tbp) |>
    dplyr::mutate(tbp = as.numeric(tbp))

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

  # Sort & compute gaps within camera and species
  d <- d |>
    dplyr::arrange(project, location, species_common_name, image_date_time, image_id) |>
    dplyr::group_by(project, location, species_common_name) |>
    dplyr::mutate(
      dt_prev    = dplyr::lag(image_date_time),
      gap_prev_s = as.numeric(difftime(image_date_time, dt_prev, units = "secs")),
      new_series = dplyr::if_else(dplyr::row_number() == 1L | gap_prev_s > split_gap_secs, 1L, 0L),
      series_num = cumsum(new_series)
    ) |>
    dplyr::ungroup()

  # Within-series prev/next diffs (seconds); bookends get 0 here
  d <- d |>
    dplyr::group_by(project, location, species_common_name, series_num) |>
    dplyr::mutate(
      prev_ts      = dplyr::lag(image_date_time),
      next_ts      = dplyr::lead(image_date_time),
      diff_prev_s  = dplyr::if_else(dplyr::row_number() == 1L, 0,
                                    as.numeric(difftime(image_date_time, prev_ts, units = "secs"))),
      diff_next_s  = dplyr::if_else(dplyr::row_number() == dplyr::n(), 0,
                                    as.numeric(difftime(next_ts, image_date_time, units = "secs"))),
      is_bookend   = dplyr::row_number() == 1L | dplyr::row_number() == dplyr::n()
    ) |>
    dplyr::ungroup()

  # Attach tbp (seconds) and warn if any species missing in lookup
  d <- d |>
    dplyr::left_join(tbi_lookup, by = "species_common_name") |>
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

  # Image-level time (seconds); bookends add tbp/2
  d <- d |>
    dplyr::mutate(
      image_time_s    = dplyr::if_else(
        is_bookend,
        ((diff_prev_s + diff_next_s) / 2) + (tbp / 2),
        (diff_prev_s + diff_next_s) / 2
      ),
      image_time_ni_s = image_time_s * dplyr::coalesce(individual_count, 1)
    )

  # Series roll-up
  out <- d |>
    dplyr::group_by(project, location, species_common_name, series_num) |>
    dplyr::summarise(
      n_images         = dplyr::n(),
      series_total_time= sum(image_time_ni_s, na.rm = TRUE),  # seconds
      series_start     = min(image_date_time),
      series_end       = max(image_date_time),
      .groups = "drop"
    )

  out
}
