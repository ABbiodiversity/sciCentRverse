## code to prepare `internal-data` dataset goes here

dist_groups <- readr::read_csv("inst/extdata/dist_groups.csv",
                               show_col_types = FALSE)
edd <- readr::read_csv("inst/extdata/edd_predictions.csv",
                       show_col_types = FALSE)
gap_groups <- readr::read_csv("inst/extdata/gap_groups.csv",
                              show_col_types = FALSE)
leave_prob_pred <- readr::read_csv("inst/extdata/leave_prob_pred.csv",
                                   show_col_types = FALSE)
tbi <- readr::read_csv("inst/extdata/tbi.csv",
                       show_col_types = FALSE)
load("inst/extdata/species.RData")

# Save as internal data (R/sysdata.rda)
usethis::use_data(
  native_sp,
  dist_groups,
  edd,
  gap_groups,
  leave_prob_pred,
  tbi,
  internal  = TRUE,
  overwrite = TRUE,
  compress  = "xz"
)
