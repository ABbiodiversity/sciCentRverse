# Summarise operational days by user-defined seasons

Takes the output from
[`cam_get_op_days()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_get_op_days.md)
and sums the number of **operational days** per season. Seasons are
defined by Julian day **start** cutoffs and can be 1..n segments that
wrap the year.

## Usage

``` r
cam_summarise_op_by_season(
  calendar_df,
  grouping = c("project", "project_id", "location", "location_id"),
  seasons = c(spring = 99, summer = 143, winter = 288),
  labels = NULL,
  date_col = "date",
  operating_col = "operating",
  na_as = FALSE,
  by_year = FALSE,
  wide = TRUE
)
```

## Arguments

- calendar_df:

  A tibble/data.frame with at least `date` (Date) and `operating`
  (logical/NA), typically the output of
  [`cam_get_op_days()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_get_op_days.md).

- grouping:

  Character vector of grouping columns to keep in the summary. Defaults
  to `c("project","project_id","location","location_id")`; only columns
  present are used. If none are present, aggregation is global.

- seasons:

  Season starts. Named numeric, unnamed numeric + `labels`, or a data
  frame with `season` and `start` columns. Defaults to
  `c(spring = 99, summer = 143, winter = 288)`.

- labels:

  Optional labels if `seasons` is an unnamed numeric vector.

- date_col:

  Name of the date column in `calendar_df`. Default `"date"`.

- operating_col:

  Name of the logical operating column. Default `"operating"`.

- na_as:

  Logical: treat `NA` in `operating` as TRUE when counting? Default
  `FALSE`.

- by_year:

  Logical: also summarise by calendar year? Default `FALSE`.

- wide:

  Logical: return one column per season (`TRUE`) or a long table with
  `season` and `operating_days` (`FALSE`). Default `TRUE`.

## Value

A tibble. In **wide** mode: grouping cols (+ `year` if `by_year`), one
column per season (counts), and `total_days` (row sum). In **long**
mode: grouping cols (+ `year`), `season`, `operating_days`, and
`total_days`.

## Details

**Season definitions** (`seasons`) can be supplied in any of these
forms:

- **Named numeric vector** (recommended): e.g.,
  `c(spring = 99, summer = 143, winter = 288)`.

- **Unnamed numeric + `labels=`**: e.g.,
  `seasons = c(99, 143, 288), labels = c("spring","summer","winter")`.

- **Data frame** with columns `season` (labels) and `start` (Julian
  day).

Rules:

- Starts must be integers in `1..366`, unique, and will be sorted.

- Classification is circular: the last season runs to day 366, then
  wraps to the first start.

**Grouping**: By default the function looks for
`c("project","project_id","location", "location_id)` but only use the
ones actually present in `calendar_df`. If none are present, the result
is aggregated across all records.

**Operating NA handling**: By default `operating = NA` is counted as
`FALSE` (`na_as = FALSE`). Set `na_as = TRUE` to count unknown days as
operational.

## See also

[`cam_get_op_days`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_get_op_days.md)

## Author

Marcus Becker

## Examples

``` r
if (FALSE) { # \dontrun{
cal <- cam_get_op_days(image_reports,
                       grouping = c("project_id","location","location_id"),
                       span = "operational", missing_as = FALSE)

# Default seasons, by year, wide format
sum1 <- cam_summarise_op_by_season(cal, by_year = TRUE, wide = TRUE)

# Two-season example, long format
sum2 <- cam_summarise_op_by_season(
  calendar_df = cal,
  seasons     = c(IceFree = 120, FreezeUp = 305),
  by_year     = FALSE,
  wide        = FALSE
)
} # }
```
