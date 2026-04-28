# Read TIF Files into a Named List

Reads all `.tif` files from a specified directory and stores them as
raster objects in a named list. The names of the list elements are
derived from the TIF file names (without the `.tif` extension).

## Usage

``` r
read_tifs_to_list(tif_directory, tif_list = list())
```

## Arguments

- tif_directory:

  Character, the path to the directory containing `.tif` files.

- tif_list:

  List, an optional existing list to append the raster objects to.
  Defaults to an empty list.

## Value

A list where each element is a raster object, named after the
corresponding TIF file.

## Examples

``` r
# Example usage of the function
tif_directory <- "path/to/tif/files"
tif_list <- read_tifs_to_list(tif_directory)
print(names(tif_list)) # Display names of list elements
#> NULL
```
