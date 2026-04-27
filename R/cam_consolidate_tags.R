#' Consolidate per-image species tags into one row from a WildTrax main report
#'
#' @description
#' For each `(project_id, location, location_id, image_id, species_common_name)`
#' group, sum `individual_count` (numeric rows) and collapse `age_class` /
#' `sex_class` by replicating each tag by that row's count and joining with
#' `", "`. The `image_date_time` is retained and must be identical within each
#' image. Non-species rows (e.g., `"STAFF/SETUP"`, `"NONE"`) are preserved unchanged.
#' Rows whose `species_common_name` is neither in `native_sp` nor in the
#' non-species list are **dropped with a warning** listing the unexpected labels
#' and row counts.
#'
#' @details
#' Species identification uses the **internal** character vector `native_sp`
#' saved in `R/sysdata.rda`.
#'
#' The function also **detects, warns about, and removes** likely duplicate tag
#' entries where all fields are identical **except** `tag_id`,
#' which is a possible double-entry flag.
#' The duplicate check is applied to species rows only, using these fields:
#' `project_id, location, location_id, image_id, image_date_time,
#'  species_common_name, individual_count, age_class, sex_class`.
#' When duplicates are found, the function keeps **one** row per identical set
#' (the one with the **lowest `tag_id`**) and drops the rest.
#'
#' @param report A data.frame/tibble with at least:
#'   `project_id, location, location_id, image_id, image_date_time,
#'    species_common_name, individual_count, age_class, sex_class, tag_id`.
#'    Should be a main report from WildTrax.
#'
#' @return A tibble with one row per image × species:
#'   `project_id, location, location_id, image_id, image_date_time,
#'    species_common_name, age_class, sex_class, individual_count` (character).
#'
#' @examples
#' \dontrun{
#' x <- cam_consolidate_tags(main_reports)
#' # If duplicate tags were removed, you'll see a warning listing image_id(s).
#' }
#'
#' @seealso [cam_calc_time_by_series()] for the next step in the pipeline.
#'
#' @author Marcus Becker
#'
#' @export
cam_consolidate_tags <- function(report) {

  # Ensure internal species vector exists
  if (!exists("native_sp", inherits = TRUE) ||
      !is.character(native_sp) || length(native_sp) == 0L) {
    stop("Internal `native_sp` not found or invalid.",
         call. = FALSE)
  }

  non_species <- c("STAFF/SETUP", "NONE")
  is_species     <- report$species_common_name %in% native_sp
  is_non_species <- report$species_common_name %in% non_species

  # Warn about rows that are neither a known species nor a known non-species
  # label. These are dropped silently otherwise (e.g. domestic animals,
  # uncertain tags, or labels not yet in native_sp).
  is_unknown <- !is_species & !is_non_species
  if (any(is_unknown)) {
    unknown_counts <- sort(table(report$species_common_name[is_unknown]),
                           decreasing = TRUE)
    shown <- head(unknown_counts, 10L)
    label_str <- paste(
      paste0('"', names(shown), '" (n=', shown, ')'),
      collapse = ", "
    )
    extra <- length(unknown_counts) - length(shown)
    warning(
      sum(is_unknown), " row(s) with unrecognised species_common_name dropped: ",
      label_str,
      if (extra > 0L) paste0(" ... +", extra, " more label(s)") else "",
      ". Add to `native_sp` or the non-species list if intentional.",
      call. = FALSE
    )
  }

  to_int_or_na <- function(x) suppressWarnings(as.integer(x))

  # Dynamically keep any of these identity columns if present
  id_candidates <- c("project", "project_id", "location", "location_id")
  id_present    <- intersect(id_candidates, names(report))

  # Aggregation key (do NOT include image_date_time; asserted unique later)
  key_cols <- c(id_present, "image_id", "species_common_name")

  # Columns used to detect "identical except tag_id"
  dup_check_cols <- c(
    id_present, "image_id", "image_date_time",
    "species_common_name","individual_count","age_class","sex_class"
  )

  # Species subset
  sp_raw <- report[is_species, , drop = FALSE]

  # Detect & remove duplicate entries (identical except tag_id)
  if (nrow(sp_raw) > 0 && all(dup_check_cols %in% names(sp_raw))) {
    dup_ids <- sp_raw |>
      dplyr::group_by(dplyr::across(dplyr::all_of(dup_check_cols))) |>
      dplyr::filter(dplyr::n() > 1L, dplyr::n_distinct(tag_id, na.rm = TRUE) > 1L) |>
      dplyr::ungroup() |>
      dplyr::distinct(image_id) |>
      dplyr::pull(image_id)

    if (length(dup_ids) > 0) {
      shown <- head(unique(dup_ids), 20)
      extra <- length(unique(dup_ids)) - length(shown)
      warning(
        paste0(
          "Removed duplicate tag entries (identical rows except tag_id). image_id(s): ",
          paste(shown, collapse = ", "),
          if (extra > 0) paste0(" ... +", extra, " more") else ""
        ),
        call. = FALSE
      )

      sp_raw <- sp_raw |>
        dplyr::arrange(.data$tag_id) |>
        dplyr::distinct(dplyr::across(dplyr::all_of(dup_check_cols)), .keep_all = TRUE)
    }
  }

  # Species rows: one row per image × species
  sp <- sp_raw
  if (nrow(sp) > 0) {
    sp <- sp |>
      dplyr::group_by(dplyr::across(dplyr::all_of(key_cols))) |>
      dplyr::summarise(
        # Assert single timestamp per image_id × species
        image_date_time = {
          u <- unique(image_date_time)
          if (length(u) != 1L) {
            stop(sprintf(
              "Multiple image_date_time values found for image_id=%s, species=%s",
              as.character(dplyr::first(image_id)),
              as.character(dplyr::first(species_common_name))
            ))
          }
          u[1]
        },
        .sum_count = {
          cnt <- to_int_or_na(individual_count)
          sum(cnt, na.rm = TRUE)
        },
        .has_numeric = {
          cnt <- to_int_or_na(individual_count)
          any(!is.na(cnt))
        },
        age_class = {
          cnt <- to_int_or_na(individual_count)
          per_row <- purrr::map2_chr(age_class, cnt, ~{
            if (is.na(.y) || is.na(.x) || .x %in% c("", "VNA") || .y <= 0) "" else paste(rep(.x, .y), collapse = ", ")
          })
          out <- paste(per_row[nzchar(per_row)], collapse = ", ")
          if (out == "") "VNA" else out
        },
        sex_class = {
          cnt <- to_int_or_na(individual_count)
          per_row <- purrr::map2_chr(sex_class, cnt, ~{
            if (is.na(.y) || is.na(.x) || .x %in% c("", "VNA") || .y <= 0) "" else paste(rep(.x, .y), collapse = ", ")
          })
          out <- paste(per_row[nzchar(per_row)], collapse = ", ")
          if (out == "") "VNA" else out
        },
        .groups = "drop"
      ) |>
      dplyr::mutate(
        individual_count = dplyr::if_else(.has_numeric, as.character(.sum_count), "VNA")
      ) |>
      # Keep all identity columns that were present so none become NA
      dplyr::select(dplyr::all_of(key_cols), image_date_time, age_class, sex_class, individual_count)
  }

  # Non-species rows: keep unchanged
  nonspecies <- report[is_non_species, , drop = FALSE]

  dplyr::bind_rows(nonspecies, sp) |>
    dplyr::arrange(dplyr::across(dplyr::all_of(id_present)),
                   .data$image_id, .data$species_common_name)

  }
