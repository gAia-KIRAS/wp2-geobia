include <- function(str_list, regex_match) {
  matches <- paste(regex_match, collapse = "|") |>
    grep(str_list, value = TRUE) |>
    unique()
  return(matches)
}

exclude <- function(str_list, regex_match) {
  return(setdiff(str_list, include(str_list, regex_match)))
}
