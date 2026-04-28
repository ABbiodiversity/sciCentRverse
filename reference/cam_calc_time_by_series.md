# Calculate time-in-front-of-camera by series (in seconds)

Groups consecutive images into per-species "series" at each deployment
using a time-gap threshold, then converts image timestamps into
*time-in-front-of-camera* (TIFC) in seconds. Bookend images of a series
get an extra `tbp/2` to account for shutter cadence; interior images
receive half the time to previous and next.

## Usage

``` r
cam_calc_time_by_series(
  cons_main_report,
  split_gap_secs = 120,
  tbp_lookup = NULL,
  n_gap_df = NULL,
  adjust_gap_prob = TRUE
)
```

## Arguments

- cons_main_report:

  Data frame (after cam_consolidate_tags()) with at least: project,
  location, image_id, image_date_time (POSIXct), species_common_name,
  individual_count

- split_gap_secs:

  Gap threshold to start a new series (seconds). Default 120.

- tbp_lookup:

  Optional tibble with per-species time-between-photos `tbp` (seconds).
  Columns required: `species_common_name`, `tbp`. If `NULL`, the
  function will try to use the internal package object `tbi` (from
  R/sysdata.rda). If that is not available, it falls back to tbp = 6
  seconds for all species and warns.

- n_gap_df:

  Optional output of
  [`cam_obtain_n_gap_class()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_obtain_n_gap_class.md).
  When supplied, any image flagged as an N-gap boundary (animal image
  immediately followed by a NONE block before the next same-species
  image) forces a new series to start on the image *after* it,
  regardless of the time gap. This prevents a NONE-bridged pair from
  being counted as a single continuous series. Matched on `image_id` ×
  `species_common_name`.

- adjust_gap_prob:

  Logical. If `TRUE` (default), applies a species-specific
  probability-of-leaving-FOV correction to within-series gaps of 20–120
  s, using the internal `gap_groups` and `leave_prob_pred` lookup
  tables. Set to `FALSE` to skip the adjustment and treat all
  within-series gaps as fully occupied — for example, to compare results
  under both assumptions or when working primarily with species not
  covered by the gap-group lookup.

## Value

Tibble with one row per series and species: project, location,
species_common_name, series_num, n_images, series_total_time (seconds),
series_start, series_end

## Details

**Inputs & filtering**

- Excludes rows with `species_common_name` in `c("STAFF/SETUP","NONE")`
  and any with `individual_count == "VNA"`.

- `image_date_time` must be POSIXct; the function stops if not.

- Rows are de-duplicated on
  (`project`,`location`,`image_id`,`species_common_name`,
  `image_date_time`,`individual_count`) to avoid double-counting.

**Series definition**

- Within each `project × location × species_common_name`, rows are
  sorted by `image_date_time` (then `image_id`) and the previous-gap
  (seconds) is computed.

- A new series starts at the first image or when the gap exceeds
  `split_gap_secs` (default 120 s). `series_num` is the cumulative count
  of such starts.

**Per-image time allocation**

- For each image, `diff_prev_s` is the elapsed time since the previous
  image in the same series; `diff_next_s` is the time until the next
  image in the same series. Bookends get zeros on the missing side.

- Interior image time: `(diff_prev_s + diff_next_s)/2`.

- Bookend image time: `((diff_prev_s + diff_next_s)/2) + (tbp/2)`.

- Image time is multiplied by `individual_count` (coerced numeric) to
  obtain `image_time_ni_s`.

- Note: a single-image series receives `tbp/2` (not `tbp`) unless you
  choose to post-adjust downstream.

**Probabilistic gap adjustment** (`adjust_gap_prob = TRUE`)

Within-series gaps of 20–120 s fall in an ambiguous zone: the gap is too
short to confidently split into a new series, but long enough that the
animal may have temporarily left the camera's field of view (FOV). To
account for this, a species-group-specific probability of FOV departure
(`pred`) is looked up from the internal `leave_prob_pred` table (derived
from empirical gap-length models) and applied to both sides of the gap:

\$\$diff\\prev\\adj = diff\\prev \times (1 - pred)\$\$
\$\$diff\\next\\adj = diff\\next \times (1 - pred)\$\$

This reduces the time credited across the gap proportionally to how
likely it is the animal was absent. A gap of exactly 20 s receives only
a small reduction; a gap near 120 s receives a much larger one.

Species are assigned to gap groups via the internal `gap_groups` lookup.
Any species not present in that lookup (e.g., uncommonly detected taxa)
receives no adjustment — their within-series gaps are treated as though
the animal was continuously present. If this concerns you for a given
analysis, set `adjust_gap_prob = FALSE` to disable the adjustment
entirely and inspect results under both assumptions.

**Time-between-photos (tbp)**

- Supply `tbp_lookup` with columns `species_common_name`, `tbp`
  (seconds), or let the function try to use an internal package object
  `tbi` (from `R/sysdata.rda`). If neither is available, a warning is
  issued and `tbp = 6` seconds is used as a fallback.

- If `tbp_lookup` uses a different tbp column name (e.g.,
  `time_between_photos`, `tbi`, `tbp_seconds`), it is re-mapped to
  `tbp`.

## See also

[`cam_sum_total_time()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_sum_total_time.md),
[`cam_obtain_n_gap_class()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_obtain_n_gap_class.md),
[`cam_get_op_days()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_get_op_days.md),
[`cam_summarise_op_by_season()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_summarise_op_by_season.md)

## Author

Marcus Becker

## Examples

``` r
if (FALSE) { # \dontrun{
# cons_report is the output of cam_consolidate_tags()

# Standard usage — probabilistic gap adjustment applied by default
series <- cam_calc_time_by_series(cons_report)

# With N-gap boundaries to split NONE-bridged series
n_gaps <- cam_obtain_n_gap_class(cons_report)
series <- cam_calc_time_by_series(cons_report, n_gap_df = n_gaps)

# Disable probabilistic adjustment to compare results under both assumptions
series_unadj <- cam_calc_time_by_series(cons_report, adjust_gap_prob = FALSE)
} # }
```
