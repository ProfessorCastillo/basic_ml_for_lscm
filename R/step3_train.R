#' Step 3: Train the Model
#'
#' Builds and trains a linear regression model, prints coefficient
#' interpretations and model fit statistics.
#'
#' @param prepare_result List returned by step2_prepare().
#' @param interactive Logical. If TRUE, prompts user via console.
#'
#' @return A list extending prepare_result with: model, model_summary,
#'   coefficients_df, r_squared, rse.
#'
#' @importFrom stats lm summary.lm as.formula pf
#' @noRd
step3_train <- function(prepare_result, interactive = TRUE) {

  data          <- prepare_result$data
  outcome       <- prepare_result$outcome
  predictors    <- prepare_result$predictors
  categorical   <- prepare_result$categorical
  factor_levels <- prepare_result$factor_levels
  train_set     <- prepare_result$train_set
  test_set      <- prepare_result$test_set
  split_ratio   <- prepare_result$split_ratio

  if (interactive) {
    .print_header("Step 3: Train the Model")
    cat("Current predictors: ", paste(predictors, collapse = ", "), "\n", sep = "")

    if (!.ask_yn("Ready to train the model with these predictors?")) {
      if (.ask_yn("Would you like to change your predictors?")) {
        available <- setdiff(names(data), outcome)
        cat("\nAvailable columns:\n")
        for (nm in available) cat("  ", nm, "\n", sep = "")
        repeat {
          pred_input <- .ask("\nEnter predictor name(s) separated by commas: ")
          predictors <- .parse_comma_list(pred_input)
          check <- .validate_columns(predictors, available)
          if (check$valid) break
          cat("Column(s) not found: ", paste(check$bad, collapse = ", "), "\n", sep = "")
        }
      }
    }
  }

  # --- Build and train ---
  formula_str <- paste(outcome, "~", paste(predictors, collapse = " + "))
  formula_obj <- stats::as.formula(formula_str)
  model <- stats::lm(formula_obj, data = train_set)
  model_summary <- summary(model)

  # --- Extract results ---
  coefficients_df <- data.frame(
    Variable  = rownames(model_summary$coefficients),
    Estimate  = model_summary$coefficients[, "Estimate"],
    Std.Error = model_summary$coefficients[, "Std. Error"],
    t.value   = model_summary$coefficients[, "t value"],
    p.value   = model_summary$coefficients[, "Pr(>|t|)"],
    stringsAsFactors = FALSE
  )
  rownames(coefficients_df) <- NULL

  r_squared <- model_summary$r.squared
  rse       <- model_summary$sigma
  f_stat    <- model_summary$fstatistic
  f_pvalue  <- stats::pf(f_stat[1], f_stat[2], f_stat[3], lower.tail = FALSE)

  if (interactive) {
    .print_subheader("Coefficients")
    display_df <- coefficients_df
    display_df$Estimate <- round(display_df$Estimate, 4)
    display_df$Std.Error <- round(display_df$Std.Error, 4)
    display_df$t.value <- round(display_df$t.value, 4)
    display_df$p.value <- formatC(display_df$p.value, format = "e", digits = 3)
    print(display_df, row.names = FALSE)

    # --- Interpretations for each predictor ---
    cat("\n")
    for (i in seq_len(nrow(coefficients_df))) {
      vname <- coefficients_df$Variable[i]
      beta  <- coefficients_df$Estimate[i]
      pval  <- coefficients_df$p.value[i]
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
            cat("  ", vname, ": ", level_name, " is associated with a ",
                round(beta, 4), " difference in ", outcome,
                " compared to ", ref_level, ".", sig_text, "\n", sep = "")
            is_cat_level <- TRUE
            break
          }
        }
      }
      if (!is_cat_level) {
        cat("  ", vname, ": A 1-unit increase in ", vname,
            " is associated with a ", round(beta, 4),
            " change in ", outcome, ".", sig_text, "\n", sep = "")
      }
    }

    # --- Model fit ---
    .print_subheader("Model Fit")
    cat("RSE = ", round(rse, 4),
        ". This means your predictions will typically be off by about +/- ",
        round(rse, 2), " units of ", outcome,
        ". A smaller RSE means more precise predictions.\n\n", sep = "")

    cat("R-squared = ", round(r_squared, 4),
        ". This means ", round(r_squared * 100, 1),
        "% of the variation in ", outcome,
        " is explained by your predictors. The closer to 1 (100%), the\n",
        "better your model fits the data. The remaining ",
        round((1 - r_squared) * 100, 1),
        "% is unexplained -- it could be random noise\n",
        "or factors you haven't included.\n\n", sep = "")

    cat("F-statistic p-value = ", formatC(f_pvalue, format = "e", digits = 3),
        ". This tells you whether your model as a whole is statistically\n",
        "significant. ", sep = "")
    if (f_pvalue < 0.05) {
      cat("Since this value is less than 0.05, you can be at least 95% confident\n",
          "that your predictors, taken together, have a real relationship with ",
          outcome, ".\n", sep = "")
    } else {
      cat("Since this value is greater than 0.05, the model may not be reliable.\n",
          "Consider revisiting your predictor selections.\n", sep = "")
    }

    .pause()
  }

  list(
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
    coefficients_df = coefficients_df,
    r_squared     = r_squared,
    rse           = rse
  )
}
