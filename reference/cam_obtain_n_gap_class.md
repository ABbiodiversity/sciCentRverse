# Identify "N" gap boundaries where a NONE is found between animal images

Flags boundaries where an animal image is followed (after one or more
rows of `NONE`) by another animal image within a short time window.
These should be split into separate series because the intervening
`NONE` indicates the animal left the FOV, even if the total
animal-to-animal image gap is small.

## Usage

``` r
cam_obtain_n_gap_class(
  cons_main_report,
  grouping = c("project", "project_id", "location", "location_id"),
  datetime_col = "image_date_time",
  species_col = "species_common_name",
  none_label = "NONE",
  max_bridge_secs = 120,
  require_same_species = TRUE
)
```

## Arguments

- cons_main_report:

  Main report with consolidated tags (e.g., from
  [`cam_consolidate_tags()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_consolidate_tags.md)),
  requiring: `image_date_time`, `image_id`, `species_common_name`, and
  camera identity columns.

- grouping:

  Character vector of camera identity columns. Only those present are
  used. Default: c("project","project_id","location","location_id").

- datetime_col:

  Name of the timestamp column. Default "image_date_time".

- species_col:

  Name of the species column. Default "species_common_name".

- none_label:

  Label denoting a NONE image. Default "NONE".

- max_bridge_secs:

  Numeric, maximum animal-to-animal elapsed seconds to still consider a
  bridged series. Default 120.

- require_same_species:

  Logical, require same species before/after the NONE block? Default
  TRUE.

## Value

A tibble with one row per detected boundary: grouping columns,
`image_id`, `image_date_time`, `species_common_name`, `gap_class = "N"`.
If none are found, returns an empty tibble and warns.

## See also

[`cam_calc_time_by_series()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_calc_time_by_series.md)
which accepts the output of this function via its `n_gap_df` parameter
to force series splits at NONE-bridged boundaries.

## Author

Marcus Becker
