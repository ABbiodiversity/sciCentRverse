# Run a Pipeline Step with Logging

Executes an R script as part of a data processing pipeline, with
optional logging to file and execution time tracking.

## Usage

``` r
run_step(label, script)
```

## Arguments

- label:

  Character string. A descriptive label for the pipeline step, used in
  console output and log file naming.

- script:

  Character string. The filename of the R script to execute, relative to
  `code_dir`.

## Value

NULL (invisibly). Output is printed to console and/or log file.

## Details

This function:

- Prints the step label and timing information to console

- Creates a timestamped log file in `2_pipeline/logs/` directory

- Redirects both standard output and messages to the log file

- Sources (executes) the specified script from `code_dir`

- Calculates and displays the execution duration

- Automatically closes log file connections via
  [`on.exit()`](https://rdrr.io/r/base/on.exit.html)

Log files are named using the pattern:
`YYYY-MM-DD_HH-MM-SS_<sanitized_label>.log` Label sanitization converts
non-alphanumeric characters to underscores.

## Note

Requires the global variable `code_dir` to be defined. Requires the
function
[`format_time_diff()`](https://ABbiodiversity.github.io/sciCentRverse/reference/format_time_diff.md)
to be available. Logging is controlled by the `enable_logging` variable.

## Examples

``` r
if (FALSE) { # \dontrun{
  code_dir <- "1_code/r_scripts"
  run_step("Data Import", "01_import_data.R")
  run_step("Data Cleaning", "02_clean_data.R")
} # }
```
