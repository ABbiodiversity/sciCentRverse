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
#' 1) Parses the image timestamp (`image_date_time` by default) to a `Date`.
#' 2) Flags each image as in-range if `image_fov != oor_flag` (or `NA` and
#'    `na_fov_means_inrange = TRUE`).
#' 3) Aggregates to one row per (group, date) with `operating = any(in-range)`.
#' 4) Expands to a contiguous daily calendar and fills days with **no images**
#'    using `missing_as`:
#'    - `FALSE`: treat as non-operational,
#'    - `TRUE`: treat as operational (assume continuous operation),
#'    - `NA`: unknown.
#' 5) The `span` argument controls the calendar width:
#'    - `span = "data"` builds from the earliest to the latest date seen for the group.
#'    - `span = "operational"` truncates to the window from the first operational day
#'    to the last operational day (drop quiet tails).
#'
#' @param df A data.frame/tibble of an image report (or multiple) from WildTrax.
#' @param grouping Character vector of columns that identify a camera (e.g.,
#'   `c("project_id","location","location_id")`). Only columns present in `image_report`
#'   are used (error if none are present).
#' @param datetime_col Name of the timestamp column (POSIXct or parsable string).
#'   Default `"image_date_time"`.
#' @param fov_col Name of the field-of-view flag column. Default `"image_fov"`, per WildTrax.
#' @param oor_flag String that indicates out-of-range in `fov_col`. Default `"OOR"`, per WildTrax.
#' @param na_fov_means_inrange Logical; treat `NA` in `fov_col` as in-range?
#'   Default `TRUE`.
#' @param span Either `"data"` (full min..max per group) or `"operational"`
#'   (truncate to first..last operational day). Default `"data"`.
#' @param missing_as Fill value for `operating` for days with **no images** after expansion:
#'   one of `FALSE` (default), `TRUE`, or `NA`.
#'
#' @return A tibble with grouping columns, `date` (`Date`), and `operating`
#'   (`logical`/`NA`) per day.
#'
#' @examples
#' \dontrun{
#' # Basic usage with a WildTrax image report
#' cal <- cam_get_op_days(
#'   df           = image_report,
#'   grouping     = c("project_id","location","location_id"),
#'   datetime_col = "image_date_time",
#'   fov_col      = "image_fov",
#'   oor_flag     = "OOR",
#'   span         = "operational",
#'   missing_as   = FALSE
#' )
#'
#' # Assume continuous operation between observed days:
#' cal_true <- cam_get_op_days(
#'   image_report,
#'   grouping   = c("project_id","location"),
#'   span       = "data",
#'   missing_as = TRUE
#' )
#' }
#'
#' @seealso \code{\link{cam_summarise_op_by_season}}
#'
#' @author Marcus Becker
#'
#' @export
cam_get_op_days <- function(
    df,
    grouping             = c("project","project_id","location","location_id"),
    datetime_col         = "image_date_time",
    fov_col              = "image_fov",
    oor_flag             = "OOR",
    na_fov_means_inrange = TRUE,
    span                 = c("data","operational"),
    missing_as           = TRUE
) {

  span <- match.arg(span)

  # Fill missing helper function
  .missing_fill <- function(x) {
    if (is.logical(x) && length(x) == 1L) return(x)
    if (length(x) == 1L && is.na(x)) return(NA)
    if (is.character(x) && length(x) == 1L) {
      key <- toupper(x)
      if (key %in% c("TRUE","FALSE","NA"))
        return(switch(key, "TRUE"=TRUE, "FALSE"=FALSE, "NA"=NA))
    }
    stop("`missing_as` must be TRUE, FALSE, NA, or the strings \"TRUE\"/\"FALSE\"/\"NA\".")
  }

  fill_val <- .missing_fill(missing_as)

  # Resolve grouping keys that actually exist in df
  present_keys <- intersect(grouping, names(df))
  if (length(present_keys) == 0L) {
    stop(
      "None of the requested grouping columns are present. Requested: ",
      paste(grouping, collapse = ", "),
      " | Available: ",
      paste(names(df), collapse = ", ")
    )
  }

  # Symbols
  dt_sym  <- rlang::ensym(datetime_col)
  fov_sym <- rlang::ensym(fov_col)

  # Parse datetime once; derive date and in-range flag
  dt_vec <- df[[rlang::as_string(dt_sym)]]
  if (!inherits(dt_vec, "POSIXt")) {
    dt_vec <- suppressWarnings(lubridate::ymd_hms(as.character(dt_vec)))
  }
  date_vec <- as.Date(dt_vec)

  fov_vec  <- df[[rlang::as_string(fov_sym)]]
  inrange  <- ifelse(is.na(fov_vec), na_fov_means_inrange, fov_vec != oor_flag)

  # Working dataframe
  df1 <- df
  df1$.date <- date_vec
  df1$.in   <- inrange
  df1 <- dplyr::filter(df1, !is.na(.date))

  if (nrow(df1) == 0L) {
    out <- tibble::as_tibble(df[0, present_keys, drop = FALSE])
    out$date <- as.Date(character()); out$operating <- logical()
    return(out)
  }

  # Per-day, per-group operating flag: any in-range image that day
  daily <- df1 |>
    dplyr::group_by(dplyr::across(dplyr::all_of(present_keys)), .date) |>
    dplyr::summarise(operating = any(.in %in% TRUE), .groups = "drop_last")

  # Expand helper
  expand_and_fill <- function(tbl) {
    tbl |>
      dplyr::group_by(dplyr::across(dplyr::all_of(present_keys))) |>
      tidyr::complete(.date = seq(min(.date), max(.date), by = "1 day")) |>
      dplyr::mutate(operating = dplyr::coalesce(operating, fill_val)) |>
      dplyr::ungroup() |>
      dplyr::rename(date = .date)
  }

  if (span == "data") {
    return(expand_and_fill(daily))
  }

  # span == "operational": crop to first..last TRUE per group
  bounds <- daily |>
    dplyr::filter(operating %in% TRUE) |>
    dplyr::summarise(first_true = min(.date), last_true = max(.date), .groups = "keep")

  if (nrow(bounds) == 0L) {
    out <- tibble::as_tibble(df[0, present_keys, drop = FALSE])
    out$date <- as.Date(character()); out$operating <- logical()
    return(out)
  }

  daily_inrange <- daily |>
    dplyr::inner_join(bounds, by = present_keys) |>
    dplyr::filter(.date >= first_true, .date <= last_true) |>
    dplyr::select(-first_true, -last_true)

  expand_and_fill(daily_inrange)

}

