#' Identify "N" gap boundaries where a NONE is found between animal images
#'
#' @description
#' Flags boundaries where an animal image is followed (after one or more rows of
#' `NONE`) by another animal image within a short time window. These should be
#' split into separate series because the intervening `NONE` indicates the animal
#' left the FOV, even if the total animal-to-animal image gap is small.
#'
#' @param cons_main_report Main report with consolidated tags (e.g., from
#'   `cam_consolidate_tags()`), requiring: `image_date_time`, `image_id`,
#'   `species_common_name`, and camera identity columns.
#' @param grouping Character vector of camera identity columns. Only those
#'   present are used. Default: c("project","project_id","location","location_id").
#' @param datetime_col Name of the timestamp column. Default "image_date_time".
#' @param species_col  Name of the species column.   Default "species_common_name".
#' @param none_label   Label denoting a NONE image. Default "NONE".
#' @param max_bridge_secs Numeric, maximum animal-to-animal elapsed seconds to still
#'   consider a bridged series. Default 120.
#' @param require_same_species Logical, require same species before/after the
#'   NONE block? Default TRUE.
#'
#' @return A tibble with one row per detected boundary:
#'   grouping columns, `image_id`, `image_date_time`, `species_common_name`,
#'   `gap_class = "N"`. If none are found, returns an empty tibble and warns.
#'
#' @seealso [cam_calc_time_by_series()] which accepts the output of this function
#'   via its `n_gap_df` parameter to force series splits at NONE-bridged boundaries.
#'
#' @author Marcus Becker
#'
#' @export
cam_obtain_n_gap_class <- function(
    cons_main_report,
    grouping             = c("project","project_id","location","location_id"),
    datetime_col         = "image_date_time",
    species_col          = "species_common_name",
    none_label           = "NONE",
    max_bridge_secs      = 120,
    require_same_species = TRUE
) {

  present_keys <- intersect(grouping, names(cons_main_report))
  dt_sym <- rlang::ensym(datetime_col)
  sp_sym <- rlang::ensym(species_col)

  # Coerce datetime if needed
  dt_vec <- cons_main_report[[rlang::as_string(dt_sym)]]
  if (!inherits(dt_vec, "POSIXt")) {
    dt_vec <- suppressWarnings(lubridate::ymd_hms(as.character(dt_vec)))
  }

  # Base frame with flags
  df <- cons_main_report |>
    dplyr::mutate(
      .dt      = dt_vec,
      .sp      = !!sp_sym,
      .is_none = (.sp == none_label)
    ) |>
    dplyr::filter(!is.na(.dt))

  # Order: keys -> time -> image_id (if available)
  if (length(present_keys) > 0) {
    if ("image_id" %in% names(df)) {
      df <- dplyr::arrange(df, dplyr::across(dplyr::all_of(present_keys)), .dt, image_id)
    } else {
      df <- dplyr::arrange(df, dplyr::across(dplyr::all_of(present_keys)), .dt)
    }
  } else {
    if ("image_id" %in% names(df)) {
      df <- dplyr::arrange(df, .dt, image_id)
    } else {
      df <- dplyr::arrange(df, .dt)
    }
  }

  if (nrow(df) == 0L) {
    out <- tibble::as_tibble(df[0, present_keys, drop = FALSE])
    out$image_id <- integer()
    out[[rlang::as_string(dt_sym)]] <- as.POSIXct(character())
    out[[rlang::as_string(sp_sym)]]  <- character()
    out$gap_class <- character()
    warning("No rows in input after filtering valid timestamps; no N gap classes identified.", call. = FALSE)
    return(out)
  }

  # Index rows and compute cumulative NONE per group, plus lagged version
  if (length(present_keys) > 0) {
    df <- df |>
      dplyr::group_by(dplyr::across(dplyr::all_of(present_keys))) |>
      dplyr::mutate(
        .row_full        = dplyr::row_number(),
        .none_cumul      = cumsum(.is_none),
        .none_cumul_prev = dplyr::lag(.none_cumul, default = 0L)
      ) |>
      dplyr::ungroup()
  } else {
    df <- df |>
      dplyr::mutate(
        .row_full        = dplyr::row_number(),
        .none_cumul      = cumsum(.is_none),
        .none_cumul_prev = dplyr::lag(.none_cumul, default = 0L)
      )
  }

  # Animal-only table with NEXT animal's row/time/species
  animals <- df |>
    dplyr::filter(!.is_none)

  if (length(present_keys) > 0) {
    animals <- animals |>
      dplyr::group_by(dplyr::across(dplyr::all_of(present_keys))) |>
      dplyr::arrange(.row_full, .by_group = TRUE) |>
      dplyr::mutate(
        .next_row_full = dplyr::lead(.row_full),
        .next_time     = dplyr::lead(.dt),
        .next_sp       = dplyr::lead(.sp)
      ) |>
      dplyr::ungroup()
  } else {
    animals <- animals |>
      dplyr::arrange(.row_full) |>
      dplyr::mutate(
        .next_row_full = dplyr::lead(.row_full),
        .next_time     = dplyr::lead(.dt),
        .next_sp       = dplyr::lead(.sp)
      )
  }

  # Lookup for cumulative NONE counts at (current row) and (next row - 1)
  lookup <- df |>
    dplyr::select(dplyr::all_of(c(present_keys, ".row_full", ".none_cumul", ".none_cumul_prev")))

  animals <- animals |>
    # Cumulative NONE at the current animal row
    dplyr::left_join(
      lookup |>
        dplyr::rename(.none_cumul_start = .none_cumul),
      by = c(present_keys, ".row_full")
    ) |>
    # Cumulative NONE just BEFORE the next animal row (at next_row_full - 1)
    dplyr::left_join(
      lookup |>
        dplyr::select(dplyr::all_of(c(present_keys, ".row_full", ".none_cumul_prev"))) |>
        dplyr::rename(.none_cumul_end = .none_cumul_prev),
      by = c(present_keys, ".next_row_full" = ".row_full")
    ) |>
    dplyr::mutate(
      .elapsed      = as.numeric(.next_time - .dt, units = "secs"),
      .same_species = (.next_sp == .sp),
      .none_between = (.none_cumul_end - .none_cumul_start) > 0
    )

  # Apply rules and emit the boundary (current animal row)
  res <- animals |>
    dplyr::filter(
      !is.na(.next_row_full),
      .none_between,
      !is.na(.elapsed) & .elapsed <= max_bridge_secs,
      if (require_same_species) .same_species else TRUE
    ) |>
    dplyr::transmute(
      dplyr::across(dplyr::all_of(present_keys)),
      image_id,
      !!rlang::as_string(dt_sym) := .dt,
      !!rlang::as_string(sp_sym) := .sp,
      gap_class = "N"
    )

  if (nrow(res) == 0L) {
    warning("No N gap classes identified.", call. = FALSE)
  }

  res
}
