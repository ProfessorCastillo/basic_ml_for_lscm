#' Step 2: Prepare the Data
#'
#' Interactive menu for: missing data check, scatter plots, box plots,
#' correlation matrix, and train/test split.
#'
#' @param collect_result List returned by step1_collect().
#' @param interactive Logical. If TRUE, shows menus.
#' @param split_ratio Numeric. Training set proportion (default 0.8).
#'
#' @return A list extending collect_result with: train_set, test_set, split_ratio.
#'
#' @importFrom caTools sample.split
#' @importFrom corrplot corrplot
#' @importFrom stats cor
#' @noRd
step2_prepare <- function(collect_result, interactive = TRUE, split_ratio = 0.8) {

  data        <- collect_result$data
  outcome     <- collect_result$outcome
  predictors  <- collect_result$predictors
  categorical <- collect_result$categorical
  factor_levels <- collect_result$factor_levels

  cont_preds <- setdiff(predictors, categorical)
  train_set <- NULL
  test_set  <- NULL
  split_done <- FALSE

  if (interactive) {
    .print_header("Step 2: Prepare the Data")

    choices <- c(
      "Check for missing data",
      "Create scatter plots (continuous predictors)",
      "Create box plots (categorical predictors)",
      "Create correlation matrix (continuous variables)",
      "Split into training and testing sets",
      "Continue to Step 3 (Train the Model)",
      "Go back to Step 1 (Collect Data)"
    )

    repeat {
      choice <- .menu("Prepare the Data -- select a task:", choices)

      if (choice == 7L) {
        # --- Go back ---
        .lcat("\nGoing back to Step 1...\n")
        return(list(go_back = TRUE))

      } else if (choice == 1L) {
        # --- Missing data check ---
        if (!any(is.na(data))) {
          .lcat("\nNo missing data found. You're good to proceed.\n")
        } else {
          .lcat("\nMissing data detected!\n")
          na_counts <- colSums(is.na(data))
          na_cols <- na_counts[na_counts > 0]
          for (nm in names(na_cols)) {
            .lcat("  ", nm, ": ", na_cols[nm], " missing value(s)\n", sep = "")
          }
          if (.ask_yn("\nWould you like to remove rows with missing data?")) {
            before <- nrow(data)
            data <- data[stats::complete.cases(data), ]
            .lcat("Removed ", before - nrow(data), " rows. ",
                nrow(data), " rows remaining.\n", sep = "")
          }
        }

      } else if (choice == 2L) {
        # --- Scatter plots (continuous predictors) ---
        if (length(cont_preds) == 0) {
          .lcat("\nNo continuous predictors to plot.\n")
        } else {
          .lcat("\n")
          for (i in seq_along(cont_preds)) {
            pred <- cont_preds[i]
            plot_title <- paste("Impact of", pred, "on", outcome)

            # Display in RStudio
            graphics::plot(data[[pred]], data[[outcome]],
                           xlab = pred, ylab = outcome,
                           main = plot_title,
                           pch = 16, col = "steelblue")

            # Auto-save to working directory
            png_name <- paste0("scatter_", pred, "_vs_", outcome, ".png")
            .save_plot(png_name)
            graphics::plot(data[[pred]], data[[outcome]],
                           xlab = pred, ylab = outcome,
                           main = plot_title,
                           pch = 16, col = "steelblue")
            .save_plot_done(png_name)

            if (i < length(cont_preds)) .pause()
          }
          .lcat("\nAll scatter plots saved to your working directory.\n")
        }

      } else if (choice == 3L) {
        # --- Box plots (categorical predictors) ---
        if (is.null(categorical) || length(categorical) == 0) {
          .lcat("\nNo categorical predictors declared. Skipping.\n")
        } else {
          .lcat("\n")
          for (i in seq_along(categorical)) {
            cname <- categorical[i]
            plot_title <- paste(outcome, "by", cname)

            # Display in RStudio
            graphics::boxplot(data[[outcome]] ~ data[[cname]],
                              xlab = cname, ylab = outcome,
                              main = plot_title)

            # Auto-save to working directory
            png_name <- paste0("boxplot_", outcome, "_by_", cname, ".png")
            .save_plot(png_name)
            graphics::boxplot(data[[outcome]] ~ data[[cname]],
                              xlab = cname, ylab = outcome,
                              main = plot_title)
            .save_plot_done(png_name)

            if (i < length(categorical)) .pause()
          }
          .lcat("\nAll box plots saved to your working directory.\n")
        }

      } else if (choice == 4L) {
        # --- Correlation matrix ---
        cor_vars <- c(cont_preds, outcome)
        if (length(cor_vars) < 2) {
          .lcat("\nNeed at least 2 continuous variables for a correlation matrix.\n")
        } else {
          cor_data <- data[, cor_vars, drop = FALSE]
          # Ensure all numeric
          cor_data <- cor_data[, vapply(cor_data, is.numeric, logical(1)), drop = FALSE]
          if (ncol(cor_data) < 2) {
            .lcat("\nNot enough numeric columns for a correlation matrix.\n")
          } else {
            # Display in RStudio
            corrplot::corrplot(stats::cor(cor_data), type = "lower",
                               method = "number", tl.cex = 0.8, number.cex = 0.8)

            # Auto-save to working directory
            png_name <- "correlation_matrix.png"
            .save_plot(png_name)
            corrplot::corrplot(stats::cor(cor_data), type = "lower",
                               method = "number", tl.cex = 0.8, number.cex = 0.8)
            .save_plot_done(png_name)

            .lcat("\nInterpretation: Look for predictors with strong correlations to your\n")
            .lcat("outcome (closer to +1 or -1). Also watch for predictors that are\n")
            .lcat("highly correlated with each other -- this may cause multicollinearity\n")
            .lcat("issues in Step 4.\n")
          }
        }

      } else if (choice == 5L) {
        # --- Train/test split ---
        use_default <- .ask_yn(
          "The recommended split is 80% training / 20% testing. Would you like to use this?"
        )
        if (!use_default) {
          repeat {
            pct_input <- .ask("Enter your training percentage (e.g., 70 for 70%): ")
            pct <- suppressWarnings(as.numeric(pct_input))
            if (!is.na(pct) && pct > 0 && pct < 100) {
              split_ratio <- pct / 100
              break
            }
            .lcat("Please enter a number between 1 and 99.\n")
          }
        } else {
          split_ratio <- 0.8
        }

        set.seed(4321)
        split_flag <- caTools::sample.split(data[[outcome]], SplitRatio = split_ratio)
        train_set <- data[split_flag, ]
        test_set  <- data[!split_flag, ]
        split_done <- TRUE

        .lcat("\nTraining set: ", nrow(train_set), " observations (",
            round(split_ratio * 100), "%)\n", sep = "")
        .lcat("Testing set:  ", nrow(test_set), " observations (",
            round((1 - split_ratio) * 100), "%)\n", sep = "")

      } else if (choice == 6L) {
        # --- Continue ---
        if (!split_done) {
          .lcat("\nYou haven't split the data yet. Please complete task [5] first.\n")
        } else {
          break
        }
      }
    }

  } else {
    # --- Non-interactive mode ---
    # Warn about NAs but don't remove
    if (any(is.na(data))) {
      warning("Data contains missing values. Consider handling them before modeling.",
              call. = FALSE)
    }

    set.seed(4321)
    split_flag <- caTools::sample.split(data[[outcome]], SplitRatio = split_ratio)
    train_set <- data[split_flag, ]
    test_set  <- data[!split_flag, ]
  }

  list(
    data          = data,
    outcome       = outcome,
    predictors    = predictors,
    categorical   = categorical,
    factor_levels = factor_levels,
    train_set     = train_set,
    test_set      = test_set,
    split_ratio   = split_ratio
  )
}
