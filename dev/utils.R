include <- function(str_list, regex_match) {
  matches <- paste(regex_match, collapse = "|") |>
    grep(str_list, value = TRUE) |>
    unique()
  return(matches)
}

exclude <- function(str_list, regex_match) {
  return(setdiff(str_list, include(str_list, regex_match)))
}

sfc_as_cols <- function(x, geometry, names = c("x", "y")) {
  if (missing(geometry)) {
    geometry <- sf::st_geometry(x)
  } else {
    geometry <- rlang::eval_tidy(enquo(geometry), x)
  }
  stopifnot(inherits(x, "sf") && inherits(geometry, "sfc_POINT"))
  ret <- sf::st_coordinates(geometry)
  ret <- tibble::as_tibble(ret)
  stopifnot(length(names) == ncol(ret))
  x <- x[, !names(x) %in% names]
  ret <- setNames(ret, names)
  dplyr::bind_cols(x, ret)
}
