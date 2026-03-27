#' Interactive ML Regression Workflow
#'
#' Guides the student through the 5-step supervised machine learning
#' regression process using interactive console menus. At each step,
#' the student makes analytical decisions about their data. Students
#' can go back to a previous step at any time without starting over.
#'
#' The entire interactive session (all output and student responses) is
#' captured in a log. It is saved automatically as a \code{.txt} file in
#' the working directory and included in the Excel export.
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
  # --- Start logging ---
  .log_start()

  .print_header("Supervised ML Regression Workflow")
  .lcat("Welcome! This tool will guide you through the 5-step supervised\n")
  .lcat("machine learning process using linear regression.\n\n")
  .lcat("The 5 steps are:\n")
  .lcat("  1. Collect Data\n")
  .lcat("  2. Prepare the Data\n")
  .lcat("  3. Train the Model\n")
  .lcat("  4. Evaluate the Model\n")
  .lcat("  5. Test the Model\n\n")
  .lcat("You will make decisions at each step. You can go back to a\n")
  .lcat("previous step at any time. Let's get started!\n\n")

  # Ask for student's OSU name.# (used for file naming and seed generation)
  student_name <- .ask("Enter your OSU name.# (e.g., castillo.230): ")
  student_name <- tolower(trimws(student_name))
  student_name <- gsub("[^a-z0-9._-]", "", student_name)  # sanitize, allow dots
  if (nchar(student_name) == 0L) student_name <- "student"
  .ml_env$student_name <- student_name

  # Generate deterministic seed from student name
  student_seed <- sum(utf8ToInt(student_name))
  .ml_env$student_seed <- student_seed

  # Ask for a short project name to differentiate file names
  project_name <- .ask("Enter a short project name for your files (e.g., ecommerce, bikes): ")
  project_name <- tolower(trimws(project_name))
  project_name <- gsub("[^a-z0-9._-]", "", project_name)
  .ml_env$project_name <- project_name

  file_prefix <- if (nchar(project_name) > 0L) paste0(student_name, "_", project_name) else student_name

  .lcat("Files will be named with prefix: ", file_prefix, "\n")
  .log_append("[seed: ", student_seed, "]\n")
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
        .lcat("\nYou're already at Step 1 -- there's no previous step to go back to.\n")
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

  .lcat("\nWorkflow complete! Your results are stored in the returned object.\n")

  # --- Stop logging, attach to result, and save to file ---
  session_log <- .log_stop()
  result$log <- session_log
  result$student_name <- .ml_env$student_name
  result$student_seed <- .ml_env$student_seed
  result$project_name <- .ml_env$project_name

  # Auto-save log as .txt with student name and project name
  log_filename <- paste0(file_prefix, "_session_log.txt")
  writeLines(session_log, log_filename)
  cat("Session log saved to: ", log_filename, "\n", sep = "")

  # --- Export prompt (after log is attached) ---
  if (.ask_yn("Would you like to export all results to an Excel file?")) {
    suggested <- paste0(file_prefix, "_results.xlsx")
    file_name <- .ask(paste0("Enter file name or press Enter to accept [", suggested, "]: "))
    if (nchar(trimws(file_name)) == 0L) file_name <- suggested
    if (!grepl("\\.xlsx$", file_name, ignore.case = TRUE)) {
      file_name <- paste0(file_name, ".xlsx")
    }
    export_xlsx(result, file_name)
  }

  cat("\nUse print(result) to see a summary, plot(result) for visuals,\n")
  cat("or export_xlsx(result, 'file.xlsx') to export to Excel.\n")

  invisible(result)
}
