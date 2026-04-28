# Package index

## Camera Trap Functions

A pipeline for estimating wildlife density from camera trap data using
the time-in-front-of-camera (TIFC) method.

- [`cam_get_op_days()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_get_op_days.md)
  : Get a dataframe of operational days for each camera
- [`cam_summarise_op_by_season()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_summarise_op_by_season.md)
  : Summarise operational days by user-defined seasons
- [`cam_consolidate_tags()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_consolidate_tags.md)
  : Consolidate per-image species tags into one row from a WildTrax main
  report
- [`cam_obtain_n_gap_class()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_obtain_n_gap_class.md)
  : Identify "N" gap boundaries where a NONE is found between animal
  images
- [`cam_calc_time_by_series()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_calc_time_by_series.md)
  : Calculate time-in-front-of-camera by series (in seconds)
- [`cam_sum_total_time()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_sum_total_time.md)
  : Summarise total time by project, location, species, and season (with
  op-days)
- [`cam_extract_model_lookup()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_extract_model_lookup.md)
  : Extract per-camera model ("hf2" / "pc900") from an image report
- [`cam_calc_density_by_loc()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_calc_density_by_loc.md)
  : Calculate density at each location from seasonal time and EDD (with
  optional pooled fallback)

## Spatial & Mapping Utilities

Functions for spatial data processing and map styling.

- [`theme_science()`](https://ABbiodiversity.github.io/sciCentRverse/reference/theme_science.md)
  : Minimal Theme for Scientific Plots
- [`theme_science_map()`](https://ABbiodiversity.github.io/sciCentRverse/reference/theme_science_map.md)
  : Minimal Theme for Scientific Map Plots
- [`add_alberta_flag()`](https://ABbiodiversity.github.io/sciCentRverse/reference/add_alberta_flag.md)
  : Add Alberta flag to a site data frame using precise boundaries

## General Utilities

Miscellaneous data processing and helper functions.

- [`estimate_processing_time()`](https://ABbiodiversity.github.io/sciCentRverse/reference/estimate_processing_time.md)
  : Estimate Total Processing Time
- [`extract_by_year()`](https://ABbiodiversity.github.io/sciCentRverse/reference/extract_by_year.md)
  : Extract Raster Values by Year
- [`format_time_diff()`](https://ABbiodiversity.github.io/sciCentRverse/reference/format_time_diff.md)
  : Format Time Difference
- [`load_most_recent_data()`](https://ABbiodiversity.github.io/sciCentRverse/reference/load_most_recent_data.md)
  : Load the Most Recent Data File Dynamically
- [`load_rdata_files()`](https://ABbiodiversity.github.io/sciCentRverse/reference/load_rdata_files.md)
  : Load .RData Files into a List
- [`parallel_extract_directory()`](https://ABbiodiversity.github.io/sciCentRverse/reference/parallel_extract_directory.md)
  : Parallel Extraction of Raster Data Stored in a Directory
- [`read_tifs_to_list()`](https://ABbiodiversity.github.io/sciCentRverse/reference/read_tifs_to_list.md)
  : Read TIF Files into a Named List
- [`read_tifs_to_multiband()`](https://ABbiodiversity.github.io/sciCentRverse/reference/read_tifs_to_multiband.md)
  : Read TIF Files into a Multiband Raster Object
- [`run_step()`](https://ABbiodiversity.github.io/sciCentRverse/reference/run_step.md)
  : Run a Pipeline Step with Logging
- [`sample_blocks()`](https://ABbiodiversity.github.io/sciCentRverse/reference/sample_blocks.md)
  : Sample a fraction of rows within blocks
- [`select_one_response()`](https://ABbiodiversity.github.io/sciCentRverse/reference/select_one_response.md)
  : Select a single response column
- [`select_species()`](https://ABbiodiversity.github.io/sciCentRverse/reference/select_species.md)
  : Select a Specific Species Column
- [`set_terra_options()`](https://ABbiodiversity.github.io/sciCentRverse/reference/set_terra_options.md)
  : Set Terra Options with Buffer
- [`snake_case()`](https://ABbiodiversity.github.io/sciCentRverse/reference/snake_case.md)
  : Convert Strings to Snake Case
- [`style_active_file()`](https://ABbiodiversity.github.io/sciCentRverse/reference/style_active_file.md)
  : Style the Active R File
- [`summarize_column_classes()`](https://ABbiodiversity.github.io/sciCentRverse/reference/summarize_column_classes.md)
  : Generate a Data Frame of Column Classes
