# Generate a Data Frame of Column Classes

This function takes a list of data frames and returns a summary data
frame showing the classes of each column across all the data frames.
Missing columns in some data frames are represented as NA.

## Usage

``` r
summarize_column_classes(all_data)
```

## Arguments

- all_data:

  List. A list of data frames.

## Value

A data frame with rows representing the data frames and columns
representing the column names from all the data frames. The values are
the classes of the columns or NA if the column is missing in a data
frame.

## Examples

``` r
# Example usage:
all_data <- list(
    df1 = data.frame(a = 1:3, b = letters[1:3]),
    df2 = data.frame(a = 4:6, c = c(TRUE, FALSE, TRUE))
)
column_classes_df <- summarize_column_classes(all_data)
print(column_classes_df)
#>   data_frame       a         b       c
#> 1        df1 integer character    <NA>
#> 2        df2 integer      <NA> logical
```
