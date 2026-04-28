# Consolidate per-image species tags into one row from a WildTrax main report

For each
`(project_id, location, location_id, image_id, species_common_name)`
group, sum `individual_count` (numeric rows) and collapse `age_class` /
`sex_class` by replicating each tag by that row's count and joining with
`", "`. The `image_date_time` is retained and must be identical within
each image. Non-species rows (e.g., `"STAFF/SETUP"`, `"NONE"`) are
preserved unchanged. Rows whose `species_common_name` is neither in
`native_sp` nor in the non-species list are **dropped with a warning**
listing the unexpected labels and row counts.

## Usage

``` r
cam_consolidate_tags(report)
```

## Arguments

- report:

  A data.frame/tibble with at least:
  `project_id, location, location_id, image_id, image_date_time, species_common_name, individual_count, age_class, sex_class, tag_id`.
  Should be a main report from WildTrax.

## Value

A tibble with one row per image × species:
`project_id, location, location_id, image_id, image_date_time, species_common_name, age_class, sex_class, individual_count`
(character).

## Details

Species identification uses the **internal** character vector
`native_sp` saved in `R/sysdata.rda`.

The function also **detects, warns about, and removes** likely duplicate
tag entries where all fields are identical **except** `tag_id`, which is
a possible double-entry flag. The duplicate check is applied to species
rows only, using these fields:
`project_id, location, location_id, image_id, image_date_time, species_common_name, individual_count, age_class, sex_class`.
When duplicates are found, the function keeps **one** row per identical
set (the one with the **lowest `tag_id`**) and drops the rest.

## See also

[`cam_calc_time_by_series()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_calc_time_by_series.md)
for the next step in the pipeline.

## Author

Marcus Becker

## Examples

``` r
if (FALSE) { # \dontrun{
x <- cam_consolidate_tags(main_reports)
# If duplicate tags were removed, you'll see a warning listing image_id(s).
} # }
```
