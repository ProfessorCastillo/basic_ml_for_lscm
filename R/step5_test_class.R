#' Step 5 (Classification): Test the Model
#'
#' Runs predictions on the test set, applies a probability threshold,
#' produces a confusion matrix, and computes accuracy.
#'
#' @param evaluate_result List returned by step4_evaluate_class().
#' @param interactive Logical. If TRUE, shows output and prompts.
#'
#' @return An object of class \code{ml_result_class}.
#'
#' @importFrom stats predict
#' @noRd
step5_test_class <- function(evaluate_result, interactive = TRUE) {

  outcome         <- evaluate_result$outcome
  positive_class  <- evaluate_result$positive_class
  predictors      <- evaluate_result$predictors
  categorical     <- evaluate_result$categorical
  factor_levels   <- evaluate_result$factor_levels
  train_set       <- evaluate_result$train_set
  test_set        <- evaluate_result$test_set
  split_ratio     <- evaluate_result$split_ratio
  model           <- evaluate_result$model
  model_summary   <- evaluate_result$model_summary
  coefficients_df <- evaluate_result$coefficients_df
  vif_df          <- evaluate_result$vif_df
  data            <- evaluate_result$data

  # --- Determine class levels ---
  outcome_levels <- levels(train_set[[outcome]])
  negative_class <- setdiff(outcome_levels, positive_class)

  # --- Threshold selection ---
  threshold <- 0.5
  if (interactive) {
    .print_header("Step 5: Test the Model (Classification)")

    .lcat("The model predicts probabilities for each observation. A threshold\n")
    .lcat("determines the cutoff: observations with predicted probability above\n")
    .lcat("the threshold are classified as '", positive_class, "'.\n\n", sep = "")
    .lcat("The default threshold is 0.5 (recommended for most cases).\n")

    if (!.ask_yn("Use the default threshold of 0.5?")) {
      repeat {
        thr_input <- .ask("Enter your threshold (between 0 and 1): ")
        thr <- suppressWarnings(as.numeric(thr_input))
        if (!is.na(thr) && thr > 0 && thr < 1) {
          threshold <- thr
          break
        }
        .lcat("Please enter a number between 0 and 1.\n")
      }
    }
    .lcat("\nUsing threshold: ", threshold, "\n\n", sep = "")
  }

  # --- Predict probabilities ---
  probs <- stats::predict(model, newdata = test_set, type = "response")

  # --- Apply threshold ---
  predicted_class <- ifelse(probs >= threshold, positive_class, negative_class)
  predicted_class <- factor(predicted_class, levels = outcome_levels)
  actual_class <- test_set[[outcome]]

  # --- Confusion matrix ---
  conf_matrix <- table(Predicted = predicted_class, Actual = actual_class)

  # --- Accuracy ---
  accuracy <- sum(diag(conf_matrix)) / sum(conf_matrix)

  # --- Predictions data frame ---
  predictions <- data.frame(
    Actual          = actual_class,
    Probability     = round(as.numeric(probs), 4),
    Predicted_Class = predicted_class,
    Correct         = as.integer(actual_class == predicted_class),
    stringsAsFactors = FALSE
  )

  if (interactive) {
    .print_subheader("Confusion Matrix")
    .lprint(conf_matrix)

    # Extract counts for plain-English interpretation
    tp <- if (positive_class %in% rownames(conf_matrix) &&
              positive_class %in% colnames(conf_matrix))
            conf_matrix[positive_class, positive_class] else 0
    tn <- if (negative_class %in% rownames(conf_matrix) &&
              negative_class %in% colnames(conf_matrix))
            conf_matrix[negative_class, negative_class] else 0
    fp <- if (positive_class %in% rownames(conf_matrix) &&
              negative_class %in% colnames(conf_matrix))
            conf_matrix[positive_class, negative_class] else 0
    fn <- if (negative_class %in% rownames(conf_matrix) &&
              positive_class %in% colnames(conf_matrix))
            conf_matrix[negative_class, positive_class] else 0

    .lcat("\nHow to read the confusion matrix:\n")
    .lcat("  True Positives  (", tp, "): Correctly predicted '",
        positive_class, "'\n", sep = "")
    .lcat("  True Negatives  (", tn, "): Correctly predicted '",
        negative_class, "'\n", sep = "")
    .lcat("  False Positives (", fp, "): Predicted '",
        positive_class, "' but was actually '",
        negative_class, "'\n", sep = "")
    .lcat("  False Negatives (", fn, "): Predicted '",
        negative_class, "' but was actually '",
        positive_class, "'\n", sep = "")

    .print_subheader("Accuracy")
    .lcat("Accuracy = ", round(accuracy * 100, 2), "%\n\n", sep = "")
    .lcat("This means the model correctly classified ", round(accuracy * 100, 2),
        "% of observations\n", sep = "")
    .lcat("in the test set. The remaining ",
        round((1 - accuracy) * 100, 2),
        "% were misclassified.\n\n", sep = "")

    baseline <- max(table(actual_class)) / length(actual_class)
    .lcat("For context, a naive model that always predicts the most common class\n")
    .lcat("would achieve ", round(baseline * 100, 2),
        "% accuracy. Your model should beat this baseline\n",
        "to be considered useful.\n", sep = "")

    .lcat("\nNote: Scatter-style 'Actual vs Predicted' plots do not apply to\n")
    .lcat("classification tasks because the outcome is categorical, not\n")
    .lcat("continuous. The confusion matrix above is the standard way to\n")
    .lcat("evaluate classification performance.\n")

    # --- Go back option ---
    if (.ask_yn("\nWould you like to go back to Step 4 (Evaluate)?")) {
      .lcat("\nGoing back to Step 4...\n")
      return(list(go_back = TRUE))
    }
  }

  # --- Build and return result ---
  new_ml_result_class(
    data = data, outcome = outcome, positive_class = positive_class,
    predictors = predictors, categorical = categorical,
    factor_levels = factor_levels,
    train_set = train_set, test_set = test_set, split_ratio = split_ratio,
    model = model, model_summary = model_summary, vif = vif_df,
    predictions = predictions, confusion_matrix = conf_matrix,
    accuracy = accuracy, threshold = threshold,
    coefficients = coefficients_df,
    student_name = .ml_env$student_name,
    student_seed = .ml_env$student_seed,
    project_name = .ml_env$project_name
  )
}
