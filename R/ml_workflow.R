#' Interactive ML Regression Workflow
#'
#' Guides the student through the 5-step supervised machine learning
#' regression process using interactive console menus. At each step,
#' the student makes analytical decisions about their data. Students
#' can go back to a previous step at any time without starting over.
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
  # --- Capture console log ---
  log_file <- tempfile(fileext = ".txt")
  sink(log_file, split = TRUE)
  on.exit({
    if (sink.number() > 0) sink()
  }, add = TRUE)

  .print_header("Supervised ML Regression Workflow")
  cat("Welcome! This tool will guide you through the 5-step supervised\n")
  cat("machine learning process using linear regression.\n\n")
  cat("The 5 steps are:\n")
  cat("  1. Collect Data\n")
  cat("  2. Prepare the Data\n")
  cat("  3. Train the Model\n")
  cat("  4. Evaluate the Model\n")
  cat("  5. Test the Model\n\n")
  cat("You will make decisions at each step. You can go back to a\n")
  cat("previous step at any time. Let's get started!\n")
  .pause()

  # State machine: track results from each step
  collect  <- NULL
  prepare  <- NULL
  train    <- NULL
  evaluate <- NULL
  result   <- NULL

  current_step <- 1L

  while (current_step <= 5L) {
    if (current_step == 1L) {
      collect <- step1_collect(file_path, interactive = TRUE)
      if (isTRUE(collect$go_back)) {
        cat("\nYou're already at Step 1 -- there's no previous step to go back to.\n")
        next
      }
      current_step <- 2L

    } else if (current_step == 2L) {
      prepare <- step2_prepare(collect, interactive = TRUE)
      if (isTRUE(prepare$go_back)) {
        current_step <- 1L
        next
      }
      current_step <- 3L

    } else if (current_step == 3L) {
      train <- step3_train(prepare, interactive = TRUE)
      if (isTRUE(train$go_back)) {
        current_step <- 2L
        next
      }
      current_step <- 4L

    } else if (current_step == 4L) {
      evaluate <- step4_evaluate(train, interactive = TRUE)
      if (isTRUE(evaluate$go_back)) {
        current_step <- 3L
        next
      }
      current_step <- 5L

    } else if (current_step == 5L) {
      result <- step5_test(evaluate, interactive = TRUE)
      if (isTRUE(result$go_back)) {
        current_step <- 4L
        next
      }
      current_step <- 6L  # exit loop
    }
  }

  cat("\nWorkflow complete! Your results are stored in the returned object.\n")
  cat("Use print(result) to see a summary, plot(result) for visuals,\n")
  cat("or export_xlsx(result, 'file.xlsx') to export to Excel.\n")

  # --- Close sink and attach log ---
  if (sink.number() > 0) sink()
  if (file.exists(log_file)) {
    result$log <- readLines(log_file, warn = FALSE)
    unlink(log_file)
  }

  invisible(result)
}
