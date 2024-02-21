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

wall <- function(x) print(glue(x))

learn <- function(susc_data, learner = c("randomforest", "earth", "gam"), id = "carinthia", resampling_strategy = rsmp("spcv_coords", folds = 5)) {
  # Setup classification task
  task <- as_task_classif_st(susc_data, target = "slide", id = id, positive = "TRUE", coordinate_names = c("x", "y"), crs = "epsg:3416")

  # Check learner argument
  learner <- match.arg(learner)

  # Define learner and search space
  if (learner == "randomforest") {
    learner <- lrn("classif.ranger",
      num.trees = 1000,
      mtry = to_tune(1, length(task$feature_names)),
      min.node.size = to_tune(p_int(1, 10)),
      sample.fraction = to_tune(0.2, 0.9),
      respect.unordered.factors = "order",
      importance = "permutation",
      predict_type = "prob",
      verbose = FALSE,
      num.threads = 32L
    )
  } else if (learner == "earth") {
    learner <- lrn("classif.earth",
      nk = to_tune(p_int(2, 100)),
      degree = to_tune(p_int(1, 3)),
      nprune = to_tune(p_int(5, 100)),
      pmethod = "backward",
      predict_type = "prob"
    )
  } else if (learner == "gam") {
    fm <- paste("s(", names(susc_data[-1]), ")", sep = "", collapse = " + ")
    learner <- lrn("classif.gam",
      formula = as.formula(paste("slide ~", fm)),
      select = TRUE,
      predict_type = "prob"
    )
  }

  # Setup tuning w/ mbo
  instance <- tune(
    tuner = tnr("mbo"),
    # https://mlr3mbo.mlr-org.com/reference/mbo_defaults.html
    task = task,
    learner = learner,
    resampling = resampling_strategy,
    measure = msr("classif.bbrier"),
    terminator = trm("evals", n_evals = 500)
  )

  # Set optimal hyperparameter configuration to learner
  learner$param_set$values <- instance$result_learner_param_vals

  # Train the learner on the full data set
  learner$train(task)

  return(learner)
}

nested_resampling <- function(susc_data, learner = c("randomforest", "earth"), id = "carinthia", outer_resampling = rsmp("spcv_coords", folds = 5), inner_resampling = rsmp("spcv_coords", folds = 4)) {
  # Setup classification task
  task <- as_task_classif_st(susc_data, target = "slide", id = id, positive = "TRUE", coordinate_names = c("x", "y"), crs = "epsg:3416")

  # Check learner argument
  learner <- match.arg(learner)

  # Define learner and search space
  if (learner == "randomforest") {
    learner <- lrn("classif.ranger",
      num.trees = 1000,
      mtry = to_tune(1, length(task$feature_names)),
      min.node.size = to_tune(p_int(1, 10)),
      sample.fraction = to_tune(0.2, 0.9),
      respect.unordered.factors = "order",
      importance = "permutation",
      predict_type = "prob",
      verbose = FALSE,
      num.threads = 32L
    )
  } else if (learner == "earth") {
    learner <- lrn("classif.earth",
      nk = to_tune(p_int(2, 100)),
      degree = to_tune(p_int(1, 3)),
      nprune = to_tune(p_int(5, 100)),
      pmethod = "backward",
      predict_type = "prob"
    )
  }

  # Setup tuning w/ mbo
  at <- auto_tuner(
    tuner = tnr("mbo"),
    # https://mlr3mbo.mlr-org.com/reference/mbo_defaults.html
    learner = learner,
    resampling = inner_resampling,
    measure = msr("classif.bbrier"),
    terminator = trm("evals", n_evals = 100)
  )

  rr <- resample(task, at, outer_resampling, store_models = TRUE)

  return(rr)
}

get_score <- function(x) {
  x$score() |>
    select(iteration:classif.ce)
}

get_inner_tuning <- function(x) {
  x |>
    extract_inner_tuning_results() |>
    select(iteration:classif.bbrier)
}

get_importance <- function(ranger_model) {
  ranger_model$importance() |>
    tibble::enframe() |>
    rename(index = name, importance = value) |>
    arrange(-importance) |>
    mutate(index = forcats::fct_reorder(index, -desc(importance)))
}

get_evimp <- function(earth_model) {
  tmp <- evimp(earth_model$model)
  tmp <- tmp[, c("nsubsets", "gcv", "rss")] |>
    as_tibble(rownames = "index") |>
    mutate(index = forcats::fct_reorder(index, -desc(gcv)))
  return(tmp)
}

okabe_ito <- c(
  "#E69F00", "#56B4E9", "#009E73", "#F0E442",
  "#0072B2", "#D55E00", "#CC79A7", "#000000"
)
names(okabe_ito) <- c(
  "orange",
  "skyblue",
  "green",
  "yellow",
  "darkblue",
  "darkorange",
  "pink",
  "black"
)

# handle duplicates
identify_dups <- function(inv, cn) {
  inv |>
    drop_na({{ cn }}) |>
    filter(duplicated({{ cn }})) |>
    pull({{ cn }})
}

list_dups <- function(inv, cn) {
  dups <- identify_dups(inv, {{ cn }})
  inv |>
    filter({{ cn }} %in% dups)
}
