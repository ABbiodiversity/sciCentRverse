# Summarise total time by project, location, species, and season (with op-days)

Rolls up image-series time (seconds) to seasonal totals per deployment ×
species and attaches the number of operating days per season. Seasons
are assigned by Julian cutoffs you provide (e.g., spring = 99, summer =
143, winter = 288). Output is ready to feed into density calculations
that require both `total_duration` and `total_season_days`.

## Usage

``` r
cam_sum_total_time(
  series_df,
  season_cutoffs = c(spring = 99L, summer = 143L, winter = 288L),
  tz = Sys.timezone(),
  op_days_df,
  species_universe = NULL
)
```

## Arguments

- series_df:

  Output of cam_calc_time_by_series(); needs project, location,
  species_common_name, series_start, series_total_time

- season_cutoffs:

  Named integer vector of Julian cutoffs, e.g. c(spring=99L,
  summer=143L, winter=288L). Labels come from names (lower-case
  recommended for consistency with EDD lookups). Cutoffs are
  auto-sorted, so order does not matter.

- tz:

  Time zone used to extract the Julian day from `series_start`. Defaults
  to [`Sys.timezone()`](https://rdrr.io/r/base/timezones.html) (the
  local system timezone). WildTrax timestamps are typically stored in
  local time, so this default is usually correct. Override explicitly
  (e.g. `"America/Edmonton"`) when running on a machine whose timezone
  does not match the study area.

- op_days_df:

  Operating-days table (required) for zero-fill + days per season.
  Accepts EITHER:

  - long: project, location, season, total_season_days (or
    operating_days), or

  - wide: project, location, one column per season label (values are day
    counts). Typically the output of
    `cam_summarise_op_by_season(wide = TRUE)`.

- species_universe:

  Optional vector used for zero-fill across species

## Value

Tibble with: project, location, species_common_name, season,
total_duration, total_season_days

## Details

**Season assignment**

- Each series row is assigned to a season using the Julian day of
  `series_start` in the chosen `tz`. Cutoffs must be strictly
  increasing; season labels come from the names of `season_cutoffs` and
  are used downstream (keep them lower-case for consistency with EDD
  lookups).

**Aggregation**

- Within each `project` × `location` × `species_common_name` × `season`,
  the function sums `series_total_time` to produce `total_duration` in
  seconds.

**Operating days**

- `op_days_df` can be supplied either in long form (has a `season`
  column and a day-count column named `total_season_days` or
  `operating_days`) or wide form (one column per season label). The
  function normalizes this to a long table and merges to add
  `total_season_days`.

**Zero-filling**

- To ensure locations with no detected series still appear (with 0
  duration), the function constructs the full grid of cameras (from
  `op_days_df`) × seasons, crossed with a species universe. If
  `species_universe` is not supplied, it uses the species present in
  `series_df`. This guarantees downstream density steps see explicit
  zeros rather than missing rows.

**Input requirements**

- `series_df` must include: `project`, `location`,
  `species_common_name`, `series_start` (POSIXct or parseable), and
  `series_total_time` (seconds).

- `op_days_df` must provide operating-day counts per camera × season
  (long or wide).

**Output**

- A tibble with columns: `project`, `location`, `species_common_name`,
  `season`, `total_duration` (seconds), and `total_season_days` (days).

## See also

[`cam_calc_time_by_series()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_calc_time_by_series.md),
[`cam_get_op_days()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_get_op_days.md),
[`cam_summarise_op_by_season()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_summarise_op_by_season.md)

## Author

Marcus Becker

## Examples

``` r
if (FALSE) { # \dontrun{
# series is the output of cam_calc_time_by_series()
# op_days is the output of cam_summarise_op_by_season(wide = TRUE)
dur <- cam_sum_total_time(
  series_df        = series,
  season_cutoffs   = c(spring = 99L, summer = 143L, winter = 288L),
  op_days_df       = op_days,
  species_universe = c("White-tailed Deer", "Moose", "Black Bear")
)
} # }
```
