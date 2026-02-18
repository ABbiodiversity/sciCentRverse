# Demo: run_step

# Setup ----
library(sciCentRverse)

## Create demo files ----
# Create a temporary demo directory with three R scripts
demo_dir <- file.path("demo_pipeline")
dir.create(demo_dir, showWarnings = FALSE, recursive = TRUE)

code_dir <- demo_dir

script_one <- file.path(code_dir, "01_demo_script.R")
writeLines(
    c(
        "cat('Hello from script 1.\n')",
        "x <- 1 + 1",
        "cat('x =', x, '\n')"
    ),
    con = script_one
)

script_two <- file.path(code_dir, "02_demo_script.R")
writeLines(
    c(
        "cat('Hello from script 2.\n')",
        "set.seed(42)",
        "df <- data.frame(x = 1:10, y = 2 * (1:10) + rnorm(10))",
        "fit <- lm(y ~ x, data = df)",
        "out_path <- file.path(code_dir, 'regression_summary.txt')",
        "print(summary(fit))",
        "writeLines(capture.output(summary(fit)), out_path)",
        "cat('Wrote regression summary to', out_path, '\n')"
    ),
    con = script_two
)

script_three <- file.path(code_dir, "03_demo_script.R")
writeLines(
    c(
        "cat('Hello from script 3.\n')",
        "z <- paste(letters[1:3], collapse = '-')",
        "cat('z =', z, '\n')",
        "tbl <- data.frame(id = 1:5, value = round(runif(5), 3))",
        "cat('Table output:\n')",
        "print(tbl)"
    ),
    con = script_three
)

# Run steps ----
# Execute the demo scripts with logging
run_step("Demo Step 1", "01_demo_script.R")
run_step("Demo Step 2", "02_demo_script.R")
run_step("Demo Step 3", "03_demo_script.R")

# Cleanup (optional) ----
# Optional cleanup: remove the demo directory and files
if (TRUE) {
    log_root <- file.path("2_pipeline")
    if (dir.exists(log_root)) {
        unlink(log_root, recursive = TRUE, force = TRUE)
    }
    unlink(demo_dir, recursive = TRUE, force = TRUE)
}