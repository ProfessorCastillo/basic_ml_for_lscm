#' Single-Shot ML Classification
#'
#' Executes the entire 5-step ML classification workflow in one call without
#' interactive menus. Uses logistic regression for binary classification.
#'
#' @param file_path Character. Path to the \code{.xlsx} data file.
#' @param outcome Character. Name of the outcome (Y) column. Must have
#'   exactly 2 unique values.
#' @param positive_class Character. The level of the outcome variable that
#'   represents the event you want to predict (e.g., \code{"Yes"},
#'   \code{"Churn"}, \code{1}).
#' @param predictors Character vector. Names of the predictor (X) columns.
#' @param categorical Character vector or \code{NULL}. Names of categorical
#'   predictor columns.
#' @param factor_levels Named list or \code{NULL}. Each element is a character
#'   vector of level names for the corresponding categorical variable.
#' @param split_ratio Numeric between 0 and 1. Proportion of data used for
#'   training (default 0.8).
#' @param threshold Numeric between 0 and 1. Probability cutoff for
#'   classification (default 0.5).
#' @param student_name Character or \code{NULL}. OSU name.# for seed generation.
#' @param seed Numeric or \code{NULL}. If provided, overrides the seed
#'   derived from \code{student_name}.
#'
#' @return An object of class \code{ml_result_class} (returned invisibly).
#'
#' @examples
#' \dontrun{
#' result <- ml_run_class(
#'   file_path      = "customers.xlsx",
#'   outcome        = "Churn",
#'   positive_class = "Yes",
#'   predictors     = c("tenure", "monthly_charges", "contract_type"),
#'   categorical    = "contract_type",
#'   factor_levels  = list(contract_type = c("Month-to-month", "One year", "Two year"))
#' )
#' print(result)
#' }
#'
#' @export
ml_run_class <- function(file_path, outcome, positive_class, predictors,
                         categorical = NULL, factor_levels = NULL,
                         split_ratio = 0.8, threshold = 0.5,
                         student_name = NULL, seed = NULL) {

  # --- Input validation ---
  if (!is.character(file_path) || length(file_path) != 1)
    stop("file_path must be a single character string.", call. = FALSE)
  if (!is.character(outcome) || length(outcome) != 1)
    stop("outcome must be a single character string.", call. = FALSE)
  if (!is.character(positive_class) || length(positive_class) != 1)
    stop("positive_class must be a single character string.", call. = FALSE)
  if (!is.character(predictors) || length(predictors) < 1)
    stop("predictors must be a character vector with at least one name.", call. = FALSE)
  if (!is.numeric(split_ratio) || split_ratio <= 0 || split_ratio >= 1)
    stop("split_ratio must be a number between 0 and 1.", call. = FALSE)
  if (!is.numeric(threshold) || threshold <= 0 || threshold >= 1)
    stop("threshold must be a number between 0 and 1.", call. = FALSE)

  # --- Warning ---
  cat("\n")
  cat("WARNING: ml_run_class() executes the entire 5-step ML classification\n")
  cat("process in one call. You will not be able to inspect each step\n")
  cat("individually. For the guided experience, use ml_workflow_class().\n\n")

  # Set seed
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

  # Validate binary outcome
  outcome_vals <- unique(collect$data[[outcome]])
  outcome_vals <- outcome_vals[!is.na(outcome_vals)]
  if (length(outcome_vals) != 2)
    stop("Outcome '", outcome, "' has ", length(outcome_vals),
         " unique values. Binary classification requires exactly 2.", call. = FALSE)
  if (!positive_class %in% as.character(outcome_vals))
    stop("positive_class '", positive_class, "' not found in outcome values: ",
         paste(outcome_vals, collapse = ", "), call. = FALSE)

  # Convert outcome to factor
  negative_class <- setdiff(as.character(outcome_vals), positive_class)
  collect$data[[outcome]] <- factor(collect$data[[outcome]],
                                    levels = c(negative_class, positive_class))
  collect$positive_class <- positive_class

  cat("Data loaded: ", nrow(collect$data), " observations, ",
      ncol(collect$data), " columns.\n", sep = "")
  cat("Positive class: '", positive_class, "'\n", sep = "")

  # --- Step 2 ---
  cat("\n-- Step 2: Prepare Data --\n")
  prepare <- step2_prepare(collect, interactive = FALSE, split_ratio = split_ratio)
  prepare$positive_class <- positive_class
  cat("Train: ", nrow(prepare$train_set), " rows | Test: ",
      nrow(prepare$test_set), " rows\n", sep = "")

  # --- Step 3 ---
  cat("\n-- Step 3: Train Model (Logistic Regression) --\n")
  train <- step3_train_class(prepare, interactive = FALSE)
  cat("AIC: ", round(train$model$aic, 2), "\n", sep = "")

  # --- Step 4 ---
  cat("\n-- Step 4: Evaluate Model --\n")
  evaluate <- step4_evaluate_class(train, interactive = FALSE)
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
  result <- step5_test_class(evaluate, interactive = FALSE)
  cat("Accuracy: ", round(result$accuracy * 100, 2), "% (threshold = ",
      threshold, ")\n", sep = "")
  cat("\nConfusion Matrix:\n")
  print(result$confusion_matrix)

  cat("\nDone! Use print(result) for a summary, plot(result) for visuals,\n")
  cat("or export_xlsx(result, 'file.xlsx') to export to Excel.\n")

  invisible(result)
}
