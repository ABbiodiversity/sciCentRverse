#' Calculate density at each location from seasonal time and EDD (with optional pooled fallback)
#'
#' @description
#' Computes seasonal (or aggregated) density estimates per deployment × species using
#' time-in-front-of-camera (TIFC) totals and effective detection distance (EDD)
#' lookups. Supports exact EDD matches on species group, vegetation category,
#' season, and—when available—camera model and height. Optionally applies a
#' dist-group–specific pooled fallback when exact EDDs are missing. Note that filtering
#' locations with total days below a certain threshold (e.g., 30 days) should be done
#' prior to running the this function.
#'
#' @details
#' **Inputs and joins**
#' * `duration_df` must contain: `project`, `location`, `species_common_name`,
#'   `season`, `total_season_days` (days of operation in that season), and
#'   `total_duration` (seconds of TIFC in that season). If present, `model`
#'   and/or `height` are used directly.
#' * `edd_category_df` must provide `overall_category` for each (`project`, `location`)
#'   (or via `project_location` that gets split).
#' * Species are mapped to EDD groups via `dist_groups` (override with `dist_groups_df`).
#' * EDDs are taken from `edd` (override with `edd_df`). Exact joins use keys:
#'   `dist_group`, `overall_category`, `season`, and, when present in both
#'   data and lookup, `model` and/or `height`. If multiple EDD rows share the
#'   same keys, the entry with the largest `n` is chosen.
#'
#' **Density calculation**
#' * Area per season (m²): `area_m2 = π * (edd^2) * (cam_fov_angle / 360)`.
#' * Effort per season (m²·10⁻²): `effort = total_season_days * (area_m2 / 100)` (legacy factor).
#' * CPUE: `cpue = total_duration / effort`.
#' * Density (km⁻²): `density_km2 = (cpue / 86400) * 10000`.
#' * If `edd`, `effort`, or `total_season_days` are missing/zero, `density_km2` is `NA`.
#'
#' **Pooled EDD fallback (`use_global_edd = TRUE`)**
#' Uses weighted pooled EDDs (weights = `n`) following a conservative plan per `dist_group`:
#' * `Coyote`, `Deer`, `LargeUngulates`: pool over `overall_category`
#'   (keys: `dist_group`, `season`, `model`, `height`; absent keys are ignored).
#' * `Bear`, `Hare`, `Lynx`, `SmallMustelids`, `Wolf`: try pooled-overall first, then pool over height.
#' If pooling supplies an EDD and `annotate_edd_source = TRUE`, marks `edd_source = "pooled"`;
#' otherwise `edd_source = "exact"`. If pooling fails, density remains `NA`.
#'
#' **Aggregation (`aggregate = TRUE`)**
#' * Returns one row per deployment × species with `weighted.mean(density_km2, w = total_season_days, na.rm = TRUE)`.
#' * Removes Bear–winter rows before aggregation (including zeros).
#'
#' **Outputs**
#' * `format = "long"`: per-season rows with `overall_category`, `model`, `height`,
#'   `total_season_days`, `total_duration`, `density_km2`, and (optionally) `edd_source`.
#' * `format = "wide"`: densities pivoted to one row per deployment (diagnostic season-day columns included).
#' * `aggregate = TRUE`: one row per deployment × species (no seasons).
#'
#' @param duration_df Tibble with: project, location, species_common_name, season,
#'   total_season_days, total_duration (seconds). If present, `model` and/or `height`
#'   are used directly.
#' @param edd_category_df Tibble with vegetation/EDD category per camera; must contain
#'   `overall_category` plus (`project`,`location`) or `project_location`.
#' @param model_df Optional tibble (`project`,`location`,`model`) to attach if `duration_df`
#'   lacks a `model` column.
#' @param cam_fov_angle Camera FOV in degrees. Default 40.
#' @param format "long" (default) or "wide".
#' @param include_project Keep `project` in wide output. Default TRUE.
#' @param height_col Column name in `duration_df` to use as height (default "height").
#' @param dist_groups_df Optional override mapping (species_common_name -> dist_group).
#'   If NULL, an object named `dist_groups` must exist in your env/package.
#' @param edd_df Optional override EDD table. If NULL, an object named `edd` must exist.
#'   Must include: dist_group, season, overall_category, edd; ideally `n`, and optionally `model`, `height`.
#' @param aggregate Logical; if TRUE, return weighted mean per deployment by species
#'   (weights = `total_season_days`) after removing Bear–winter rows.
#' @param use_global_edd Logical; if TRUE, fill missing exact EDDs using a **dist-group–specific plan**.
#' @param annotate_edd_source Logical; add `edd_source` = "exact"/"pooled" (default TRUE).
#'
#' @return Seasonal densities (long/wide) or weighted aggregate (if `aggregate = TRUE`).
#' @seealso [cam_sum_total_time()], [cam_calc_time_by_series()], [cam_summarise_op_by_season()]
#' @author Marcus Becker
#' @export
cam_calc_density_by_loc <- function(
    duration_df,
    edd_category_df,
    model_df        = NULL,
    cam_fov_angle   = 40,
    format          = c("long","wide"),
    include_project = TRUE,
    height_col      = "height",
    dist_groups_df  = NULL,
    edd_df          = NULL,
    aggregate       = FALSE,
    use_global_edd  = FALSE,
    annotate_edd_source = TRUE
) {
  format <- match.arg(format)

  # ---- resolve lookups ----
  resolve_lookup <- function(name, override) {
    if (!is.null(override)) return(override)
    if (exists(name, inherits = TRUE)) return(get(name, inherits = TRUE))
    stop("Lookup `", name, "` not found. Define it or pass via the *_df argument.", call. = FALSE)
  }
  dist_groups_ <- resolve_lookup("dist_groups", dist_groups_df)
  edd_         <- resolve_lookup("edd",         edd_df)

  # ---- validate ----
  req <- c("project","location","species_common_name","season","total_season_days","total_duration")
  miss <- setdiff(req, names(duration_df))
  if (length(miss)) stop("`duration_df` missing: ", paste(miss, collapse = ", "), call. = FALSE)

  if (!all(c("project","location") %in% names(edd_category_df))) {
    if ("project_location" %in% names(edd_category_df)) {
      edd_category_df <- tidyr::separate(
        edd_category_df, "project_location",
        into = c("project","location"),
        sep = "_", remove = FALSE, extra = "merge"
      )
    } else {
      stop("`edd_category_df` needs `project` + `location` or `project_location`.", call. = FALSE)
    }
  }
  if (!"overall_category" %in% names(edd_category_df)) {
    stop("`edd_category_df` must contain `overall_category`.", call. = FALSE)
  }

  # ---- attach model if needed ----
  if (!"model" %in% names(duration_df) && !is.null(model_df)) {
    if (!all(c("project","location","model") %in% names(model_df))) {
      stop("`model_df` must contain `project`,`location`,`model`.", call. = FALSE)
    }
    duration_df <- dplyr::left_join(
      duration_df, dplyr::distinct(model_df, project, location, model),
      by = c("project","location")
    )
  }

  # ---- join species group + EDD category ----
  d <- duration_df |>
    dplyr::left_join(dist_groups_, by = "species_common_name") |>
    dplyr::left_join(
      edd_category_df |> dplyr::select(project, location, overall_category),
      by = c("project","location")
    )

  # exact EDD join keys
  join_keys <- c("dist_group","overall_category","season")
  if ("model" %in% names(d) && "model" %in% names(edd_)) join_keys <- c(join_keys, "model")
  use_height <- !is.null(height_col) && height_col %in% names(d) && "height" %in% names(edd_)
  if (use_height && !"height" %in% names(d)) d[["height"]] <- d[[height_col]]
  if (use_height && "height" %in% names(d)) join_keys <- c(join_keys, "height")

  # exact EDD (dedup by max n)
  edd_exact <- edd_ |>
    dplyr::group_by(dplyr::across(dplyr::all_of(join_keys))) |>
    dplyr::slice_max(dplyr::coalesce(n, -Inf), with_ties = FALSE) |>
    dplyr::ungroup() |>
    dplyr::select(dplyr::all_of(join_keys), edd, n)

  d_edd <- d |>
    dplyr::left_join(edd_exact, by = join_keys)

  # ensure diagnostics
  if (!"model" %in% names(d_edd))  d_edd$model  <- NA_character_
  if (!"height" %in% names(d_edd)) d_edd$height <- NA_character_
  if (annotate_edd_source && !"edd_source" %in% names(d_edd)) d_edd$edd_source <- NA_character_

  # ---- optional pooled fallback driven by dist_group ----
  if (use_global_edd) {
    pool_tbl <- function(tbl, keys) {
      keys <- intersect(keys, names(tbl))
      tbl |>
        dplyr::group_by(dplyr::across(dplyr::all_of(keys))) |>
        dplyr::summarise(
          edd_pool = if (all(is.na(edd))) NA_real_
          else stats::weighted.mean(edd, w = dplyr::coalesce(n, 0), na.rm = TRUE),
          .groups = "drop"
        )
    }
    pool_overall <- pool_tbl(edd_, c("dist_group","season","model","height"))
    pool_height  <- pool_tbl(edd_, c("dist_group","season","model"))

    jk_overall <- intersect(c("dist_group","season","model","height"), names(d_edd))
    jk_height  <- intersect(c("dist_group","season","model"),          names(d_edd))

    d_edd <- d_edd |>
      dplyr::left_join(dplyr::rename(pool_overall, edd_overall = edd_pool), by = jk_overall) |>
      dplyr::left_join(dplyr::rename(pool_height,  edd_height  = edd_pool), by = jk_height)

    plan_map <- list(
      "Coyote"         = c("overall"),
      "Deer"           = c("overall"),
      "LargeUngulates" = c("overall"),
      "Bear"           = c("overall","height"),
      "Hare"           = c("overall","height"),
      "Lynx"           = c("overall","height"),
      "SmallMustelids" = c("overall","height"),
      "Wolf"           = c("overall","height")
    )

    choose_pooled <- function(exact, over, ht, grp) {
      if (!is.na(exact)) return(exact)
      plan <- plan_map[[grp]]
      if (is.null(plan)) plan <- "overall"
      for (m in plan) {
        if (m == "overall" && !is.na(over)) return(over)
        if (m == "height"  && !is.na(ht))   return(ht)
      }
      NA_real_
    }

    edd_final <- mapply(
      choose_pooled,
      d_edd$edd, d_edd$edd_overall, d_edd$edd_height, d_edd$dist_group
    )

    if (annotate_edd_source) {
      d_edd$edd_source <- ifelse(!is.na(d_edd$edd), "exact",
                                 ifelse(!is.na(edd_final), "pooled", NA_character_))
    }
    d_edd$edd <- edd_final
    d_edd <- d_edd |>
      dplyr::select(-dplyr::any_of(c("edd_overall","edd_height")))
  }

  # ---- compute density (keep NAs) ----
  out_long0 <- d_edd |>
    dplyr::mutate(
      area_m2     = ifelse(is.na(edd), NA_real_,
                           pi * (edd^2) * (cam_fov_angle / 360)),
      effort      = ifelse(is.na(area_m2) | is.na(total_season_days) | total_season_days <= 0,
                           NA_real_,
                           total_season_days * (area_m2 / 100)),
      cpue        = ifelse(is.na(effort) | effort == 0, NA_real_, total_duration / effort),
      density_km2 = ifelse(is.na(cpue),   NA_real_, (cpue / 86400) * 10000)
    )

  keep_cols <- c("project","location","species_common_name","season",
                 "overall_category","model","height",
                 "total_season_days","total_duration","density_km2")
  if (annotate_edd_source && "edd_source" %in% names(out_long0)) keep_cols <- c(keep_cols, "edd_source")

  out_long0 <- out_long0 |>
    dplyr::select(dplyr::all_of(keep_cols), dplyr::everything(), -n, -edd) |>
    dplyr::relocate(dplyr::any_of(c("edd_source")), .after = "density_km2")

  if (aggregate) {
    out_agg <- out_long0 |>
      dplyr::filter(!(grepl("Bear", species_common_name) & season == "winter")) |>
      dplyr::group_by(project, location, species_common_name,
                      overall_category, model, height) |>
      dplyr::summarise(
        density_km2 = stats::weighted.mean(density_km2, w = total_season_days, na.rm = TRUE),
        .groups = "drop"
      ) |>
      dplyr::arrange(project, location, species_common_name)
    return(out_agg)
  }

  if (format == "long") {
    return(out_long0 |>
             dplyr::arrange(project, location, species_common_name, season))
  }

  # ---- wide output ----
  day_cols <- out_long0 |>
    dplyr::distinct(project, location, season, total_season_days) |>
    tidyr::pivot_wider(
      id_cols    = c(project, location),
      names_from = season,
      values_from= total_season_days,
      names_glue = "{season}_Days"
    )

  base_cols <- c("project","location","overall_category","model","height")
  val_cols  <- c("species_common_name","season")

  wide <- out_long0 |>
    dplyr::select(dplyr::all_of(c(base_cols, val_cols, "density_km2"))) |>
    tidyr::pivot_wider(
      id_cols    = dplyr::all_of(base_cols),
      names_from = dplyr::all_of(val_cols),
      values_from= density_km2
    ) |>
    dplyr::left_join(day_cols, by = c("project","location")) |>
    dplyr::relocate(dplyr::any_of(sort(names(day_cols)[-(1:2)])), .after = "location")

  if (!include_project) wide <- dplyr::select(wide, -project)
  wide
}
