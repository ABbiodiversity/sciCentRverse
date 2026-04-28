# Calculate density at each location from seasonal time and EDD (with optional pooled fallback)

Computes seasonal (or aggregated) density estimates per deployment ×
species using time-in-front-of-camera (TIFC) totals and effective
detection distance (EDD) lookups. Supports exact EDD matches on species
group, vegetation category, season, and—when available—camera model and
height. Optionally applies a dist-group–specific pooled fallback when
exact EDDs are missing. Note that filtering locations with total days
below a certain threshold (e.g., 30 days) should be done prior to
running the this function.

## Usage

``` r
cam_calc_density_by_loc(
  duration_df,
  edd_category_df,
  model_df = NULL,
  cam_fov_angle = 40,
  format = c("long", "wide"),
  include_project = TRUE,
  height_col = "height",
  dist_groups_df = NULL,
  edd_df = NULL,
  aggregate = FALSE,
  agg_exclude_species = "Bear",
  agg_exclude_season = "winter",
  use_global_edd = FALSE,
  annotate_edd_source = TRUE
)
```

## Arguments

- duration_df:

  Tibble with: project, location, species_common_name, season,
  total_season_days, total_duration (seconds). If present, `model`
  and/or `height` are used directly.

- edd_category_df:

  Tibble with vegetation/EDD category per camera; must contain
  `overall_category` plus (`project`,`location`) or `project_location`.

- model_df:

  Optional tibble (`project`,`location`,`model`) to attach if
  `duration_df` lacks a `model` column.

- cam_fov_angle:

  Camera FOV in degrees. Default 40.

- format:

  "long" (default) or "wide".

- include_project:

  Keep `project` in wide output. Default TRUE.

- height_col:

  Column name in `duration_df` to use as height (default "height").

- dist_groups_df:

  Optional override mapping (species_common_name -\> dist_group). If
  NULL, an object named `dist_groups` must exist in your env/package.

- edd_df:

  Optional override EDD table. If NULL, an object named `edd` must
  exist. Must include: dist_group, season, overall_category, edd;
  ideally `n`, and optionally `model`, `height`.

- aggregate:

  Logical; if TRUE, return weighted mean per deployment × species
  (weights = `total_season_days`). Rows matching `agg_exclude_species` ×
  `agg_exclude_season` are removed before aggregation. See also
  `agg_exclude_species`.

- agg_exclude_species:

  Regex pattern (case-insensitive) for species to exclude from
  aggregation in a specific season. Default `"Bear"`. Set to `NULL` to
  disable exclusion entirely.

- agg_exclude_season:

  Season label(s) to exclude for the matching species. Default
  `"winter"`. Set to `NULL` to disable exclusion entirely.

- use_global_edd:

  Logical; if TRUE, fill missing exact EDDs using a
  **dist-group–specific plan**.

- annotate_edd_source:

  Logical; if TRUE (default), add `edd_source` column with values
  `"observed"`, `"prefilled"`, or `"pooled"`. See Details.

## Value

Seasonal densities (long/wide) or weighted aggregate (if
`aggregate = TRUE`).

## Details

**Inputs and joins**

- `duration_df` must contain: `project`, `location`,
  `species_common_name`, `season`, `total_season_days` (days of
  operation in that season), and `total_duration` (seconds of TIFC in
  that season). If present, `model` and/or `height` are used directly.

- `edd_category_df` must provide `overall_category` for each (`project`,
  `location`) (or via `project_location` that gets split).

- Species are mapped to EDD groups via `dist_groups` (override with
  `dist_groups_df`).

- EDDs are taken from `edd` (override with `edd_df`). Exact joins use
  keys: `dist_group`, `overall_category`, `season`, and, when present in
  both data and lookup, `model` and/or `height`. If multiple EDD rows
  share the same keys, the entry with the largest `n` is chosen.

**Density calculation**

- Area per season (m²): `area_m2 = π * (edd^2) * (cam_fov_angle / 360)`.

- Effort per season (m²·10⁻²):
  `effort = total_season_days * (area_m2 / 100)` (legacy factor).

- CPUE: `cpue = total_duration / effort`.

- Density (km⁻²): `density_km2 = (cpue / 86400) * 10000`.

- If `edd`, `effort`, or `total_season_days` are missing/zero,
  `density_km2` is `NA`.

**Pooled EDD fallback (`use_global_edd = TRUE`)** Uses weighted pooled
EDDs (weights = `n`) following a conservative plan per `dist_group`:

- `Coyote`, `Deer`, `LargeUngulates`: pool over `overall_category`
  (keys: `dist_group`, `season`, `model`, `height`; absent keys are
  ignored).

- `Bear`, `Hare`, `Lynx`, `SmallMustelids`, `Wolf`: try pooled-overall
  first, then pool over height. If pooling supplies an EDD and
  `annotate_edd_source = TRUE`, marks `edd_source = "pooled"`. If
  pooling fails, density remains `NA`.

**EDD source annotation (`annotate_edd_source = TRUE`)** Adds an
`edd_source` column with three levels:

- `"observed"`: EDD came from a direct match in the lookup table with
  `n > 0` (real measured detections).

- `"prefilled"`: EDD came from a direct match but `n = 0`, meaning the
  value was pre-filled in the sysdata EDD table to cover a missing
  model/height combination within the vegetation category.

- `"pooled"`: no exact match existed; EDD was derived at runtime by
  `use_global_edd` pooling across vegetation categories.

**Aggregation (`aggregate = TRUE`)**

- Returns one row per deployment × species with
  `weighted.mean(density_km2, w = total_season_days, na.rm = TRUE)`.

- Removes Bear–winter rows before aggregation (including zeros).

- When `annotate_edd_source = TRUE`, `edd_source` is carried through
  using the most conservative level across seasons: `"pooled"` \>
  `"prefilled"` \> `"observed"`.

**Outputs**

- `format = "long"`: per-season rows with `overall_category`, `model`,
  `height`, `total_season_days`, `total_duration`, `density_km2`, and
  (optionally) `edd_source`.

- `format = "wide"`: densities pivoted to one row per deployment
  (diagnostic season-day columns included).

- `aggregate = TRUE`: one row per deployment × species (no seasons).

## See also

[`cam_sum_total_time()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_sum_total_time.md),
[`cam_calc_time_by_series()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_calc_time_by_series.md),
[`cam_summarise_op_by_season()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_summarise_op_by_season.md)

## Author

Marcus Becker

## Examples

``` r
if (FALSE) { # \dontrun{
# dur is the output of cam_sum_total_time(), with model and height columns added
density <- dur |>
  dplyr::left_join(model_lookup, by = c("project", "location")) |>
  dplyr::mutate(height = "high") |>
  dplyr::filter(total_season_days >= 30) |>
  cam_calc_density_by_loc(
    edd_category_df     = edd_categories,
    cam_fov_angle       = 40,
    format              = "long",
    aggregate           = TRUE,
    use_global_edd      = TRUE,
    annotate_edd_source = TRUE
  )
} # }
```
