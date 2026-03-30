#' Single-Shot ML Regression
#'
#' Executes the entire 5-step ML regression workflow in one call without
#' interactive menus. Prints a summary at each step.
#'
#' @param file_path Character. Path to the \code{.xlsx} data file.
#' @param outcome Character. Name of the outcome (Y) column.
#' @param predictors Character vector. Names of the predictor (X) columns.
#' @param categorical Character vector or \code{NULL}. Names of categorical
#'   predictor columns.
#' @param factor_levels Named list or \code{NULL}. Each element is a character
#'   vector of level names for the corresponding categorical variable. The first
#'   level in each vector becomes the reference level.
#' @param split_ratio Numeric between 0 and 1. Proportion of data used for
#'   training (default 0.8).
#' @param student_name Character or \code{NULL}. OSU name.# (e.g.,
#'   \code{"castillo.230"}). Used to generate a unique random seed for the
#'   train/test split. If \code{NULL}, uses the default seed.
#' @param seed Numeric or \code{NULL}. If provided, overrides the seed
#'   derived from \code{student_name}. Use this to reproduce results with
#'   a specific seed (e.g., \code{seed = 4321}).
#'
#' @return An object of class \code{ml_result} (returned invisibly).
#'
#' @details
#' \strong{Warning:} This function executes all 5 steps without pausing for
#' inspection. Use \code{\link{ml_workflow}} for the guided, step-by-step
#' experience.
#'
#' @examples
#' \dontrun{
#' result <- ml_run(
#'   file_path  = "bikes.xlsx",
#'   outcome    = "rentals",
#'   predictors = c("temperature", "humidity", "windspeed"),
#'   split_ratio = 0.8
#' )
#' print(result)
#' }
#'
#' @export
ml_run <- function(file_path, outcome, predictors,
                   categorical = NULL, factor_levels = NULL,
                   split_ratio = 0.8, student_name = NULL,
                   seed = NULL) {

  # --- Input validation ---
  if (!is.character(file_path) || length(file_path) != 1)
    stop("file_path must be a single character string.", call. = FALSE)
  if (!is.character(outcome) || length(outcome) != 1)
    stop("outcome must be a single character string.", call. = FALSE)
  if (!is.character(predictors) || length(predictors) < 1)
    stop("predictors must be a character vector with at least one name.", call. = FALSE)
  if (!is.numeric(split_ratio) || split_ratio <= 0 || split_ratio >= 1)
    stop("split_ratio must be a number between 0 and 1.", call. = FALSE)

  # --- Warning ---
  cat("\n")
  cat("WARNING: ml_run() executes the entire 5-step ML process in one call.\n")
  cat("You will not be able to inspect each step individually. Only use this\n")
  cat("if you are confident in your variable selections and understand the\n")
  cat("process. For the guided, step-by-step experience, use ml_workflow()\n")
  cat("instead.\n\n")

  # Set seed: explicit seed > student_name > default
  if (!is.null(seed)) {
    .ml_env$student_seed <- as.integer(seed)
  } else if (!is.null(student_name)) {
    student_name <- tolower(trimws(student_name))
    .ml_env$student_name <- student_name
    .ml_env$student_seed <- sum(utf8ToInt(student_name))
  }

  confirm <- .ask("Type 'yes' to proceed: ")
  if (tolower(trimws(confirm)) != "yes") {
    cat("Aborted.\n")
    return(invisible(NULL))
  }

  # --- Step 1 ---
  cat("\n-- Step 1: Collect Data --\n")
  collect <- step1_collect(file_path, interactive = FALSE,
                           outcome = outcome, predictors = predictors,
                           categorical = categorical, factor_levels = factor_levels)
  cat("Data loaded: ", nrow(collect$data), " observations, ",
      ncol(collect$data), " columns.\n", sep = "")

  # --- Step 2 ---
  cat("\n-- Step 2: Prepare Data --\n")
  prepare <- step2_prepare(collect, interactive = FALSE, split_ratio = split_ratio)
  cat("Train: ", nrow(prepare$train_set), " rows | Test: ",
      nrow(prepare$test_set), " rows\n", sep = "")

  # --- Step 3 ---
  cat("\n-- Step 3: Train Model --\n")
  train <- step3_train(prepare, interactive = FALSE)
  cat("R-squared: ", round(train$r_squared, 4),
      " | RSE: ", round(train$rse, 4), "\n", sep = "")

  # --- Step 4 ---
  cat("\n-- Step 4: Evaluate Model --\n")
  evaluate <- step4_evaluate(train, interactive = FALSE)
  if (!is.null(evaluate$vif_df)) {
    if ("VIF" %in% names(evaluate$vif_df)) {
      cat("Max VIF: ", max(evaluate$vif_df$VIF), "\n", sep = "")
    } else {
      cat("Max GVIF adjusted: ", max(evaluate$vif_df$GVIF_adjusted), "\n", sep = "")
    }
  } else {
    cat("VIF: Not applicable (single predictor).\n")
  }

  # --- Step 5 ---
  cat("\n-- Step 5: Test Model --\n")
  result <- step5_test(evaluate, interactive = FALSE)
  cat("MAD: ", round(result$mad, 4), " | MSE: ", round(result$mse, 4), "\n", sep = "")

  cat("\nDone! Use print(result) for a summary, plot(result) for visuals,\n")
  cat("or export_xlsx(result, 'file.xlsx') to export to Excel.\n")

  invisible(result)
}
