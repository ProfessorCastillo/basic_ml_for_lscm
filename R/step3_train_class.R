#' Step 3 (Classification): Train the Model
#'
#' Builds and trains a logistic regression model (binary classification),
#' prints coefficient interpretations with odds ratios and model fit.
#'
#' @param prepare_result List returned by step2_prepare().
#' @param interactive Logical. If TRUE, prompts user via console.
#'
#' @return A list extending prepare_result with: model, model_summary,
#'   coefficients_df, odds_ratios.
#'
#' @importFrom stats glm binomial coef
#' @noRd
step3_train_class <- function(prepare_result, interactive = TRUE) {

  data          <- prepare_result$data
  outcome       <- prepare_result$outcome
  predictors    <- prepare_result$predictors
  categorical   <- prepare_result$categorical
  factor_levels <- prepare_result$factor_levels
  train_set     <- prepare_result$train_set
  test_set      <- prepare_result$test_set
  split_ratio   <- prepare_result$split_ratio
  positive_class <- prepare_result$positive_class

  if (interactive) {
    .print_header("Step 3: Train the Model (Classification)")
    .lcat("Model type: Logistic Regression (binary classification)\n")
    .lcat("Positive class (what you're predicting): '", positive_class, "'\n\n", sep = "")
    .lcat("Current predictors: ", paste(predictors, collapse = ", "), "\n", sep = "")

    ready <- .ask_yn("Ready to train the model with these predictors?")
    if (!ready) {
      if (.ask_yn("Would you like to go back to Step 2?")) {
        .lcat("\nGoing back to Step 2...\n")
        return(list(go_back = TRUE))
      }
      if (.ask_yn("Would you like to change your predictors?")) {
        available <- setdiff(names(data), outcome)
        .lcat("\nAvailable columns:\n")
        for (nm in available) cat("  ", nm, "\n", sep = "")
        repeat {
          pred_input <- .ask("\nEnter predictor name(s) separated by commas: ")
          predictors <- .parse_comma_list(pred_input)
          check <- .validate_columns(predictors, available)
          if (check$valid) break
          .lcat("Column(s) not found: ", paste(check$bad, collapse = ", "), "\n", sep = "")
        }
      }
    }
  }

  # --- Build and train ---
  if (interactive) Sys.sleep(runif(1, min = 3, max = 5))
  formula_str <- paste(.bt(outcome), "~", paste(.bt(predictors), collapse = " + "))
  formula_obj <- stats::as.formula(formula_str)
  model <- stats::glm(formula_obj, data = train_set, family = stats::binomial)
  model_summary <- summary(model)

  # --- Extract coefficients ---
  coefficients_df <- data.frame(
    Variable    = rownames(model_summary$coefficients),
    Estimate    = model_summary$coefficients[, "Estimate"],
    Std.Error   = model_summary$coefficients[, "Std. Error"],
    z.value     = model_summary$coefficients[, "z value"],
    p.value     = model_summary$coefficients[, "Pr(>|z|)"],
    Odds_Ratio  = exp(model_summary$coefficients[, "Estimate"]),
    stringsAsFactors = FALSE
  )
  rownames(coefficients_df) <- NULL

  if (interactive) {
    .print_subheader("Coefficients")
    display_df <- coefficients_df
    display_df$Estimate <- round(display_df$Estimate, 2)
    display_df$Std.Error <- round(display_df$Std.Error, 2)
    display_df$z.value <- round(display_df$z.value, 2)
    display_df$p.value <- round(display_df$p.value, 2)
    display_df$Odds_Ratio <- round(display_df$Odds_Ratio, 2)
    .lprint(display_df, row.names = FALSE)

    # --- Interpretation guide ---
    .lcat("\nHow to read odds ratios:\n")
    .lcat("  Odds Ratio > 1 = increases the odds of '", positive_class, "'\n", sep = "")
    .lcat("  Odds Ratio < 1 = decreases the odds of '", positive_class, "'\n", sep = "")
    .lcat("  Odds Ratio = 1 = no effect on the odds\n\n")

    # --- Per-predictor interpretations ---
    for (i in seq_len(nrow(coefficients_df))) {
      vname <- coefficients_df$Variable[i]
      beta  <- coefficients_df$Estimate[i]
      pval  <- coefficients_df$p.value[i]
      or    <- coefficients_df$Odds_Ratio[i]
      if (vname == "(Intercept)") next

      sig_text <- if (pval < 0.05) {
        " (Statistically significant)"
      } else {
        " (Not statistically significant -- interpret with caution)"
      }

      # Check if this is a categorical level
      is_cat_level <- FALSE
      if (!is.null(categorical)) {
        for (cname in categorical) {
          if (startsWith(vname, cname) && nchar(vname) > nchar(cname)) {
            level_name <- substring(vname, nchar(cname) + 1)
            ref_level <- factor_levels[[cname]][1]
            if (or >= 1) {
              .lcat("  ", vname, ": ", level_name, " has ",
                  round(or, 2), "x the odds of '", positive_class,
                  "' compared to ", ref_level, ".", sig_text, "\n", sep = "")
            } else {
              .lcat("  ", vname, ": ", level_name, " has ",
                  round(or * 100, 1), "% the odds of '", positive_class,
                  "' compared to ", ref_level, " (lower odds).", sig_text, "\n", sep = "")
            }
            is_cat_level <- TRUE
            break
          }
        }
      }
      if (!is_cat_level) {
        if (or >= 1) {
          .lcat("  ", vname, ": A 1-unit increase multiplies the odds of '",
              positive_class, "' by ", round(or, 2), ".", sig_text, "\n", sep = "")
        } else {
          .lcat("  ", vname, ": A 1-unit increase reduces the odds of '",
              positive_class, "' to ", round(or * 100, 1), "% of the original.",
              sig_text, "\n", sep = "")
        }
      }
    }

    # --- Model fit ---
    .print_subheader("Model Fit")
    .lcat("AIC = ", round(model$aic, 2),
        ". A lower AIC indicates a better-fitting model. Use this to\n",
        "compare different models on the same data -- the one with the\n",
        "lowest AIC is preferred.\n\n", sep = "")

    null_dev <- model$null.deviance
    resid_dev <- model$deviance
    pseudo_r2 <- 1 - (resid_dev / null_dev)
    .lcat("Pseudo R-squared = ", round(pseudo_r2, 2),
        ". This is a rough analog of R-squared for logistic regression.\n",
        "It represents how much better the model is than a naive model\n",
        "that ignores all predictors. Values closer to 1 are better.\n", sep = "")

    .pause()
  }

  list(
    data            = data,
    outcome         = outcome,
    positive_class  = positive_class,
    predictors      = predictors,
    categorical     = categorical,
    factor_levels   = factor_levels,
    train_set       = train_set,
    test_set        = test_set,
    split_ratio     = split_ratio,
    model           = model,
    model_summary   = model_summary,
    coefficients_df = coefficients_df
  )
}
