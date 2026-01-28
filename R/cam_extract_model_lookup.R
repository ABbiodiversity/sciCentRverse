#' Extract per-camera model ("hf2" / "pc900") from an image report
#'
#' @description
#' Minimal helper to derive a per-camera `model` from a model column
#' (defaults to `equipment_model`). Returns one row per camera key with
#' `model` in lower case.
#'
#' @param image_report Data frame with at least `keys` and the model column.
#'   Typically a WildTrax image report.
#' @param keys Character vector of columns that identify a camera. Default:
#'   c("project","location"). If you prefer per-`location_id`, include it
#'   (e.g., c("project","location","location_id")).
#' @param model_col Column name (string or bare) containing the raw model text.
#'   Default "equipment_model".
#' @param hf2_pattern Regex used to detect HF2 models (case-insensitive).
#'   Default "HF2".
#' @param pc900_pattern Regex used to detect PC900 models (case-insensitive).
#'   Default "PC900|PC 900|PC-900".
#'
#' @author Marcus Becker
#'
#' @return Tibble with `keys` + `model` (values: "hf2" or "pc900").
#' @export
cam_extract_model_lookup <- function(
    image_report,
    keys = c("project","location"),
    model_col = "equipment_model",
    hf2_pattern = "HF2",
    pc900_pattern = "PC900|PC 900|PC-900"
) {
  # Resolve column symbol (supports string or bare name)
  model_sym <- rlang::ensym(model_col)
  model_name <- rlang::as_string(model_sym)

  # Checks
  need <- c(keys, model_name)
  miss <- setdiff(need, names(image_report))
  if (length(miss)) {
    stop("`image_report` missing: ", paste(miss, collapse = ", "), call. = FALSE)
  }

  out <- image_report |>
    dplyr::select(dplyr::all_of(keys), !!model_sym) |>
    dplyr::filter(!is.na(!!model_sym)) |>
    dplyr::mutate(
      .model_raw = as.character(!!model_sym),
      .model_raw = trimws(.model_raw),
      model = dplyr::case_when(
        stringr::str_detect(.model_raw, stringr::regex(hf2_pattern,   ignore_case = TRUE)) ~ "hf2",
        stringr::str_detect(.model_raw, stringr::regex(pc900_pattern, ignore_case = TRUE)) ~ "pc900",
        TRUE ~ NA_character_
      )
    ) |>
    dplyr::filter(!is.na(model)) |>
    dplyr::distinct(dplyr::across(dplyr::all_of(keys)), model)

  # Warn if a camera appears with multiple models (rare; indicates upstream inconsistency)
  dup_warn <- out |>
    dplyr::count(dplyr::across(dplyr::all_of(keys)), name = "n_models") |>
    dplyr::filter(n_models > 1)
  if (nrow(dup_warn)) {
    warning(
      "Some cameras have multiple models in the report; keeping multiple rows in the lookup.",
      call. = FALSE
    )
  }

  out
}
