#' Step 1: Collect Data
#'
#' Reads an xlsx file, lets the student identify the outcome variable,
#' categorical predictors (with levels), and predictor variables.
#'
#' @param file_path Character. Path to the .xlsx file.
#' @param interactive Logical. If TRUE, prompts user via console.
#' @param outcome Character. Outcome variable name (non-interactive mode).
#' @param predictors Character vector. Predictor names (non-interactive mode).
#' @param categorical Character vector or NULL. Categorical predictor names.
#' @param factor_levels Named list or NULL. Factor levels per categorical variable.
#'
#' @return A list with components: data, outcome, predictors, categorical, factor_levels.
#'
#' @noRd
step1_collect <- function(file_path, interactive = TRUE,
                          outcome = NULL, predictors = NULL,
                          categorical = NULL, factor_levels = NULL) {

  # --- Input validation ---
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path, call. = FALSE)
  }
  if (!grepl("\\.(xlsx|xls)$", file_path, ignore.case = TRUE)) {
    stop("File must be an .xlsx or .xls file.", call. = FALSE)
  }

  # --- Read data ---
  data <- readxl::read_excel(file_path)
  data <- as.data.frame(data)

  if (interactive) {
    # Outer loop allows restarting Step 1 if the student wants to redo selections
    repeat {
      # Re-read data each time in case factor conversions need to be reset
      data <- readxl::read_excel(file_path)
      data <- as.data.frame(data)

      .print_header("Step 1: Collect Data")
      cat("Reading file: ", basename(file_path), "\n", sep = "")
      cat("Found ", nrow(data), " observations and ", ncol(data), " columns.\n\n", sep = "")
      cat("Columns:\n")
      .print_columns(data)

      # --- Outcome variable ---
      repeat {
        outcome <- .ask("\nWhich column is your outcome variable (Y)? Enter the column name: ")
        check <- .validate_columns(outcome, names(data))
        if (check$valid) break
        cat("Column '", outcome, "' not found. Please try again.\n", sep = "")
      }

      # --- Categorical variables ---
      categorical <- NULL
      factor_levels <- NULL
      has_cat <- .ask_yn("\nDo you have any categorical predictor variables?")

      if (has_cat) {
        repeat {
          cat_input <- .ask("Which column(s) are categorical? Enter name(s) separated by commas: ")
          categorical <- .parse_comma_list(cat_input)
          check <- .validate_columns(categorical, names(data))
          if (check$valid) break
          cat("Column(s) not found: ", paste(check$bad, collapse = ", "),
              ". Please try again.\n", sep = "")
        }

        factor_levels <- list()
        for (cname in categorical) {
          lvl_input <- .ask(paste0(
            "\nWhat are the levels for '", cname,
            "'? Enter them separated by commas\n",
            "(the first one listed becomes the reference level): "
          ))
          lvls <- .parse_comma_list(lvl_input)
          factor_levels[[cname]] <- lvls
          data[[cname]] <- factor(data[[cname]], levels = lvls)
        }
      }

      # --- Predictor variables ---
      available <- setdiff(names(data), outcome)
      cat("\nAvailable columns (excluding outcome):\n")
      for (i in seq_along(available)) {
        cat("  ", available[i], "\n", sep = "")
      }
      repeat {
        pred_input <- .ask("\nWhich columns are your predictor variables (X)? Enter name(s) separated by commas: ")
        predictors <- .parse_comma_list(pred_input)
        check <- .validate_columns(predictors, available)
        if (check$valid) break
        cat("Column(s) not found: ", paste(check$bad, collapse = ", "),
            ". Please try again.\n", sep = "")
      }

      # --- Summary ---
      .print_subheader("Summary")
      cat("Outcome:     ", outcome, "\n", sep = "")
      cont_preds <- setdiff(predictors, categorical)
      if (length(cont_preds) > 0) {
        cat("Predictors:  ", paste(cont_preds, collapse = ", "), "\n", sep = "")
      }
      if (!is.null(categorical) && length(categorical) > 0) {
        for (cname in categorical) {
          lvls <- factor_levels[[cname]]
          cat("Categorical: ", cname, " (levels: ", lvls[1], " [ref], ",
              paste(lvls[-1], collapse = ", "), ")\n", sep = "")
        }
      }
      cat("Observations:", nrow(data), "\n")

      # --- Confirmation ---
      if (.ask_yn("\nDoes this look correct?")) break
      cat("\nNo problem -- let's redo Step 1.\n")
    } # end repeat

  } else {
    # --- Non-interactive mode ---
    if (is.null(outcome)) stop("outcome is required in non-interactive mode.", call. = FALSE)
    if (is.null(predictors)) stop("predictors is required in non-interactive mode.", call. = FALSE)

    all_needed <- c(outcome, predictors)
    check <- .validate_columns(all_needed, names(data))
    if (!check$valid) {
      stop("Column(s) not found in data: ", paste(check$bad, collapse = ", "), call. = FALSE)
    }

    if (!is.null(categorical) && !is.null(factor_levels)) {
      for (cname in categorical) {
        lvls <- factor_levels[[cname]]
        data[[cname]] <- factor(data[[cname]], levels = lvls)
      }
    }
  }

  list(
    data          = data,
    outcome       = outcome,
    predictors    = predictors,
    categorical   = categorical,
    factor_levels = factor_levels
  )
}
