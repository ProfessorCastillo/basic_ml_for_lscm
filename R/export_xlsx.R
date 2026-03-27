#' Export ML Results to Excel
#'
#' Writes all results from an ML regression workflow to a single Excel
#' workbook with multiple tabs: Coefficients, Model Fit, VIF, Predictions,
#' and Accuracy.
#'
#' @param x An object of class \code{ml_result}, as returned by
#'   \code{\link{ml_workflow}} or \code{\link{ml_run}}.
#' @param file Character. Output file path (e.g., \code{"results.xlsx"}).
#'
#' @return Invisibly returns the file path.
#'
#' @details
#' Requires the \code{openxlsx} package. If it is not installed, the
#' function will stop with installation instructions.
#'
#' @examples
#' \dontrun{
#' result <- ml_run("bikes.xlsx", "rentals",
#'                  c("temperature", "humidity", "windspeed"))
#' export_xlsx(result, "bike_results.xlsx")
#' }
#'
#' @export
export_xlsx <- function(x, file) {
  if (!inherits(x, "ml_result"))
    stop("x must be an ml_result object from ml_workflow() or ml_run().", call. = FALSE)
  if (!requireNamespace("openxlsx", quietly = TRUE))
    stop("Package 'openxlsx' is required. Install with: install.packages('openxlsx')",
         call. = FALSE)

  wb <- openxlsx::createWorkbook()

  # Tab 1: Coefficients (rounded to 2 decimal places)
  coef_export <- x$coefficients
  coef_export$Estimate <- round(coef_export$Estimate, 2)
  coef_export$Std.Error <- round(coef_export$Std.Error, 2)
  coef_export$t.value <- round(coef_export$t.value, 2)
  coef_export$p.value <- round(coef_export$p.value, 2)
  openxlsx::addWorksheet(wb, "Coefficients")
  openxlsx::writeData(wb, "Coefficients", coef_export)

  # Tab 2: Model Fit (rounded to 2 decimal places)
  f_stat <- x$model_summary$fstatistic
  f_pvalue <- stats::pf(f_stat[1], f_stat[2], f_stat[3], lower.tail = FALSE)
  fit_df <- data.frame(
    Student        = if (!is.null(x$student_name)) x$student_name else NA,
    Project        = if (!is.null(x$project_name)) x$project_name else NA,
    Seed           = if (!is.null(x$student_seed)) x$student_seed else NA,
    RSE            = round(x$rse, 2),
    R_squared      = round(x$r_squared, 2),
    Adj_R_squared  = round(x$model_summary$adj.r.squared, 2),
    F_statistic    = round(f_stat[1], 2),
    F_pvalue       = round(f_pvalue, 2)
  )
  openxlsx::addWorksheet(wb, "Model Fit")
  openxlsx::writeData(wb, "Model Fit", fit_df)

  # Tab 3: VIF (already rounded in compute_vif)
  openxlsx::addWorksheet(wb, "VIF")
  if (!is.null(x$vif)) {
    openxlsx::writeData(wb, "VIF", x$vif)
  } else {
    openxlsx::writeData(wb, "VIF",
                        data.frame(Note = "VIF not applicable (single predictor)"))
  }

  # Tab 4: Predictions (rounded to 2 decimal places)
  pred_export <- x$predictions
  pred_export$Predicted <- round(pred_export$Predicted, 2)
  pred_export$Error <- round(pred_export$Error, 2)
  pred_export$Absolute_Error <- round(pred_export$Absolute_Error, 2)
  openxlsx::addWorksheet(wb, "Predictions")
  openxlsx::writeData(wb, "Predictions", pred_export)

  # Tab 5: Accuracy (rounded to 2 decimal places)
  acc_df <- data.frame(MAD = round(x$mad, 2), MSE = round(x$mse, 2))
  openxlsx::addWorksheet(wb, "Accuracy")
  openxlsx::writeData(wb, "Accuracy", acc_df)

  # Tab 6: Console Log (if available)
  if (!is.null(x$log) && length(x$log) > 0) {
    log_df <- data.frame(Console_Output = x$log)
    openxlsx::addWorksheet(wb, "Console Log")
    openxlsx::writeData(wb, "Console Log", log_df)
  }

  openxlsx::saveWorkbook(wb, file, overwrite = TRUE)
  cat("Results exported to: ", file, "\n", sep = "")

  invisible(file)
}
