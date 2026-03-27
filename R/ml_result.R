#' Create a new ml_result object
#'
#' Internal constructor for the S3 class returned by ml_workflow() and ml_run().
#'
#' @noRd
new_ml_result <- function(data, outcome, predictors, categorical, factor_levels,
                          train_set, test_set, split_ratio,
                          model, model_summary, vif,
                          predictions, mad, mse, r_squared, rse,
                          coefficients, log = NULL,
                          student_name = NULL, student_seed = NULL,
                          project_name = NULL) {
  obj <- list(
    data          = data,
    outcome       = outcome,
    predictors    = predictors,
    categorical   = categorical,
    factor_levels = factor_levels,
    train_set     = train_set,
    test_set      = test_set,
    split_ratio   = split_ratio,
    model         = model,
    model_summary = model_summary,
    vif           = vif,
    predictions   = predictions,
    mad           = mad,
    mse           = mse,
    r_squared     = r_squared,
    rse           = rse,
    coefficients  = coefficients,
    log           = log,
    student_name  = student_name,
    student_seed  = student_seed,
    project_name  = project_name
  )
  class(obj) <- "ml_result"
  obj
}

#' Print an ml_result object
#'
#' Displays a formatted summary of the ML regression results.
#'
#' @param x An object of class \code{ml_result}.
#' @param ... Additional arguments (ignored).
#'
#' @return Invisibly returns \code{x}.
#'
#' @export
print.ml_result <- function(x, ...) {
  cat("\n=== ML Regression Results ===\n\n")

  cat("Outcome Variable: ", x$outcome, "\n", sep = "")

  cont_preds <- setdiff(x$predictors, x$categorical)
  if (length(cont_preds) > 0) {
    cat("Predictors:       ", paste(cont_preds, collapse = ", "), "\n", sep = "")
  }

  if (!is.null(x$categorical) && length(x$categorical) > 0) {
    cat_parts <- vapply(x$categorical, function(cname) {
      lvls <- x$factor_levels[[cname]]
      paste0(cname, " (levels: ", lvls[1], " [ref], ",
             paste(lvls[-1], collapse = ", "), ")")
    }, character(1))
    cat("Categorical:      ", paste(cat_parts, collapse = "; "), "\n", sep = "")
  }

  cat("\n--- Model Fit ---\n")
  cat("R-squared:              ", round(x$r_squared, 2), "\n", sep = "")
  cat("Residual Standard Error:", round(x$rse, 2), "\n")

  cat("\n--- Coefficients ---\n")
  coef_display <- x$coefficients
  coef_display$Estimate <- round(coef_display$Estimate, 2)
  coef_display$Std.Error <- round(coef_display$Std.Error, 2)
  coef_display$t.value <- round(coef_display$t.value, 2)
  coef_display$p.value <- round(coef_display$p.value, 2)
  print(coef_display, row.names = FALSE)

  if (!is.null(x$vif)) {
    cat("\n--- VIF ---\n")
    print(x$vif, row.names = FALSE)
  }

  cat("\n--- Predictive Accuracy (Test Set) ---\n")
  cat("MAD:", round(x$mad, 2), "\n")
  cat("MSE:", round(x$mse, 2), "\n")

  cat("\nTrain/Test Split: ", x$split_ratio * 100, "/", (1 - x$split_ratio) * 100,
      " (", nrow(x$train_set), " / ", nrow(x$test_set), " observations)\n", sep = "")

  invisible(x)
}

#' Plot an ml_result object
#'
#' Produces a 2-panel layout: Actual vs Predicted (left) and Residuals vs Predicted (right).
#'
#' @param x An object of class \code{ml_result}.
#' @param ... Additional arguments (ignored).
#'
#' @return Invisibly returns \code{x}.
#'
#' @export
plot.ml_result <- function(x, ...) {
  old_par <- graphics::par(no.readonly = TRUE)
  on.exit(graphics::par(old_par))
  graphics::par(mfrow = c(1, 2))

  # Left panel: Actual vs Predicted
  graphics::plot(x$predictions$Actual, x$predictions$Predicted,
                 xlab = paste("Actual", x$outcome),
                 ylab = paste("Predicted", x$outcome),
                 main = "Actual vs Predicted",
                 pch = 16, col = "steelblue")
  graphics::abline(0, 1, col = "red", lwd = 2)

  # Right panel: Residuals vs Predicted
  residuals <- x$predictions$Actual - x$predictions$Predicted
  graphics::plot(x$predictions$Predicted, residuals,
                 xlab = paste("Predicted", x$outcome),
                 ylab = "Residuals",
                 main = "Residuals vs Predicted",
                 pch = 16, col = "steelblue")
  graphics::abline(h = 0, col = "red", lwd = 2)

  # Auto-save to working directory
  pn <- .ml_env$project_name
  name_prefix <- if (.ml_env$logging || nchar(.ml_env$student_name) > 0) {
    if (!is.null(pn) && nchar(pn) > 0L) paste0(.ml_env$student_name, "_", pn) else .ml_env$student_name
  } else "student"
  png_name <- paste0(name_prefix, "_diagnostic_plots_", x$outcome, ".png")
  grDevices::png(png_name, width = 1200, height = 600, res = 120)
  graphics::par(mfrow = c(1, 2))
  graphics::plot(x$predictions$Actual, x$predictions$Predicted,
                 xlab = paste("Actual", x$outcome),
                 ylab = paste("Predicted", x$outcome),
                 main = "Actual vs Predicted",
                 pch = 16, col = "steelblue")
  graphics::abline(0, 1, col = "red", lwd = 2)
  graphics::plot(x$predictions$Predicted, residuals,
                 xlab = paste("Predicted", x$outcome),
                 ylab = "Residuals",
                 main = "Residuals vs Predicted",
                 pch = 16, col = "steelblue")
  graphics::abline(h = 0, col = "red", lwd = 2)
  grDevices::dev.off()
  cat("Plot saved to:", png_name, "\n")

  invisible(x)
}
