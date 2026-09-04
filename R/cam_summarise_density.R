#' Summarise density across locations within an area of interest, with uncertainty
#'
#' @description
#' Takes location-level density estimates (e.g., the output of
#' [cam_calc_density_by_loc()]) and calculates a mean density per species within
#' a user-defined unit of interest (e.g., a grid, cluster, or region). Because
#' density at unsampled/unoccupied locations is exactly zero, the mean is
#' calculated as a two-part ("hurdle") estimator: the proportion of locations
#' occupied, multiplied by the average density at occupied locations. Confidence
#' intervals are obtained by simulating from the sampling distributions of both
#' components and combining them.
#'
#' @details
#' **Two-part mean.** For a given group (area of interest x species):
#' * `prop_occupied` = proportion of locations with `dens_col > 0`.
#' * `agp` ("abundance given presence") = mean of `dens_col` among occupied locations.
#' * `density_avg` = `prop_occupied * agp`.
#'
#' **Uncertainty.** `prop_occupied` is treated as a binomial proportion
#' (`n_deployments` trials), and `agp` is treated as log-normal, with the standard
#' deviation of `log(dens_col)` among occupied locations scaled by
#' `1/sqrt(occupied)` to approximate the standard error of the mean. `n_sim` draws
#' are taken from each distribution and multiplied together to build a simulated
#' distribution of `density_avg`, which is then rescaled to have mean equal to the
#' point estimate before taking quantiles at `conf_level` to form the confidence
#' interval. This is a simulation-based (parametric bootstrap) approach to
#' combining the uncertainty of the two components — related to, but not
#' identical to, an analytical delta-method variance formula.
#'
#' When a group has zero occupied locations, `density_avg`, the lower CI, and the
#' upper CI are all set to 0. When a group has exactly **one** occupied location,
#' there is no information available on the variance of `agp`; the simulation
#' still incorporates uncertainty in `prop_occupied`, but `agp` is held fixed at
#' its point estimate.
#'
#' **Grouping.** `density_df` is always grouped by `group_col` and `species_col`.
#' If `samp_per_col` is supplied (or a default `samp_per` column exists) and
#' `agg_samp_per = FALSE`, the output retains one row per sampling period;
#' otherwise sampling periods are pooled together before summarising.
#'
#' **Missing density values.** Rows where `dens_col` is `NA` provide no
#' information on occupancy status and are dropped prior to summarising (see
#' `remove_na`); by default a message reports how many rows were dropped.
#'
#' @param density_df Tibble/data.frame of location-level density estimates, e.g.
#'   the output of [cam_calc_density_by_loc()]. If an `sf` object, geometry is dropped.
#' @param group_col Column name(s) identifying the unit/area of interest to
#'   summarise within (e.g., `"grid"`). Character vector of one or more columns.
#' @param species_col Column name identifying species. Default `"species_common_name"`.
#' @param dens_col Column name of location-level density values. Default `"density_km2"`.
#' @param agg_samp_per Logical; if `TRUE` (default), sampling periods are pooled
#'   before summarising. If `FALSE`, output retains one row per sampling period
#'   (see `samp_per_col`).
#' @param samp_per_col Optional column name identifying the sampling period. If
#'   `NULL` (default) and `agg_samp_per = FALSE`, a default column named
#'   `"samp_per"` is used if present.
#' @param conf_level Confidence level for the simulated interval. Default `0.9`.
#' @param n_sim Number of simulation draws used to build the confidence interval.
#'   Default `10000`.
#' @param remove_na Logical; drop rows with `NA` in `dens_col` before summarising?
#'   Default `TRUE`.
#' @param seed Optional integer seed for reproducible simulation. The global RNG
#'   state is saved and restored, so calling this function does not affect
#'   random draws elsewhere in the user's session. Default `NULL` (no seed set).
#'
#' @return A tibble grouped by `group_col` (and `samp_per_col` if applicable) and
#'   `species_col`, with columns `n_deployments`, `occupied`, `prop_occupied`,
#'   `density_avg`, and the lower/upper confidence bounds named
#'   `density_lci_<conf_level>` / `density_uci_<conf_level>`.
#'
#' @examples
#' \dontrun{
#' # density is the output of cam_calc_density_by_loc(), split into a grouping
#' # column (e.g., grid) and location
#' density |>
#'   tidyr::separate(location, into = c("grid", "station"), sep = "-") |>
#'   cam_summarise_density(
#'     group_col    = "grid",
#'     species_col  = "species_common_name",
#'     dens_col     = "density_km2",
#'     agg_samp_per = TRUE,
#'     conf_level   = 0.9
#'   )
#' }
#'
#' @seealso [cam_calc_density_by_loc()]
#' @author Marcus Becker
#' @export
cam_summarise_density <- function(
    density_df,
    group_col,
    species_col  = "species_common_name",
    dens_col     = "density_km2",
    agg_samp_per = TRUE,
    samp_per_col = NULL,
    conf_level   = 0.9,
    n_sim        = 10000,
    remove_na    = TRUE,
    seed         = NULL
) {

  if (missing(group_col)) {
    stop("`group_col` must be supplied: the column(s) identifying the unit/area of interest.", call. = FALSE)
  }

  # Drop geometry if present
  if ("geometry" %in% names(density_df) && inherits(density_df, "sf")) {
    density_df <- sf::st_set_geometry(density_df, NULL)
  }

  req  <- c(group_col, species_col, dens_col)
  miss <- setdiff(req, names(density_df))
  if (length(miss)) stop("`density_df` missing: ", paste(miss, collapse = ", "), call. = FALSE)
  if (!is.numeric(density_df[[dens_col]])) stop("`dens_col` must refer to a numeric column.", call. = FALSE)

  # Resolve sampling-period grouping
  if (!agg_samp_per) {
    if (is.null(samp_per_col)) {
      if (!"samp_per" %in% names(density_df)) {
        stop("Cannot group by sampling period: `samp_per_col` was not supplied and no ",
             "default `samp_per` column exists. Set `agg_samp_per = TRUE`, or supply ",
             "`samp_per_col`.", call. = FALSE)
      }
      samp_per_col <- "samp_per"
    } else if (!samp_per_col %in% names(density_df)) {
      stop("`samp_per_col` must refer to a column in `density_df`.", call. = FALSE)
    }
  } else {
    samp_per_col <- NULL
  }

  # Drop rows with missing density values; they carry no occupancy information
  if (remove_na) {
    n_na <- sum(is.na(density_df[[dens_col]]))
    if (n_na > 0) {
      message(n_na, " row(s) with NA `", dens_col, "` removed prior to summarising.")
      density_df <- density_df[!is.na(density_df[[dens_col]]), ]
    }
  }

  group_cols <- c(group_col, samp_per_col, species_col)

  occupied <- n_deployments <- prop_occupied <- agp <- logagp_sd <- density_avg <- NULL

  summary_df <- density_df |>
    dplyr::group_by(dplyr::across(dplyr::all_of(group_cols))) |>
    dplyr::summarise(
      n_deployments = dplyr::n(),
      occupied      = sum(.data[[dens_col]] > 0, na.rm = TRUE),
      prop_occupied = occupied / n_deployments,
      agp           = suppressWarnings(mean(.data[[dens_col]][.data[[dens_col]] > 0])),
      agp           = dplyr::if_else(is.nan(agp), 0, agp),
      logagp_sd     = suppressWarnings(stats::sd(log(.data[[dens_col]][.data[[dens_col]] > 0]))),
      density_avg   = prop_occupied * agp,
      .groups = "drop"
    )

  # Seed handling: save/restore the caller's RNG state so this function does not
  # have side effects on random draws elsewhere in the session
  if (!is.null(seed)) {
    if (!exists(".Random.seed", envir = .GlobalEnv)) stats::runif(1)
    old_seed <- get(".Random.seed", envir = .GlobalEnv)
    on.exit(assign(".Random.seed", old_seed, envir = .GlobalEnv), add = TRUE)
    set.seed(seed)
  }

  ci <- purrr::pmap(
    list(
      prop_occupied = summary_df$prop_occupied,
      n_deployments = summary_df$n_deployments,
      occupied      = summary_df$occupied,
      agp           = summary_df$agp,
      logagp_sd     = summary_df$logagp_sd,
      density_avg   = summary_df$density_avg
    ),
    .simulate_density_ci,
    conf_level = conf_level,
    n_sim      = n_sim
  ) |>
    dplyr::bind_rows()

  summary_df |>
    dplyr::bind_cols(ci) |>
    dplyr::rename_with(~ paste0("density_", ., "_", conf_level), .cols = c("lci", "uci")) |>
    dplyr::select(-c(agp, logagp_sd))
}

#' Simulate a confidence interval for a two-part (occupancy x abundance-given-presence) density estimate
#'
#' @param prop_occupied Proportion of deployments with density > 0.
#' @param n_deployments Total number of deployments (binomial trials).
#' @param occupied Number of deployments with density > 0.
#' @param agp Mean density among occupied deployments ("abundance given presence").
#' @param logagp_sd Standard deviation of `log(density)` among occupied deployments.
#' @param density_avg Point estimate of mean density (`prop_occupied * agp`), used
#'   to recentre the simulated distribution.
#' @param conf_level Confidence level.
#' @param n_sim Number of simulation draws.
#'
#' @return A named numeric vector with elements `lci` and `uci`.
#'
#' @keywords internal
.simulate_density_ci <- function(prop_occupied, n_deployments, occupied, agp,
                                  logagp_sd, density_avg, conf_level, n_sim) {

  if (is.na(occupied) || occupied == 0 || n_deployments == 0) {
    return(c(lci = 0, uci = 0))
  }

  pa_sim <- stats::rbinom(n_sim, size = n_deployments, prob = prop_occupied) / n_deployments

  if (occupied >= 2 && !is.na(logagp_sd)) {
    agp_sim <- exp(stats::rnorm(n_sim, mean = log(agp), sd = logagp_sd / sqrt(occupied)))
  } else {
    # A single occupied deployment carries no information on the variance of agp;
    # hold it fixed and let uncertainty come from prop_occupied only
    agp_sim <- rep(agp, n_sim)
  }

  full_sim <- pa_sim * agp_sim

  # Recentre so the simulated distribution's mean matches the point estimate
  sim_mean <- mean(full_sim)
  if (sim_mean > 0) {
    full_sim <- full_sim * density_avg / sim_mean
  }

  probs <- c((1 - conf_level) / 2, conf_level + (1 - conf_level) / 2)
  q <- stats::quantile(full_sim, probs = probs, na.rm = TRUE)
  c(lci = unname(q[1]), uci = unname(q[2]))
}
