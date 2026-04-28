# Parallel Extraction of Raster Data Stored in a Directory

Executes a parallelized approach to extract values from multi-band
raster files using a custom extraction function for each spatial feature
in `locations`.

## Usage

``` r
parallel_extract_directory(
  locations,
  tif_directory,
  bands,
  extract_fun = extract_by_year,
  extract_args = list(fun = "mean"),
  extra_exports = NULL
)
```

## Arguments

- locations:

  sf or Spatial object. Geographic features for which raster values are
  extracted.

- tif_directory:

  Character. The directory path containing the TIF files.

- bands:

  Character vector. The subset of raster bands to extract from each TIF
  file.

- extract_fun:

  Function. The function used to perform the extraction. Defaults to
  `extract_by_year` (replace as needed).

- extract_args:

  List. Additional arguments passed on to `extract_fun`. Defaults to
  `list(fun = "mean")`.

- extra_exports:

  Character vector. Names of additional objects or functions to export
  to the cluster environment, if needed.

## Value

A list of extraction results, one element per feature in `locations`.

## Examples

``` r
# Example usage of the function
# Suppose you have a set of locations (e.g., sf polygons or points)
# buffers <- sf::read_sf("path/to/shapefile.shp")

# result <- parallel_extract_directory(
#   locations     = list of location buffers,
#   tif_directory = "path/to/tifs",
#   bands         = c("SR_B1", "NDVI"),
#   extract_fun   = extract_by_year,
#   extract_args  = list(fun = "mean")
# )

# print(result)
```
