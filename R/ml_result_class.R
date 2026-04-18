#' Create a new ml_result_class object
#'
#' Internal constructor for the S3 class returned by ml_workflow_class()
#' and ml_run_class().
#'
#' @noRd
new_ml_result_class <- function(data, outcome, positive_class, predictors,
                                categorical, factor_levels,
                                train_set, test_set, split_ratio,
                                model, model_summary, vif,
                                predictions, confusion_matrix,
                                accuracy, threshold,
                                coefficients, log = NULL,
                                student_name = NULL, student_seed = NULL,
                                project_name = NULL) {
  obj <- list(
    data             = data,
    outcome          = outcome,
    positive_class   = positive_class,
    predictors       = predictors,
    categorical      = categorical,
    factor_levels    = factor_levels,
    train_set        = train_set,
    test_set         = test_set,
    split_ratio      = split_ratio,
    model            = model,
    model_summary    = model_summary,
    vif              = vif,
    predictions      = predictions,
    confusion_matrix = confusion_matrix,
    accuracy         = accuracy,
    threshold        = threshold,
    coefficients     = coefficients,
    log              = log,
    student_name     = student_name,
    student_seed     = student_seed,
    project_name     = project_name
  )
  class(obj) <- "ml_result_class"
  obj
}

#' Print an ml_result_class object
#'
#' Displays a formatted summary of the ML classification results.
#'
#' @param x An object of class \code{ml_result_class}.
#' @param ... Additional arguments (ignored).
#'
#' @return Invisibly returns \code{x}.
#'
#' @export
print.ml_result_class <- function(x, ...) {
  cat("\n=== ML Classification Results ===\n\n")

  cat("Outcome Variable:  ", x$outcome, "\n", sep = "")
  cat("Positive Class:    ", x$positive_class, "\n", sep = "")
  cat("Threshold:         ", x$threshold, "\n", sep = "")

  cont_preds <- setdiff(x$predictors, x$categorical)
  if (length(cont_preds) > 0) {
    cat("Predictors:        ", paste(cont_preds, collapse = ", "), "\n", sep = "")
  }

  if (!is.null(x$categorical) && length(x$categorical) > 0) {
    cat_parts <- vapply(x$categorical, function(cname) {
      lvls <- x$factor_levels[[cname]]
      paste0(cname, " (levels: ", lvls[1], " [ref], ",
             paste(lvls[-1], collapse = ", "), ")")
    }, character(1))
    cat("Categorical:       ", paste(cat_parts, collapse = "; "), "\n", sep = "")
  }

  cat("\n--- Model Fit ---\n")
  cat("AIC:              ", round(x$model$aic, 2), "\n", sep = "")
  pseudo_r2 <- 1 - (x$model$deviance / x$model$null.deviance)
  cat("Pseudo R-squared: ", round(pseudo_r2, 2), "\n", sep = "")

  cat("\n--- Coefficients ---\n")
  coef_display <- x$coefficients
  coef_display$Estimate <- round(coef_display$Estimate, 2)
  coef_display$Std.Error <- round(coef_display$Std.Error, 2)
  coef_display$z.value <- round(coef_display$z.value, 2)
  coef_display$p.value <- round(coef_display$p.value, 2)
  coef_display$Odds_Ratio <- round(coef_display$Odds_Ratio, 2)
  print(coef_display, row.names = FALSE)

  if (!is.null(x$vif)) {
    cat("\n--- VIF ---\n")
    print(x$vif, row.names = FALSE)
  }

  cat("\n--- Confusion Matrix ---\n")
  print(x$confusion_matrix)

  cat("\n--- Accuracy ---\n")
  cat("Accuracy: ", round(x$accuracy * 100, 2), "%\n", sep = "")

  cat("\nTrain/Test Split: ", x$split_ratio * 100, "/", (1 - x$split_ratio) * 100,
      " (", nrow(x$train_set), " / ", nrow(x$test_set), " observations)\n", sep = "")

  invisible(x)
}

#' Plot an ml_result_class object
#'
#' Displays a confusion matrix heatmap.
#'
#' @param x An object of class \code{ml_result_class}.
#' @param ... Additional arguments (ignored).
#'
#' @return Invisibly returns \code{x}.
#'
#' @export
plot.ml_result_class <- function(x, ...) {
  cm <- x$confusion_matrix
  cm_df <- as.data.frame(cm)
  names(cm_df) <- c("Predicted", "Actual", "Count")

  gg <- ggplot2::ggplot(cm_df, ggplot2::aes(
      x = .data$Actual, y = .data$Predicted, fill = .data$Count)) +
    ggplot2::geom_tile(color = "white", linewidth = 1.5) +
    ggplot2::geom_text(ggplot2::aes(label = .data$Count), size = 8) +
    ggplot2::scale_fill_gradient(low = "white", high = "steelblue") +
    ggplot2::labs(
      title = paste0("Confusion Matrix (Accuracy: ",
                     round(x$accuracy * 100, 1), "%)"),
      x = "Actual", y = "Predicted"
    ) +
    ggplot2::theme_minimal(base_size = 14)
  print(gg)

  # Auto-save to working directory
  png_name <- paste0(.file_prefix(), "_confusion_matrix_",
                     .safe_name(x$outcome), ".png")
  ggplot2::ggsave(png_name, plot = gg, width = 6, height = 5, dpi = 120)
  cat("Plot saved to:", png_name, "\n")

  invisible(x)
}
