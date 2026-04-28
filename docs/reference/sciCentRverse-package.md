# sciCentRverse: Personal R Utility Functions

An internal R package for prototyping, testing, and refining reusable
functions for data processing, visualization, species distribution
modelling, and general analyses across Science Centre projects. Includes
functions for spatial data handling, raster extraction, time estimation,
file loading, and data formatting.

An internal R package for prototyping, testing, and refining reusable
functions for data processing, visualization, species distribution
modelling, and general analyses across Science Centre projects.

## Key Functions

- [`add_alberta_flag()`](https://ABbiodiversity.github.io/sciCentRverse/reference/add_alberta_flag.md):
  Flag points inside Alberta using `sf` and `rnaturalearth`.

- [`extract_by_year()`](https://ABbiodiversity.github.io/sciCentRverse/reference/extract_by_year.md):
  Extract data grouped by year.

- [`read_tifs_to_list()`](https://ABbiodiversity.github.io/sciCentRverse/reference/read_tifs_to_list.md),
  [`read_tifs_to_multiband()`](https://ABbiodiversity.github.io/sciCentRverse/reference/read_tifs_to_multiband.md):
  Read rasters.

- [`estimate_processing_time()`](https://ABbiodiversity.github.io/sciCentRverse/reference/estimate_processing_time.md):
  Estimate runtime.

- [`load_most_recent_data()`](https://ABbiodiversity.github.io/sciCentRverse/reference/load_most_recent_data.md),
  [`load_rdata_files()`](https://ABbiodiversity.github.io/sciCentRverse/reference/load_rdata_files.md):
  File loading helpers.

- [`sample_blocks()`](https://ABbiodiversity.github.io/sciCentRverse/reference/sample_blocks.md):
  Sampling helpers for spatial workflows.

- [`set_terra_options()`](https://ABbiodiversity.github.io/sciCentRverse/reference/set_terra_options.md):
  Configure `terra`.

- [`snake_case()`](https://ABbiodiversity.github.io/sciCentRverse/reference/snake_case.md):
  String case utilities.

- [`style_active_file()`](https://ABbiodiversity.github.io/sciCentRverse/reference/style_active_file.md):
  Format active file with `styler`.

- [`summarize_column_classes()`](https://ABbiodiversity.github.io/sciCentRverse/reference/summarize_column_classes.md):
  Inspect data frame column classes.

## See also

Useful links:

- <https://ABbiodiversity.github.io/sciCentRverse/>

- <https://github.com/ABbiodiversity/sciCentRverse>

- Report bugs at
  <https://github.com/ABbiodiversity/sciCentRverse/issues>

Useful links:

- <https://ABbiodiversity.github.io/sciCentRverse/>

- <https://github.com/ABbiodiversity/sciCentRverse>

- Report bugs at
  <https://github.com/ABbiodiversity/sciCentRverse/issues>

## Author

**Maintainer**: Brendan Casey <bgcasey@ualberta.ca>

Authors:

- Marcus Becker <mabecker@ualberta.ca>
