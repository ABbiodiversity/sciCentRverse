# Estimate Total Processing Time

Calculates an estimated total processing time for a complete dataset
based on the time taken to process a subset of its features. The result
is returned as a human-readable string indicating days, hours, minutes,
and remaining seconds.

## Usage

``` r
estimate_processing_time(n_features, nsub, end_time, start_time)
```

## Arguments

- n_features:

  Numeric. The total number of features in the dataset.

- nsub:

  Numeric. The number of features actually processed in the partial
  subset.

- end_time:

  POSIXct. The time the subset processing ended.

- start_time:

  POSIXct. The time the subset processing started.

## Value

Character string. A human-readable duration representing the estimated
total processing time for all features.

## Examples

``` r
# Example usage of the function

# Simulate a short processing run
start_time <- Sys.time()
Sys.sleep(2) # stand-in for some real processing
end_time <- Sys.time()

# Estimate total time if the above was a test on 100 out of
# 10,000 features
estimate_processing_time(10000, 100, end_time, start_time)
#> [1] "0 days, 0 hours, 3 minutes, 20 seconds"
```
