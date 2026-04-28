# Extract per-camera model ("hf2" / "pc900") from an image report

Minimal helper to derive a per-camera `model` from a model column
(defaults to `equipment_model`). Returns one row per camera key with
`model` in lower case.

## Usage

``` r
cam_extract_model_lookup(
  image_report,
  keys = c("project", "location"),
  model_col = "equipment_model",
  hf2_pattern = "HF2",
  pc900_pattern = "PC900|PC 900|PC-900"
)
```

## Arguments

- image_report:

  Data frame with at least `keys` and the model column. Typically a
  WildTrax image report.

- keys:

  Character vector of columns that identify a camera. Default:
  c("project","location"). If you prefer per-`location_id`, include it
  (e.g., c("project","location","location_id")).

- model_col:

  Column name (string or bare) containing the raw model text. Default
  "equipment_model".

- hf2_pattern:

  Regex used to detect HF2 models (case-insensitive). Default "HF2".

- pc900_pattern:

  Regex used to detect PC900 models (case-insensitive). Default
  "PC900\|PC 900\|PC-900".

## Value

Tibble with `keys` + `model` (values: "hf2" or "pc900").

## See also

[`cam_calc_density_by_loc()`](https://ABbiodiversity.github.io/sciCentRverse/reference/cam_calc_density_by_loc.md)
which accepts this output via `model_df`.

## Author

Marcus Becker

## Examples

``` r
if (FALSE) { # \dontrun{
# image_reports is a WildTrax image report tibble
model_lookup <- cam_extract_model_lookup(
  image_reports,
  keys      = c("project", "location"),
  model_col = "equipment_model"
)
} # }
```
