#' @keywords internal
#' @importFrom data.table :=
#' @importFrom utils head
"_PACKAGE"

# Global variables used in NSE across dplyr/data.table pipelines
utils::globalVariables(c(
  # dot-prefixed helpers (from cam fns)
  ".date",".dt",".elapsed",".has_numeric",".in",".is_none",".model_raw",
  ".next_row_full",".next_sp",".next_time",".none_between",".none_cumul",
  ".none_cumul_end",".none_cumul_prev",".none_cumul_start",".op",".row_full",
  ".same_species",".season",".sp",".sum_count",".yday",".year",
  # plain column names flagged by R CMD check
  "age_class","area_m2","cpue","density_km2","diff_next_s","diff_prev_s",
  "dt_prev","edd_pool","effort","first_true","gap_prev_s","height",
  "image_date_time","image_id","image_time_ni_s","image_time_s",
  "individual_count","is_bookend","last_true","model","n_models",
  "new_series","next_ts","operating","operating_days","overall_category",
  "prev_ts","project","season","series_num","series_start","series_total_time",
  "sex_class","species_common_name","tag_id","tbp","total_duration",
  "total_season_days"
))
