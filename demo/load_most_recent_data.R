# Demo: load_most_recent_data
# Create a temporary directory with several .RData files named with a
# common prefix and date. Use load_most_recent_data() to load the most
# recent file into the global environment.

# Setup ----
library(sciCentRverse)

## Create demo files ----
# Create a temporary demo directory with dated .RData files
prefix <- "demo_data_"
demo_dir <- file.path("demo_pipeline")
dir.create(demo_dir, showWarnings = FALSE, recursive = TRUE)

# Build three example date strings
base_date <- as.Date(Sys.Date())
date_strings <- format(base_date + c(-7, -2, 0), "%Y-%m-%d")

for (date_str in date_strings) {
  demo_obj <- list(date = date_str, values = rnorm(5))
  save(
    demo_obj,
    file = file.path(demo_dir, paste0(prefix, date_str, ".RData"))
  )
}

# Load most recent ----
# Load the most recent file into the global environment
load_most_recent_data(directory = demo_dir, file_prefix = prefix)

# Inspect the loaded object
print(demo_obj)

# Cleanup (optional) ----
# Optional cleanup: remove the demo directory and files
if (TRUE) {
  unlink(demo_dir, recursive = TRUE, force = TRUE)
}

# End of demo