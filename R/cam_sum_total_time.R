#' Summarise total time by project, location, species, and season (with op-days)
#'
#' @description
#' Rolls up image-series time (seconds) to seasonal totals per deployment × species
#' and attaches the number of operating days per season. Seasons are assigned by
#' Julian cutoffs you provide (e.g., spring = 99, summer = 143, winter = 288).
#' Output is ready to feed into density calculations that require both
#' `total_duration` and `total_season_days`.
#'
#' @details
#' **Season assignment**
#' * Each series row is assigned to a season using the Julian day of `series_start`
#'   in the chosen `tz`. Cutoffs must be strictly increasing; season labels come
#'   from the names of `season_cutoffs` and are used downstream (keep them lower-case
#'   for consistency with EDD lookups).
#'
#' **Aggregation**
#' * Within each `project` × `location` × `species_common_name` × `season`,
#'   the function sums `series_total_time` to produce `total_duration` in seconds.
#'
#' **Operating days**
#' * `op_days_df` can be supplied either in long form (has a `season` column and a
#'   day-count column named `total_season_days` or `operating_days`) or wide form
#'   (one column per season label). The function normalizes this to a long table and
#'   merges to add `total_season_days`.
#'
#' **Zero-filling**
#' * To ensure locations with no detected series still appear (with 0 duration),
#'   the function constructs the full grid of cameras (from `op_days_df`) × seasons,
#'   crossed with a species universe. If `species_universe` is not supplied, it uses
#'   the species present in `series_df`. This guarantees downstream density steps
#'   see explicit zeros rather than missing rows.
#'
#' **Input requirements**
#' * `series_df` must include: `project`, `location`, `species_common_name`,
#'   `series_start` (POSIXct or parseable), and `series_total_time` (seconds).
#' * `op_days_df` must provide operating-day counts per camera × season (long or wide).
#'
#' **Output**
#' * A tibble with columns:
#'   `project`, `location`, `species_common_name`, `season`,
#'   `total_duration` (seconds), and `total_season_days` (days).
#'
#' @param series_df Output of cam_calc_time_by_series(); needs
#'   project, location, species_common_name, series_start, series_total_time
#' @param season_cutoffs Named integer vector of Julian cutoffs, e.g.
#'   c(spring=99L, summer=143L, winter=288L). Labels come from names (lower-case
#'   recommended for consistency with EDD lookups). Cutoffs are auto-sorted, so
#'   order does not matter.
#' @param tz Time zone used to extract the Julian day from \code{series_start}.
#'   Defaults to \code{Sys.timezone()} (the local system timezone). WildTrax
#'   timestamps are typically stored in local time, so this default is usually
#'   correct. Override explicitly (e.g. \code{"America/Edmonton"}) when running
#'   on a machine whose timezone does not match the study area.
#' @param op_days_df Operating-days table (required) for zero-fill + days per
#'   season. Accepts EITHER:
#'   - long: project, location, season, total_season_days (or operating_days), or
#'   - wide: project, location, one column per season label (values are day counts).
#'   Typically the output of \code{cam_summarise_op_by_season(wide = TRUE)}.
#' @param species_universe Optional vector used for zero-fill across species
#'
#' @return Tibble with: project, location, species_common_name, season,
#'   total_duration, total_season_days
#'
#' @examples
#' \dontrun{
#' # series is the output of cam_calc_time_by_series()
#' # op_days is the output of cam_summarise_op_by_season(wide = TRUE)
#' dur <- cam_sum_total_time(
#'   series_df        = series,
#'   season_cutoffs   = c(spring = 99L, summer = 143L, winter = 288L),
#'   op_days_df       = op_days,
#'   species_universe = c("White-tailed Deer", "Moose", "Black Bear")
#' )
#' }
#'
#' @seealso [cam_calc_time_by_series()], [cam_get_op_days()], [cam_summarise_op_by_season()]
#'
#' @author Marcus Becker
#'
#' @export
cam_sum_total_time <- function(
    series_df,
    season_cutoffs   = c(spring=99L, summer=143L, winter=288L),
    tz               = Sys.timezone(),
    op_days_df,
    species_universe = NULL
) {

  need <- c("project","location","species_common_name","series_start","series_total_time")
  miss <- setdiff(need, names(series_df))
  if (length(miss)) stop("`series_df` missing: ", paste(miss, collapse=", "), call. = FALSE)
  if (is.null(names(season_cutoffs)) || any(names(season_cutoffs) == "")) {
    stop("`season_cutoffs` must be a named integer vector; names = season labels.", call. = FALSE)
  }
  cuts <- as.integer(season_cutoffs); names(cuts) <- names(season_cutoffs)
  cuts <- cuts[order(cuts)]
  labs <- names(cuts)

  s <- series_df
  if (!inherits(s$series_start, "POSIXt")) {
    s$series_start <- suppressWarnings(lubridate::ymd_hms(as.character(s$series_start), tz = tz))
  } else {
    s$series_start <- lubridate::force_tz(s$series_start, tzone = tz)
  }

  make_season <- function(x, cuts_int, labs, tz_local) {
    j <- as.integer(strftime(x, "%j", tz = tz_local))
    .assign_season(j, cuts_int, labs)
  }

  # Assign seasons & sum time
  s <- dplyr::mutate(s, season = make_season(series_start, cuts, labs, tz))
  tt <- s |>
    dplyr::group_by(project, location, species_common_name, season) |>
    dplyr::summarise(total_duration = sum(series_total_time, na.rm = TRUE), .groups = "drop")

  # normalise op_days_df to long: project, location, season, total_season_days
  if (!all(c("project","location") %in% names(op_days_df))) {
    stop("`op_days_df` must contain `project` and `location`.", call. = FALSE)
  }

  # Case 1: already long (has a season column)
  if ("season" %in% names(op_days_df)) {
    days_long <- op_days_df
    # rename count col if needed
    if (!"total_season_days" %in% names(days_long)) {
      if ("operating_days" %in% names(days_long)) {
        days_long <- dplyr::rename(days_long, total_season_days = operating_days)
      } else {
        stop("`op_days_df` (long) must have `total_season_days` or `operating_days`.", call. = FALSE)
      }
    }
    # Season label normalisation to match our labels
    days_long <- days_long |>
      dplyr::mutate(season = factor(as.character(season), levels = labs, ordered = TRUE))
  } else {
    # Case 2: wide -> pivot longer
    wide_season_cols <- intersect(names(op_days_df), labs)
    if (length(wide_season_cols) == 0L) {
      stop("`op_days_df` wide form must have columns named exactly: ", paste(labs, collapse = ", "), call. = FALSE)
    }
    days_long <- op_days_df |>
      tidyr::pivot_longer(
        cols = dplyr::all_of(wide_season_cols),
        names_to = "season",
        values_to = "total_season_days"
      ) |>
      dplyr::mutate(season = factor(season, levels = labs, ordered = TRUE))
  }

  # Cameras universe from op_days_df (ensures zero-fill includes sites with zero series)
  cameras <- days_long |>
    dplyr::distinct(project, location)

  # Species universe for zero-fill
  if (is.null(species_universe)) {
    species_universe <- sort(unique(tt$species_common_name))
  }

  # Full grid: cameras × species × seasons
  grid <- tidyr::crossing(
    cameras,
    species_common_name = species_universe,
    season = factor(labs, levels = labs, ordered = TRUE)
  )

  # Zero-fill total_duration, then join total_season_days
  out <- grid |>
    dplyr::left_join(tt, by = c("project","location","species_common_name","season")) |>
    dplyr::mutate(total_duration = dplyr::coalesce(total_duration, 0)) |>
    dplyr::left_join(days_long, by = c("project","location","season")) |>
    dplyr::arrange(project, location, species_common_name, season)

  out
}
