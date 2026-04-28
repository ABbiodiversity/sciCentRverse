# Set Terra Options with Buffer

Configure `terra` options to control memory usage, core allocation, and
temporary file storage. This function calculates resource allocations
based on total system memory, number of cores, resource percentage, and
optional memory buffer for spikes. It sets `memfrac`, `memmax`, and
`tempdir` options in `terra`.

## Usage

``` r
set_terra_options(
  total_memory_gb,
  total_cores,
  resource_percent,
  priority = "default",
  buffer_percent = 10,
  tempdir = tempdir()
)
```

## Arguments

- total_memory_gb:

  Numeric, total system memory in GB.

- total_cores:

  Integer, total number of cores available.

- resource_percent:

  Numeric, percentage of system resources to allocate for the process.

- priority:

  Character, resource allocation strategy: "memory", "speed", or
  "default". Default is "default".

- buffer_percent:

  Numeric, additional percentage of memory reserved as a buffer to
  handle spikes. Default is 10.

- tempdir:

  Character, directory for storing temporary files. Default is
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html).

## Value

Integer, the number of cores to be used for parallel processing.

## Examples

``` r
if (FALSE) { # \dontrun{
cores <- set_terra_options(
    total_memory_gb = 128,
    total_cores = 20,
    resource_percent = 50,
    priority = "default",
    buffer_percent = 10,
    tempdir = "D:/r_temp/RtmpWSPfnw"
)
print(cores)
} # }
```
