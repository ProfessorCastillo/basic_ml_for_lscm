#' Interactive ML Regression Workflow
#'
#' Guides the student through the 5-step supervised machine learning
#' regression process using interactive console menus. At each step,
#' the student makes analytical decisions about their data.
#'
#' @param file_path Character. Path to the student's \code{.xlsx} data file.
#'
#' @return An object of class \code{ml_result} (returned invisibly).
#'
#' @details
#' The 5 steps are:
#' \enumerate{
#'   \item \strong{Collect Data} -- read the file, identify outcome and predictors
#'   \item \strong{Prepare Data} -- check for missing data, visualize, split train/test
#'   \item \strong{Train Model} -- fit a linear regression and interpret results
#'   \item \strong{Evaluate Model} -- check multicollinearity (VIF), improve if needed
#'   \item \strong{Test Model} -- predict on test set, compute MAD and MSE
#' }
#'
#' For a non-interactive version, see \code{\link{ml_run}}.
#'
#' @examples
#' \dontrun{
#' result <- ml_workflow("mydata.xlsx")
#' print(result)
#' plot(result)
#' export_xlsx(result, "results.xlsx")
#' }
#'
#' @export
ml_workflow <- function(file_path) {
  .print_header("Supervised ML Regression Workflow")
  cat("Welcome! This tool will guide you through the 5-step supervised\n")
  cat("machine learning process using linear regression.\n\n")
  cat("The 5 steps are:\n")
  cat("  1. Collect Data\n")
  cat("  2. Prepare the Data\n")
  cat("  3. Train the Model\n")
  cat("  4. Evaluate the Model\n")
  cat("  5. Test the Model\n\n")
  cat("You will make decisions at each step. Let's get started!\n")
  .pause()

  collect  <- step1_collect(file_path, interactive = TRUE)
  prepare  <- step2_prepare(collect, interactive = TRUE)
  train    <- step3_train(prepare, interactive = TRUE)
  evaluate <- step4_evaluate(train, interactive = TRUE)
  result   <- step5_test(evaluate, interactive = TRUE)

  cat("\nWorkflow complete! Your results are stored in the returned object.\n")
  cat("Use print(result) to see a summary, plot(result) for visuals,\n")
  cat("or export_xlsx(result, 'file.xlsx') to export to Excel.\n")

  invisible(result)
}
