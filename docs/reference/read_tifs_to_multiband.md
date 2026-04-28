# Read TIF Files into a Multiband Raster Object

Reads all `.tif` files from a specified directory and combines them into
a single multiband raster object. Each band in the resulting raster
corresponds to one of the TIF files, and the band names are derived from
the TIF file names (without the `.tif` extension).

## Usage

``` r
read_tifs_to_multiband(tif_directory)
```

## Arguments

- tif_directory:

  Character, the path to the directory containing `.tif` files.

## Value

A multiband raster object (`SpatRaster`) where each band corresponds to
a `.tif` file in the directory, named after the corresponding file.

## Examples

``` r
if (FALSE) { # \dontrun{
# Example usage of the function
tif_directory <- "path/to/tif/files"
multiband_raster <- read_tifs_to_multiband(tif_directory)
print(multiband_raster) # Display the multiband raster object
plot(multiband_raster) # Plot the raster bands
} # }
```
