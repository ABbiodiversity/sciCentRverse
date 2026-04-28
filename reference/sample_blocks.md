# Sample a fraction of rows within blocks

This function takes a data frame and samples a specified fraction of
rows within each block, defined by a given column. Sampling is done
without replacement, so each row can appear at most once in the output.

## Usage

``` r
sample_blocks(data, frac = 0.05, block_column)
```

## Arguments

- data:

  A data frame containing the data to sample from.

- frac:

  Numeric. Fraction of rows to sample from each block (default = 0.05).

- block_column:

  Character. The name of the column in `data` that defines blocks.

## Value

A data frame containing the sampled rows, with approximately `frac` rows
per block.

## Examples

``` r
set.seed(123)
df <- data.frame(
    block_id = rep(letters[1:4], each = 1000),
    value = rnorm(4000)
)
df_sub <- sample_blocks(
    df,
    frac = 0.05, block_column = "block_id"
)
dplyr::count(df_sub, block_id)
#> # A tibble: 4 × 2
#>   block_id     n
#>   <chr>    <int>
#> 1 a           50
#> 2 b           50
#> 3 c           50
#> 4 d           50
```
