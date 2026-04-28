# Convert Strings to Snake Case

Converts a vector of strings to snake_case by inserting underscores
between words and converting all characters to lowercase. It also
replaces spaces with underscores.

## Usage

``` r
snake_case(x)
```

## Arguments

- x:

  Character vector. The input strings to be converted.

## Value

A character vector with the converted strings in snake_case.

## Examples

``` r
snake_case(c("Normal 1991_2020 AHM", "Normal 1991_2020 bFFP"))
#> [1] "normal_1991_2020_ahm"   "normal_1991_2020_b_ffp"
# Returns: c("normal_1991_2020_ahm", "normal_1991_2020_b_ffp")
```
