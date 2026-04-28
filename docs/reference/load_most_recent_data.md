# Load the Most Recent Data File Dynamically

This function dynamically loads the most recent `.rData` file from a
specified directory that matches a given file prefix and follows the
naming convention: `prefix`YYYY-MM-DD.RData.

## Usage

``` r
load_most_recent_data(directory, file_prefix)
```

## Arguments

- directory:

  character. Path to the directory containing the `.rData` files.

- file_prefix:

  character. Prefix of the file to search for (e.g.,
  "data_for_models\_").

## Value

Loads the data from the most recent `.rData` file into the global
environment and prints the name of the loaded file.

## Examples

``` r
# Example usage
if (FALSE) { # \dontrun{
# Example usage (requires files matching the pattern)
load_most_recent_data(
    directory = "2_pipeline/",
    file_prefix = "data_for_models_"
)
} # }
```
