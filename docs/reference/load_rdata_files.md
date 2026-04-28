# Load .RData Files into a List

This function scans a directory for `.RData` files, loads each file, and
stores all objects from the `.RData` files into a single list.

## Usage

``` r
load_rdata_files(data_dir)
```

## Arguments

- data_dir:

  Character. The path to the directory containing `.RData` files.

## Value

A list where each element is an object loaded from the `.RData` files.

## Examples

``` r
if (FALSE) { # \dontrun{
# Example usage of the function
data_dir <- "path/to/your/data/directory"
all_data <- load_rdata_files(data_dir)
print(names(all_data)) # Prints the names of loaded objects
} # }
```
