# Style the Active R File

Locate the currently active R source file (in RStudio or from the –file
command line argument) and run styler::style_file on it using a
tidyverse style with 2-space indent.

## Usage

``` r
style_active_file()
```

## Value

Invisibly returns the path to the styled file, or NULL if no active file
was found.
