# Format Time Difference

This function calculates the difference between two timestamps and
formats it as days, hours, minutes, and seconds for readability.

## Usage

``` r
format_time_diff(start_time, end_time)
```

## Arguments

- start_time:

  POSIXct. The starting timestamp.

- end_time:

  POSIXct. The ending timestamp.

## Value

Character. A formatted string showing the time difference in days,
hours, minutes, and seconds.

## Examples

``` r
# Example usage of the function
start_time <- Sys.time()
Sys.sleep(5) # Simulate a delay
end_time <- Sys.time()
format_time_diff(start_time, end_time)
#> [1] "0 days, 0 hours, 0 minutes, 5.01 seconds"
```
