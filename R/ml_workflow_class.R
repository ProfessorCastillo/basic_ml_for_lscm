#' Interactive ML Classification Workflow
#'
#' Guides the student through the 5-step supervised machine learning
#' classification process using interactive console menus. Uses logistic
#' regression for binary classification tasks.
#'
#' @param file_path Character. Path to the student's \code{.xlsx} data file.
#'
#' @return An object of class \code{ml_result_class} (returned invisibly).
#'
#' @details
#' The 5 steps are:
#' \enumerate{
#'   \item \strong{Collect Data} -- read the file, identify outcome and predictors
#'   \item \strong{Prepare Data} -- check for missing data, visualize, split train/test
#'   \item \strong{Train Model} -- fit a logistic regression and interpret results
#'   \item \strong{Evaluate Model} -- check multicollinearity (VIF), improve if needed
#'   \item \strong{Test Model} -- predict on test set, produce confusion matrix
#' }
#'
#' For a non-interactive version, see \code{\link{ml_run_class}}.
#'
#' @examples
#' \dontrun{
#' result <- ml_workflow_class("mydata.xlsx")
#' print(result)
#' plot(result)
#' export_xlsx(result, "results.xlsx")
#' }
#'
#' @export
ml_workflow_class <- function(file_path) {

  # --- Start logging ---
  .log_start()

  .print_header("Supervised ML Classification Workflow")
  .lcat("Welcome! This tool will guide you through the 5-step supervised\n")
  .lcat("machine learning process using logistic regression (binary\n")
  .lcat("classification).\n\n")
  .lcat("The 5 steps are:\n")
  .lcat("  1. Collect Data\n")
  .lcat("  2. Prepare the Data\n")
  .lcat("  3. Train the Model (Logistic Regression)\n")
  .lcat("  4. Evaluate the Model\n")
  .lcat("  5. Test the Model (Confusion Matrix & Accuracy)\n\n")
  .lcat("You will make decisions at each step. You can go back to a\n")
  .lcat("previous step at any time. Let's get started!\n\n")

  # Ask for student's OSU name.#
  student_name <- .ask("Enter your OSU name.# (e.g., castillo.230): ")
  student_name <- tolower(trimws(student_name))
  student_name <- gsub("[^a-z0-9._-]", "", student_name)
  if (nchar(student_name) == 0L) student_name <- "student"
  .ml_env$student_name <- student_name

  student_seed <- sum(utf8ToInt(student_name))
  .ml_env$student_seed <- student_seed

  project_name <- .ask("Enter a short project name for your files (e.g., churn, fraud): ")
  project_name <- tolower(trimws(project_name))
  project_name <- gsub("[^a-z0-9._-]", "", project_name)
  .ml_env$project_name <- project_name

  file_prefix <- if (nchar(project_name) > 0L) {
    paste0(student_name, "_", project_name)
  } else {
    student_name
  }

  .lcat("Files will be named with prefix: ", file_prefix, "\n")
  .log_append("[seed: ", student_seed, "]\n")
  .pause()

  # State machine
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

      # --- Binary outcome validation ---
      outcome_vals <- unique(collect$data[[collect$outcome]])
      outcome_vals <- outcome_vals[!is.na(outcome_vals)]

      if (length(outcome_vals) != 2) {
        .lcat("\nWARNING: Your outcome variable '", collect$outcome,
            "' has ", length(outcome_vals), " unique values.\n", sep = "")
        .lcat("Binary classification requires exactly 2 outcome levels.\n")
        .lcat("Please go back and choose a different outcome variable,\n")
        .lcat("or use ml_workflow() for a regression task.\n")
        .pause()
        next
      }

      # --- Positive class selection ---
      .lcat("\nYour outcome '", collect$outcome, "' has 2 levels: ",
          paste(outcome_vals, collapse = " and "), "\n", sep = "")
      .lcat("Which level is the POSITIVE class -- the event you want to predict?\n\n")
      for (i in seq_along(outcome_vals)) {
        .lcat("  [", i, "] ", outcome_vals[i], "\n", sep = "")
      }
      repeat {
        pos_input <- .ask("Enter your choice: ")
        pos_num <- suppressWarnings(as.integer(pos_input))
        if (!is.na(pos_num) && pos_num >= 1L && pos_num <= length(outcome_vals)) {
          positive_class <- as.character(outcome_vals[pos_num])
          break
        }
        # Try by name
        if (pos_input %in% as.character(outcome_vals)) {
          positive_class <- pos_input
          break
        }
        .lcat("Please enter 1 or 2, or type the level name.\n")
      }

      negative_class <- setdiff(as.character(outcome_vals), positive_class)

      # Convert outcome to factor with positive class as second level
      # (glm models P(second level = 1))
      collect$data[[collect$outcome]] <- factor(
        collect$data[[collect$outcome]],
        levels = c(negative_class, positive_class)
      )
      collect$positive_class <- positive_class

      .lcat("\nPositive class set to: '", positive_class,
          "' (model will predict the probability of this outcome)\n", sep = "")

      current_step <- 2L

    } else if (current_step == 2L) {
      prepare <- step2_prepare(collect, interactive = TRUE, task = "classification")
      if (isTRUE(prepare$go_back)) {
        current_step <- 1L
        next
      }
      prepare$positive_class <- collect$positive_class
      current_step <- 3L

    } else if (current_step == 3L) {
      train <- step3_train_class(prepare, interactive = TRUE)
      if (isTRUE(train$go_back)) {
        current_step <- 2L
        next
      }
      current_step <- 4L

    } else if (current_step == 4L) {
      evaluate <- step4_evaluate_class(train, interactive = TRUE)
      if (isTRUE(evaluate$go_back)) {
        current_step <- 3L
        next
      }
      current_step <- 5L

    } else if (current_step == 5L) {
      result <- step5_test_class(evaluate, interactive = TRUE)
      if (isTRUE(result$go_back)) {
        current_step <- 4L
        next
      }
      current_step <- 6L
    }
  }

  .lcat("\nWorkflow complete! Your results are stored in the returned object.\n")

  # --- Stop logging, attach to result ---
  session_log <- .log_stop()
  result$log <- session_log
  result$student_name <- .ml_env$student_name
  result$student_seed <- .ml_env$student_seed
  result$project_name <- .ml_env$project_name

  log_filename <- paste0(file_prefix, "_session_log.txt")
  writeLines(session_log, log_filename)
  cat("Session log saved to: ", log_filename, "\n", sep = "")

  # --- Export prompt ---
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
