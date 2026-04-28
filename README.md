<!--
<img src="https://drive.google.com/uc?id=1fgYuG7jpnekZrkoL_PdVUnSiUFBFX-vI" alt="Logo" width="150" style="float: left; margin-right: 10px;">
-->
<img src="man/figures/sciCentRverse_logo.png" alt="ABMI Logo" width="300" style="margin-top: 40px;">



# sciCentRverse

![In Development](https://img.shields.io/badge/Status-In%20Development-yellow) 
![Lifecycle](https://img.shields.io/badge/Lifecycle-Experimental-orange)
![Package](https://img.shields.io/badge/Type-R%20Package-blueviolet)

<img src="man/figures/science_centre_logo_unofficial.png" alt="ABMI Science Centre (Unofficial)" width="185">

> [!IMPORTANT]
> This package is intended for internal use within the **ABMI Science Centre** and serves as a development playground for prototyping, testing, and iterating on cross-project functions and workflows.
> 

## Installation

You can install the package directly from GitHub:

```r
devtools::install_github("ABbiodiversity/sciCentRverse")
```

## Functions

The package includes the following utility functions:

### Spatial Functions
- `add_alberta_flag()` - Add Alberta flag to a site data frame using provincial boundaries
- `extract_by_year()` - Extract raster values by year from spatial features
- `parallel_extract_directory()` - Parallel extraction of raster data stored in a directory

### Time & Processing Functions
- `estimate_processing_time()` - Estimate total processing time based on subset
- `format_time_diff()` - Format time difference as days, hours, minutes, and seconds

### File I/O Functions
- `load_most_recent_data()` - Load the most recent .RData file dynamically
- `load_rdata_files()` - Load .RData files into a list
- `read_tifs_to_list()` - Read TIF files into a named list
- `read_tifs_to_multiband()` - Read TIF files into a multiband raster object

### Data Manipulation Functions
- `select_one_response()` - Select a single response column from data
- `select_species()` - Select a specific species column
- `sample_blocks()` - Sample a fraction of rows within blocks
- `snake_case()` - Convert strings to snake_case
- `summarize_column_classes()` - Generate a data frame of column classes

### Configuration Functions
- `set_terra_options()` - Set Terra options with buffer for memory management

### Plotting & Styling Functions
- `theme_science()` - Minimal theme for scientific plots
- `theme_science_map()` - Minimal theme for scientific map plots
- `style_active_file()` - Style the active R file using styler

### Camera Methods Functions
- `cam_get_op_days()` - Get a dataframe of operational days for each camera
- `cam_summarise_op_by_season()` - Summarise operational days by user-defined seasons
- `cam_consolidate_tags()` - Consolidate per-image species tags into one row from a WildTrax main report
- `cam_obtain_n_gap_class()` - Identify "N" gap boundaries where a NONE is found between animal images
- `cam_calc_time_by_series()` - Calculate time-in-front-of-camera by series (in seconds)
- `cam_sum_total_time()` - Summarise total time by project, location, species, and season (with op-days)
- `cam_extract_model_lookup()` - Extract camera models from an image report
- `cam_calc_density_by_loc()` - Calculate density at each location from seasonal time and EDD

## Usage

```r
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

The package requires the following R packages:
- dplyr
- sf
- terra
- rnaturalearth
- ggplot2
- glue
- parallel

## License

MIT 
