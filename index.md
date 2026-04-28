# sciCentRverse

![ABMI Logo](reference/figures/sciCentRverse_logo.png)

![In
Development](https://img.shields.io/badge/Status-In%20Development-yellow)![Lifecycle](https://img.shields.io/badge/Lifecycle-Experimental-orange)![Package](https://img.shields.io/badge/Type-R%20Package-blueviolet)

![ABMI Science Centre
(Unofficial)](reference/figures/science_centre_logo_unofficial.png)

> \[!IMPORTANT\] This package is intended for internal use within the
> **ABMI Science Centre** and serves as a development playground for
> prototyping, testing, and iterating on cross-project functions and
> workflows.

## Installation

You can install the package directly from GitHub:

``` r
devtools::install_github("ABbiodiversity/sciCentRverse")
```

## Functions

The package includes the following utility functions:

### Spatial Functions

- [`add_alberta_flag()`](https://ABbiodiversity.github.io/sciCentRverse/reference/add_alberta_flag.md) -
  Add Alberta flag to a site data frame using provincial boundaries
- [`extract_by_year()`](https://ABbiodiversity.github.io/sciCentRverse/reference/extract_by_year.md) -
  Extract raster values by year from spatial features
- [`parallel_extract_directory()`](https://ABbiodiversity.github.io/sciCentRverse/reference/parallel_extract_directory.md) -
  Parallel extraction of raster data stored in a directory

### Time & Processing Functions

- [`estimate_processing_time()`](https://ABbiodiversity.github.io/sciCentRverse/reference/estimate_processing_time.md) -
  Estimate total processing time based on subset
- [`format_time_diff()`](https://ABbiodiversity.github.io/sciCentRverse/reference/format_time_diff.md) -
  Format time difference as days, hours, minutes, and seconds

### File I/O Functions

- [`load_most_recent_data()`](https://ABbiodiversity.github.io/sciCentRverse/reference/load_most_recent_data.md) -
  Load the most recent .RData file dynamically
- [`load_rdata_files()`](https://ABbiodiversity.github.io/sciCentRverse/reference/load_rdata_files.md) -
  Load .RData files into a list
- [`read_tifs_to_list()`](https://ABbiodiversity.github.io/sciCentRverse/reference/read_tifs_to_list.md) -
  Read TIF files into a named list
- [`read_tifs_to_multiband()`](https://ABbiodiversity.github.io/sciCentRverse/reference/read_tifs_to_multiband.md) -
  Read TIF files into a multiband raster object

### Data Manipulation Functions

- [`select_one_response()`](https://ABbiodiversity.github.io/sciCentRverse/reference/select_one_response.md) -
  Select a single response column from data
- [`select_species()`](https://ABbiodiversity.github.io/sciCentRverse/reference/select_species.md) -
  Select a specific species column
- [`sample_blocks()`](https://ABbiodiversity.github.io/sciCentRverse/reference/sample_blocks.md) -
  Sample a fraction of rows within blocks
- [`snake_case()`](https://ABbiodiversity.github.io/sciCentRverse/reference/snake_case.md) -
  Convert strings to snake_case
- [`summarize_column_classes()`](https://ABbiodiversity.github.io/sciCentRverse/reference/summarize_column_classes.md) -
  Generate a data frame of column classes

### Configuration Functions

- [`set_terra_options()`](https://ABbiodiversity.github.io/sciCentRverse/reference/set_terra_options.md) -
  Set Terra options with buffer for memory management

### Plotting & Styling Functions

- [`theme_science()`](https://ABbiodiversity.github.io/sciCentRverse/reference/theme_science.md) -
  Minimal theme for scientific plots
- [`theme_science_map()`](https://ABbiodiversity.github.io/sciCentRverse/reference/theme_science_map.md) -
  Minimal theme for scientific map plots
- [`style_active_file()`](https://ABbiodiversity.github.io/sciCentRverse/reference/style_active_file.md) -
  Style the active R file using styler

### Camera Methods Functions

- [`cam_get_op_days()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_get_op_days.md) -
  Get a dataframe of operational days for each camera
- [`cam_summarise_op_by_season()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_summarise_op_by_season.md) -
  Summarise operational days by user-defined seasons
- [`cam_consolidate_tags()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_consolidate_tags.md) -
  Consolidate per-image species tags into one row from a WildTrax main
  report
- [`cam_obtain_n_gap_class()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_obtain_n_gap_class.md) -
  Identify “N” gap boundaries where a NONE is found between animal
  images
- [`cam_calc_time_by_series()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_calc_time_by_series.md) -
  Calculate time-in-front-of-camera by series (in seconds)
- [`cam_sum_total_time()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_sum_total_time.md) -
  Summarise total time by project, location, species, and season (with
  op-days)
- [`cam_extract_model_lookup()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_extract_model_lookup.md) -
  Extract camera models from an image report
- [`cam_calc_density_by_loc()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_calc_density_by_loc.md) -
  Calculate density at each location from seasonal time and EDD

## Usage

``` r
library(sciCentRverse)

# Example: Convert strings to snake_case
snake_case(c("Normal 1991_2020 AHM", "Normal 1991_2020 bFFP"))

# Example: Format time difference
start_time <- Sys.time()
Sys.sleep(5)
end_time <- Sys.time()
format_time_diff(start_time, end_time)

# Example: Use custom ggplot2 theme
library(ggplot2)
ggplot(mtcars, aes(x = wt, y = mpg)) +
  geom_point() +
  labs(title = "Example Plot", x = "Weight", y = "MPG") +
  theme_science()
```

## Dependencies

The package requires the following R packages: - dplyr - sf - terra -
rnaturalearth - ggplot2 - glue - parallel

## License

MIT
