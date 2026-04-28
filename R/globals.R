# Internal globals to satisfy R CMD check for dplyr NSE
utils::globalVariables(c(
  "name_en", ".row_id_tmp", "in_alberta",
  # cam_calc_density_by_loc: edd_source used in dplyr summarise
  "edd_source",
  # cam_calc_time_by_series: .is_n_gap used in dplyr mutate
  ".is_n_gap",
  # cam_calc_time_by_series: probabilistic gap adjustment columns
  "pred", "gap_group", "gap_prob", ".diff_time_int",
  "diff_prev_s_adj", "diff_next_s_adj"
))
