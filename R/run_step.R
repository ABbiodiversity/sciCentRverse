#' Run a Pipeline Step with Logging
#'
#' Executes an R script as part of a data processing pipeline, with
#' optional logging to file and execution time tracking.
#'
#' @param label Character string. A descriptive label for the pipeline
#'   step, used in console output and log file naming.
#' @param script Character string. The filename of the R script to
#'   execute, relative to `code_dir`.
#'
#' @details
#' This function:
#' \itemize{
#'   \item Prints the step label and timing information to console
#'   \item Creates a timestamped log file in `2_pipeline/logs/`
#'   directory
#'   \item Redirects both standard output and messages to the log file
#'   \item Sources (executes) the specified script from `code_dir`
#'   \item Calculates and displays the execution duration
#'   \item Automatically closes log file connections via `on.exit()`
#' }
#'
#' Log files are named using the pattern:
#' `YYYY-MM-DD_HH-MM-SS_<sanitized_label>.log`
#' Label sanitization converts non-alphanumeric characters to
#' underscores.
#'
#' @return NULL (invisibly). Output is printed to console and/or log
#' file.
#'
#' @note
#' Requires the global variable `code_dir` to be defined. Requires the
#' function `format_time_diff()` to be available. Logging is controlled
#' by the `enable_logging` variable.
#'
#' @examples
#' \dontrun{
#'   code_dir <- "1_code/r_scripts"
#'   run_step("Data Import", "01_import_data.R")
#'   run_step("Data Cleaning", "02_clean_data.R")
#' }
#' @export
run_step <- function(label, script) {
    cat("\n--- Running ", label, " ---\n", sep = "")
    start <- Sys.time()

    # Optional: write output to a log file
    enable_logging <- TRUE
    if (isTRUE(enable_logging)) {
        log_dir <- "2_pipeline/logs"
        if (!dir.exists(log_dir)) {
            dir.create(log_dir, recursive = TRUE)
        }

        ts <- format(Sys.time(), "%Y-%m-%d_%H-%M-%S")
        safe_label <- gsub("[^A-Za-z0-9_]+", "_", label)
        log_file <- file.path(
            log_dir,
            paste0(ts, "_", safe_label, ".log")
        )

        con_out <- file(log_file, open = "wt")
        con_msg <- file(log_file, open = "at")
        sink(con_out, split = TRUE)
        sink(con_msg, type = "message")
        on.exit({
            sink(type = "message")
            sink()
            close(con_msg)
            close(con_out)
        }, add = TRUE)

        cat("[", ts, "] Logging to ", log_file, "\n", sep = "")
    }

    source(file.path(code_dir, script))
    end <- Sys.time()
    elapsed <- format_time_diff(start, end) # nolint
    elapsed <- sub(
        ", [0-9.]+ seconds",
        "",
        elapsed
    )
    cat("Completed ", label, " in ", elapsed, "\n", sep = "")
}
