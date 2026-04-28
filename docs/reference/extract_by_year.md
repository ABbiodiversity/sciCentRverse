# Extract Raster Values by Year

Extracts raster values for each feature in an `sf` object based on the
`year` column. Returns a data frame of extracted values with all
original columns retained and a single set of band columns.

## Usage

``` r
extract_by_year(sf_object, raster_list, extract_args = list())
```

## Arguments

- sf_object:

  sf, a spatial features object with a `year` column.

- raster_list:

  list, a named list of raster objects, where names contain years in the
  format `name_name_year`.

- extract_args:

  list, optional arguments passed to the
  [`terra::extract`](https://rspatial.github.io/terra/reference/extract.html)
  function (e.g., `exact`, `ID`).

## Value

data.frame, a data frame containing all original columns and band
columns with extracted raster values.

## Examples

``` r
# Example data
sf_object <- sf::st_as_sf(data.frame(
    site = c("A", "B"),
    year = c(2020, 2021),
    longitude = c(-114.07, -113.49),
    latitude = c(51.05, 53.55)
), coords = c("longitude", "latitude"), crs = 4326)

raster_list <- list(
    "data_2020" = terra::rast(array(1:30, dim = c(5, 6, 3)),
        extent = c(-120, -110, 50, 55)
    ),
    "data_2021" = terra::rast(array(31:60, dim = c(5, 6, 3)),
        extent = c(-120, -110, 50, 55)
    )
)
names(raster_list[["data_2020"]]) <- c("Band1", "Band2", "Band3")
names(raster_list[["data_2021"]]) <- c("Band1", "Band2", "Band3")

# Example function call
extracted_values <- extract_by_year(
    sf_object, raster_list,
    extract_args = list(fun = "mean")
)

# Example result printing
print(extracted_values)
#>   site year Band1 Band2 Band3
#> 1    A 2020    19    19    19
#> 2    B 2021    47    47    47
```
