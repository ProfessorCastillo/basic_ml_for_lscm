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

  # Tab 1: Coefficients
  openxlsx::addWorksheet(wb, "Coefficients")
  openxlsx::writeData(wb, "Coefficients", x$coefficients)

  # Tab 2: Model Fit
  f_stat <- x$model_summary$fstatistic
  f_pvalue <- stats::pf(f_stat[1], f_stat[2], f_stat[3], lower.tail = FALSE)
  fit_df <- data.frame(
    RSE            = x$rse,
    R_squared      = x$r_squared,
    Adj_R_squared  = x$model_summary$adj.r.squared,
    F_statistic    = f_stat[1],
    F_pvalue       = f_pvalue
  )
  openxlsx::addWorksheet(wb, "Model Fit")
  openxlsx::writeData(wb, "Model Fit", fit_df)

  # Tab 3: VIF
  openxlsx::addWorksheet(wb, "VIF")
  if (!is.null(x$vif)) {
    openxlsx::writeData(wb, "VIF", x$vif)
  } else {
    openxlsx::writeData(wb, "VIF",
                        data.frame(Note = "VIF not applicable (single predictor)"))
  }

  # Tab 4: Predictions
  openxlsx::addWorksheet(wb, "Predictions")
  openxlsx::writeData(wb, "Predictions", x$predictions)

  # Tab 5: Accuracy
  acc_df <- data.frame(MAD = x$mad, MSE = x$mse)
  openxlsx::addWorksheet(wb, "Accuracy")
  openxlsx::writeData(wb, "Accuracy", acc_df)

  openxlsx::saveWorkbook(wb, file, overwrite = TRUE)
  cat("Results exported to: ", file, "\n", sep = "")

  invisible(file)
}
