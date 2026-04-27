# Internal camera-function utilities
# These helpers are not exported; they are shared across cam_*() functions.

#' Assign season labels to a vector of Julian days
#'
#' @param yday_vec Integer or numeric vector of Julian days (1–366).
#' @param cuts Sorted integer vector of season-start Julian days (one per season).
#' @param labs Character vector of season labels, same length and order as \code{cuts}.
#'
#' @return An ordered factor of season labels with \code{levels = labs}.
#'
#' @details
#' Classification is **left-closed**: a day equal to a cutoff is assigned to
#' that season (e.g., Julian day 143 is the *first* day of summer when
#' \code{cuts = c(99, 143, 288)}). Days that fall before the first cutoff wrap
#' to the **last** season, allowing year-crossing seasons (e.g., winter spanning
#' late-year to early-year).
#'
#' @examples
#' cuts <- c(99L, 143L, 288L)
#' labs <- c("spring", "summer", "winter")
#' sciCentRverse:::.assign_season(c(98, 99, 142, 143, 287, 288, 365), cuts, labs)
#'
#' @keywords internal
.assign_season <- function(yday_vec, cuts, labs) {
  idx <- findInterval(yday_vec, cuts, left.open = FALSE)
  idx[idx == 0L] <- length(cuts)
  factor(labs[idx], levels = labs, ordered = TRUE)
}
