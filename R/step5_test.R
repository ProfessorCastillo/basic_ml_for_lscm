#' Step 5: Test the Model
#'
#' Runs predictions on the test set, computes MAD and MSE,
#' produces an actual-vs-predicted plot, and optionally exports to Excel.
#'
#' @param evaluate_result List returned by step4_evaluate().
#' @param interactive Logical. If TRUE, shows output and prompts.
#'
#' @return An object of class \code{ml_result}.
#'
#' @importFrom stats predict
#' @importFrom ggplot2 ggplot aes geom_point geom_abline labs
#' @importFrom rlang .data
#' @noRd
step5_test <- function(evaluate_result, interactive = TRUE) {

  outcome         <- evaluate_result$outcome
  predictors      <- evaluate_result$predictors
  categorical     <- evaluate_result$categorical
  factor_levels   <- evaluate_result$factor_levels
  train_set       <- evaluate_result$train_set
  test_set        <- evaluate_result$test_set
  split_ratio     <- evaluate_result$split_ratio
  model           <- evaluate_result$model
  model_summary   <- evaluate_result$model_summary
  coefficients_df <- evaluate_result$coefficients_df
  r_squared       <- evaluate_result$r_squared
  rse             <- evaluate_result$rse
  vif_df          <- evaluate_result$vif_df
  data            <- evaluate_result$data

  # --- Predict ---
  predicted <- stats::predict(model, newdata = test_set)
  predictions <- data.frame(
    Actual         = test_set[[outcome]],
    Predicted      = as.numeric(predicted),
    Error          = test_set[[outcome]] - as.numeric(predicted),
    Absolute_Error = abs(test_set[[outcome]] - as.numeric(predicted))
  )

  # --- Accuracy metrics ---
  mad_val <- mean(predictions$Absolute_Error)
  mse_val <- mean(predictions$Error^2)

  if (interactive) {
    .print_header("Step 5: Test the Model")

    .lcat("MAD = ", round(mad_val, 4),
        ": On average, predictions are off by ", round(mad_val, 2),
        " units of ", outcome, ".\n\n", sep = "")

    .lcat("MSE = ", round(mse_val, 4),
        ": Larger errors are penalized more heavily. Use this alongside\n",
        "MAD to get a complete picture of prediction accuracy.\n\n", sep = "")

    # --- Actual vs Predicted plot (ggplot2) ---
    gg <- ggplot2::ggplot(predictions, ggplot2::aes(x = .data$Actual, y = .data$Predicted)) +
      ggplot2::geom_point(color = "steelblue") +
      ggplot2::geom_abline(color = "red", linewidth = 1) +
      ggplot2::labs(
        title = "Model Performance: Actual vs Predicted",
        x     = paste("Actual", outcome),
        y     = paste("Predicted", outcome)
      )
    print(gg)

    # Auto-save to working directory
    png_name <- paste0(.ml_env$student_name, "_actual_vs_predicted_", outcome, ".png")
    ggplot2::ggsave(png_name, plot = gg, width = 7, height = 5, dpi = 120)
    .lcat("  Plot saved to: ", png_name, "\n", sep = "")

    # --- Go back option ---
    if (.ask_yn("\nWould you like to go back to Step 4 (Evaluate)?")) {
      .lcat("\nGoing back to Step 4...\n")
      return(list(go_back = TRUE))
    }

    # --- Export prompt ---
    if (.ask_yn("Would you like to export all results to an Excel file?")) {
      suggested <- paste0(.ml_env$student_name, "_results.xlsx")
      file_name <- .ask(paste0("Enter file name (suggested: ", suggested, "): "))
      if (nchar(trimws(file_name)) == 0L) file_name <- suggested
      if (!grepl("\\.xlsx$", file_name, ignore.case = TRUE)) {
        file_name <- paste0(file_name, ".xlsx")
      }
      result <- new_ml_result(
        data = data, outcome = outcome, predictors = predictors,
        categorical = categorical, factor_levels = factor_levels,
        train_set = train_set, test_set = test_set, split_ratio = split_ratio,
        model = model, model_summary = model_summary, vif = vif_df,
        predictions = predictions, mad = mad_val, mse = mse_val,
        r_squared = r_squared, rse = rse, coefficients = coefficients_df
      )
      export_xlsx(result, file_name)
    }
  }

  # --- Build and return ml_result ---
  new_ml_result(
    data = data, outcome = outcome, predictors = predictors,
    categorical = categorical, factor_levels = factor_levels,
    train_set = train_set, test_set = test_set, split_ratio = split_ratio,
    model = model, model_summary = model_summary, vif = vif_df,
    predictions = predictions, mad = mad_val, mse = mse_val,
    r_squared = r_squared, rse = rse, coefficients = coefficients_df
  )
}
