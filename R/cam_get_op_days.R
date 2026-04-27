#' Get a dataframe of operational days for each camera
#'
#' @description
#' Build a per-day calendar for each camera deployment and mark a date as
#' **operational** if there is **any in-range image** that day. In-range is
#' defined by a field-of-view flag: `image_fov != "OOR"` is in-range; `"OOR"`
#' is out-of-range. By default, `NA` in `image_fov` is treated as in-range.
#'
#' @details
#' The function:
#' 1) **Pre-filters** rows where `trigger_col == trigger_exclude_value` (default
#'    `"CodeLoc Not Entered"`). These rows do not contribute to operating days
#'    or calendar span.
#' 2) Parses the image timestamp to `Date`.
#' 3) Flags in-range by `fov_col != oor_flag` (or `NA` treated by `na_fov_means_inrange`).
#' 4) Aggregates to daily `operating = any(in-range)`.
#' 5) Expands to a full daily calendar, filling missing days with `missing_as`.
#' 6) `span = "data"` uses min..max date of filtered images; `span = "operational"`
#'    trims to first..last TRUE `operating`.
#'
#' @param df Image report tibble/data.frame.
#' @param grouping Camera identity columns (only those present are used).
#' @param datetime_col Timestamp column name. Default `"image_date_time"`.
#' @param fov_col Field-of-view flag column. Default `"image_fov"`.
#' @param oor_flag String indicating out-of-range in `fov_col`. Default `"OOR"`.
#' @param na_fov_means_inrange Logical; treat `NA` in `fov_col` as in-range? Default TRUE.
#' @param trigger_col Column that indicates trigger mode. Default `"image_trigger_mode"`.
#' @param trigger_exclude_value Value in `trigger_col` to exclude entirely from
#'   the calendar and ops logic. Default `"CodeLoc Not Entered"`.
#' @param span `"data"` or `"operational"`. Default `"data"`.
#' @param missing_as Fill for days with no images after expansion: one of TRUE, FALSE, or NA.
#'
#' @return Tibble of `grouping`, `date` (Date), and `operating` (logical/NA).
#'
#' @examples
#' \dontrun{
#' # image_reports is a WildTrax image report tibble
#' cal <- cam_get_op_days(
#'   image_reports,
#'   grouping   = c("project_id", "project", "location_id", "location"),
#'   span       = "data",
#'   missing_as = TRUE
#' )
#' }
#'
#' @seealso \code{\link{cam_summarise_op_by_season}}
#' @author Marcus Becker
#' @export
cam_get_op_days <- function(
    df,
    grouping             = c("project","project_id","location","location_id"),
    datetime_col         = "image_date_time",
    fov_col              = "image_fov",
    oor_flag             = "OOR",
    na_fov_means_inrange = TRUE,
    trigger_col          = "image_trigger_mode",
    trigger_exclude_value= "CodeLoc Not Entered",
    span                 = c("data","operational"),
    missing_as           = TRUE
) {

  span <- match.arg(span)

  .missing_fill <- function(x) {
    if (is.logical(x) && length(x) == 1L) return(x)
    if (length(x) == 1L && is.na(x)) return(NA)
    if (is.character(x) && length(x) == 1L) {
      key <- toupper(x)
      if (key %in% c("TRUE","FALSE","NA"))
        return(switch(key, "TRUE"=TRUE, "FALSE"=FALSE, "NA"=NA))
    }
    stop("`missing_as` must be TRUE, FALSE, NA, or \"TRUE\"/\"FALSE\"/\"NA\".")
  }
  fill_val <- .missing_fill(missing_as)

  present_keys <- intersect(grouping, names(df))
  if (length(present_keys) == 0L) {
    stop("None of the requested grouping columns are present. Requested: ",
         paste(grouping, collapse = ", "),
         " | Available: ", paste(names(df), collapse = ", "))
  }

  # Pre-filter by trigger mode
  if (trigger_col %in% names(df)) {
    df <- dplyr::filter(
      df,
      is.na(.data[[trigger_col]]) | .data[[trigger_col]] != trigger_exclude_value
    )
  } else {
    warning("`trigger_col` (", trigger_col, ") not found; no trigger-based filtering applied.",
            call. = FALSE)
  }

  # Parse datetime & in-range flag
  dt_sym  <- rlang::ensym(datetime_col)
  fov_sym <- rlang::ensym(fov_col)

  dt_vec <- df[[rlang::as_string(dt_sym)]]
  if (!inherits(dt_vec, "POSIXt")) {
    dt_vec <- suppressWarnings(lubridate::ymd_hms(as.character(dt_vec)))
  }
  date_vec <- as.Date(dt_vec)

  fov_vec <- df[[rlang::as_string(fov_sym)]]
  inrange <- ifelse(is.na(fov_vec), na_fov_means_inrange, fov_vec != oor_flag)

  df1 <- df
  df1$.date <- date_vec
  df1$.in   <- inrange
  df1 <- dplyr::filter(df1, !is.na(.date))

  if (nrow(df1) == 0L) {
    out <- tibble::as_tibble(df[0, present_keys, drop = FALSE])
    out$date <- as.Date(character())
    out$operating <- logical()
    return(out)
  }

  daily <- df1 |>
    dplyr::group_by(dplyr::across(dplyr::all_of(present_keys)), .date) |>
    dplyr::summarise(operating = any(.in %in% TRUE), .groups = "drop_last")

  expand_and_fill <- function(tbl) {
    tbl |>
      dplyr::group_by(dplyr::across(dplyr::all_of(present_keys))) |>
      tidyr::complete(.date = seq(min(.date), max(.date), by = "1 day")) |>
      dplyr::mutate(operating = dplyr::coalesce(operating, fill_val)) |>
      dplyr::ungroup() |>
      dplyr::rename(date = .date)
  }

  if (span == "data") return(expand_and_fill(daily))

  bounds <- daily |>
    dplyr::filter(operating %in% TRUE) |>
    dplyr::summarise(first_true = min(.date), last_true = max(.date), .groups = "keep")

  if (nrow(bounds) == 0L) {
    out <- tibble::as_tibble(df[0, present_keys, drop = FALSE])
    out$date <- as.Date(character())
    out$operating <- logical()
    return(out)
  }

  daily_inrange <- daily |>
    dplyr::inner_join(bounds, by = present_keys) |>
    dplyr::filter(.date >= first_true, .date <= last_true) |>
    dplyr::select(-first_true, -last_true)

  expand_and_fill(daily_inrange)
}
