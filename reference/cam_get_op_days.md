# Get a dataframe of operational days for each camera

Build a per-day calendar for each camera deployment and mark a date as
**operational** if there is **any in-range image** that day. In-range is
defined by a field-of-view flag: `image_fov != "OOR"` is in-range;
`"OOR"` is out-of-range. By default, `NA` in `image_fov` is treated as
in-range.

## Usage

``` r
cam_get_op_days(
  df,
  grouping = c("project", "project_id", "location", "location_id"),
  datetime_col = "image_date_time",
  fov_col = "image_fov",
  oor_flag = "OOR",
  na_fov_means_inrange = TRUE,
  trigger_col = "image_trigger_mode",
  trigger_exclude_value = "CodeLoc Not Entered",
  span = c("data", "operational"),
  missing_as = TRUE
)
```

## Arguments

- df:

  Image report tibble/data.frame.

- grouping:

  Camera identity columns (only those present are used).

- datetime_col:

  Timestamp column name. Default `"image_date_time"`.

- fov_col:

  Field-of-view flag column. Default `"image_fov"`.

- oor_flag:

  String indicating out-of-range in `fov_col`. Default `"OOR"`.

- na_fov_means_inrange:

  Logical; treat `NA` in `fov_col` as in-range? Default TRUE.

- trigger_col:

  Column that indicates trigger mode. Default `"image_trigger_mode"`.

- trigger_exclude_value:

  Value in `trigger_col` to exclude entirely from the calendar and ops
  logic. Default `"CodeLoc Not Entered"`.

- span:

  `"data"` or `"operational"`. Default `"data"`.

- missing_as:

  Fill for days with no images after expansion: one of TRUE, FALSE, or
  NA.

## Value

Tibble of `grouping`, `date` (Date), and `operating` (logical/NA).

## Details

The function:

1.  **Pre-filters** rows where `trigger_col == trigger_exclude_value`
    (default `"CodeLoc Not Entered"`). These rows do not contribute to
    operating days or calendar span.

2.  Parses the image timestamp to `Date`.

3.  Flags in-range by `fov_col != oor_flag` (or `NA` treated by
    `na_fov_means_inrange`).

4.  Aggregates to daily `operating = any(in-range)`.

5.  Expands to a full daily calendar, filling missing days with
    `missing_as`.

6.  `span = "data"` uses min..max date of filtered images;
    `span = "operational"` trims to first..last TRUE `operating`.

## See also

[`cam_summarise_op_by_season`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_summarise_op_by_season.md)

## Author

Marcus Becker

## Examples

``` r
if (FALSE) { # \dontrun{
# image_reports is a WildTrax image report tibble
cal <- cam_get_op_days(
  image_reports,
  grouping   = c("project_id", "project", "location_id", "location"),
  span       = "data",
  missing_as = TRUE
)
} # }
```
