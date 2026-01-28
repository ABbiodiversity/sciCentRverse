#' Summarise operational days by user-defined seasons
#'
#' @description
#' Takes the output from `cam_get_op_days()` and sums the number of
#' **operational days** per season. Seasons are defined
#' by Julian day **start** cutoffs and can be 1..n segments that wrap the year.
#'
#' @details
#' **Season definitions** (`seasons`) can be supplied in any of these forms:
#' - **Named numeric vector** (recommended): e.g.,
#'   `c(spring = 99, summer = 143, winter = 288)`.
#' - **Unnamed numeric + `labels=`**: e.g., `seasons = c(99, 143, 288), labels = c("spring","summer","winter")`.
#' - **Data frame** with columns `season` (labels) and `start` (Julian day).
#'
#' Rules:
#' - Starts must be integers in `1..366`, unique, and will be sorted.
#' - Classification is circular: the last season runs to day 366, then wraps to the first start.
#'
#' **Grouping**: By default the function looks for `c("project","project_id","location", "location_id)`
#' but only use the ones actually present in `calendar_df`. If none are present,
#' the result is aggregated across all records.
#'
#' **Operating NA handling**: By default `operating = NA` is counted as `FALSE`
#' (`na_as = FALSE`). Set `na_as = TRUE` to count unknown days as operational.
#'
#' @param calendar_df A tibble/data.frame with at least `date` (Date) and
#'   `operating` (logical/NA), typically the output of `cam_get_op_days()`.
#' @param grouping Character vector of grouping columns to keep in the summary.
#'   Defaults to `c("project","project_id","location","location_id")`; only columns present
#'   are used. If none are present, aggregation is global.
#' @param seasons Season starts. Named numeric, unnamed numeric + `labels`, or a
#'   data frame with `season` and `start` columns. Defaults to
#'   `c(spring = 99, summer = 143, winter = 288)`.
#' @param labels Optional labels if `seasons` is an unnamed numeric vector.
#' @param date_col Name of the date column in `calendar_df`. Default `"date"`.
#' @param operating_col Name of the logical operating column. Default `"operating"`.
#' @param na_as Logical: treat `NA` in `operating` as TRUE when counting?
#'   Default `FALSE`.
#' @param by_year Logical: also summarise by calendar year? Default `FALSE`.
#' @param wide Logical: return one column per season (`TRUE`) or a long table with
#'   `season` and `operating_days` (`FALSE`). Default `TRUE`.
#'
#' @return A tibble. In **wide** mode: grouping cols (+ `year` if `by_year`),
#'   one column per season (counts), and `total_days` (row sum). In **long** mode:
#'   grouping cols (+ `year`), `season`, `operating_days`, and `total_days`.
#'
#' @examples
#' \dontrun{
#' cal <- cam_get_op_days(image_reports,
#'                        grouping = c("project_id","location","location_id"),
#'                        span = "operational", missing_as = FALSE)
#'
#' # Default seasons, by year, wide format
#' sum1 <- cam_summarise_op_by_season(cal, by_year = TRUE, wide = TRUE)
#'
#' # Two-season example, long format
#' sum2 <- cam_summarise_op_by_season(
#'   calendar_df = cal,
#'   seasons     = c(IceFree = 120, FreezeUp = 305),
#'   by_year     = FALSE,
#'   wide        = FALSE
#' )
#' }
#'
#' @seealso \code{\link{cam_get_op_days}}
#'
#' @author Marcus Becker
#'
#' @export
cam_summarise_op_by_season <- function(
    calendar_df,
    grouping      = c("project","project_id","location","location_id"),
    seasons       = c(spring = 99, summer = 143, winter = 288),
    labels        = NULL,
    date_col      = "date",
    operating_col = "operating",
    na_as         = FALSE,
    by_year       = FALSE,
    wide          = TRUE
) {

  # Helper functions
  .parse_seasons <- function(seasons, labels = NULL) {
    if (is.numeric(seasons) && !is.null(names(seasons))) {
      starts <- as.integer(seasons); labs <- as.character(names(seasons))
    } else if (is.numeric(seasons) && is.null(names(seasons))) {
      if (is.null(labels) || length(labels) != length(seasons))
        stop("If `seasons` is unnamed numeric, provide matching `labels`.")
      starts <- as.integer(seasons); labs <- as.character(labels)
    } else if (is.data.frame(seasons)) {
      if (!all(c("season","start") %in% names(seasons)))
        stop("Data-frame `seasons` must have columns `season` and `start`.")
      starts <- as.integer(seasons$start); labs <- as.character(seasons$season)
    } else {
      stop("Unsupported `seasons` input. See help for accepted forms.")
    }
    if (length(starts) < 1L) stop("Provide at least one season start.")
    if (any(is.na(starts))) stop("Season starts contain NA.")
    if (any(starts < 1L | starts > 366L)) stop("Season starts must be in 1..366.")
    if (any(duplicated(starts))) stop("Season starts must be unique.")
    o <- order(starts)
    list(starts = starts[o], labels = labs[o])
  }

  .classify_season <- function(yday_vec, starts, labels) {
    widths <- c(diff(starts), 366L - (starts[length(starts)] - starts[1L]))
    breaks <- c(0L, cumsum(widths))
    yrot <- ((yday_vec - starts[1L]) %% 366L) + 1L
    idx  <- findInterval(yrot, breaks, rightmost.closed = TRUE)
    stats::setNames(factor(labels[idx], levels = labels), NULL)
  }

  # Resolve grouping cols present
  present_keys <- intersect(grouping, names(calendar_df))

  # Symbols
  date_sym      <- rlang::ensym(date_col)
  operating_sym <- rlang::ensym(operating_col)

  # Seasons
  S        <- .parse_seasons(seasons, labels)
  s_starts <- S$starts
  s_labels <- S$labels

  # Prepare base
  df <- calendar_df |>
    dplyr::mutate(
      .date   = as.Date(!!date_sym),
      .op     = dplyr::coalesce(as.logical(!!operating_sym), if (na_as) TRUE else FALSE),
      .yday   = lubridate::yday(.date),
      .season = .classify_season(.yday, s_starts, s_labels),
      .year   = lubridate::year(.date)
    )

  # Build grouping vector
  group_keys <- present_keys
  if (by_year) group_keys <- c(group_keys, ".year")

  # Summaries
  sums <- df |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_keys)), .season) |>
    dplyr::summarise(operating_days = sum(.op %in% TRUE, na.rm = TRUE), .groups = "drop_last") |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_keys))) |>
    tidyr::complete(.season = factor(s_labels, levels = s_labels),
                    fill = list(operating_days = 0L)) |>
    dplyr::ungroup()

  totals <- sums |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_keys))) |>
    dplyr::summarise(total_days = sum(operating_days), .groups = "drop")

  if (wide) {
    out <- sums |>
      tidyr::pivot_wider(
        id_cols     = dplyr::all_of(group_keys),
        names_from  = .season,
        values_from = operating_days
      ) |>
      dplyr::left_join(totals, by = group_keys)
    if (by_year) {
      out <- dplyr::rename(out, year = .year)
    }
  } else {
    out <- sums |>
      dplyr::left_join(totals, by = group_keys)
    if (by_year) {
      out <- dplyr::rename(out, year = .year, season = .season)
    } else {
      out <- dplyr::rename(out, season = .season)
    }
  }

  out
}



