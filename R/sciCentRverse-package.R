#' sciCentRverse: Personal R Utility Functions
#'
#' An internal R package for prototyping, testing, and
#' refining reusable functions for data processing,
#' visualization, species distribution modelling, and
#' general analyses across Science Centre projects.
#' Includes functions for spatial data handling, raster
#' extraction, time estimation, file loading, and data
#' formatting.
#'
#' @section Key Functions:
#' - `add_alberta_flag()`: Flag points inside Alberta using `sf` and `rnaturalearth`.
#' - `extract_by_year()`: Extract data grouped by year.
#' - `read_tifs_to_list()`, `read_tifs_to_multiband()`: Read rasters.
#' - `estimate_processing_time()`: Estimate runtime.
#' - `load_most_recent_data()`, `load_rdata_files()`: File loading helpers.
#' - `sample_blocks()`: Sampling helpers for spatial workflows.
#' - `set_terra_options()`: Configure `terra`.
#' - `snake_case()`: String case utilities.
#' - `style_active_file()`: Format active file with `styler`.
#' - `summarize_column_classes()`: Inspect data frame column classes.
#'
#' @aliases sciCentRverse sciCentRverse-package
#' @keywords internal
"_PACKAGE"
