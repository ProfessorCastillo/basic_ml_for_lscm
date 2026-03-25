#' Step 4: Evaluate the Model
#'
#' Checks for multicollinearity (VIF) and provides an improvement loop
#' for removing variables or adding interactions.
#'
#' @param train_result List returned by step3_train().
#' @param interactive Logical. If TRUE, shows menus.
#'
#' @return A list extending train_result with: vif_df.
#'
#' @importFrom car vif
#' @noRd
step4_evaluate <- function(train_result, interactive = TRUE) {

  data          <- train_result$data
  outcome       <- train_result$outcome
  predictors    <- train_result$predictors
  categorical   <- train_result$categorical
  factor_levels <- train_result$factor_levels
  train_set     <- train_result$train_set
  test_set      <- train_result$test_set
  split_ratio   <- train_result$split_ratio
  model         <- train_result$model
  model_summary <- train_result$model_summary
  coefficients_df <- train_result$coefficients_df
  r_squared     <- train_result$r_squared
  rse           <- train_result$rse

  vif_df <- NULL

  # --- Compute VIF (shared logic) ---
  compute_vif <- function(mdl) {
    # VIF requires at least 2 predictors
    if (length(attr(mdl$terms, "term.labels")) < 2) {
      return(NULL)
    }
    vif_raw <- car::vif(mdl)
    if (is.matrix(vif_raw)) {
      data.frame(
        Variable     = rownames(vif_raw),
        GVIF         = round(vif_raw[, "GVIF"], 2),
        Df           = vif_raw[, "Df"],
        GVIF_adjusted = round(vif_raw[, "GVIF^(1/(2*Df))"], 2),
        stringsAsFactors = FALSE
      )
    } else {
      data.frame(
        Variable = names(vif_raw),
        VIF      = round(vif_raw, 2),
        stringsAsFactors = FALSE
      )
    }
  }

  # --- Retrain helper ---
  retrain_model <- function(preds, trn) {
    fstr <- paste(outcome, "~", paste(preds, collapse = " + "))
    stats::lm(stats::as.formula(fstr), data = trn)
  }

  if (interactive) {
    .print_header("Step 4: Evaluate the Model")

    choices <- c(
      "Check for multicollinearity (VIF)",
      "Improve the model (remove/add variables)",
      "Continue to Step 5 (Test the Model)",
      "Go back to Step 3 (Train the Model)"
    )

    repeat {
      choice <- .menu("Evaluate the Model -- select a task:", choices)

      if (choice == 4L) {
        # --- Go back ---
        .lcat("\nGoing back to Step 3...\n")
        return(list(go_back = TRUE))

      } else if (choice == 1L) {
        # --- VIF ---
        vif_df <- compute_vif(model)
        if (is.null(vif_df)) {
          .lcat("\nVIF requires at least 2 predictors. Skipping.\n")
        } else {
          .lcat("\n")
          .lprint(vif_df, row.names = FALSE)

          # Flag high VIF
          if ("VIF" %in% names(vif_df)) {
            high <- vif_df$Variable[vif_df$VIF > 5]
          } else {
            high <- vif_df$Variable[vif_df$GVIF_adjusted > 5]
          }
          if (length(high) > 0) {
            .lcat("\nWARNING: The following variable(s) have VIF > 5: ",
                paste(high, collapse = ", "), "\n", sep = "")
            .lcat("This indicates problematic multicollinearity. Consider removing\n")
            .lcat("one of the highly correlated predictors in the 'Improve' step.\n")
          } else {
            .lcat("\nAll VIF values are below 5. No multicollinearity concerns.\n")
          }
        }

      } else if (choice == 2L) {
        # --- Improve model ---
        .lcat("\nCurrent predictors: ", paste(predictors, collapse = ", "), "\n", sep = "")

        # Show p-values
        .lcat("\nP-values:\n")
        for (i in seq_len(nrow(coefficients_df))) {
          if (coefficients_df$Variable[i] == "(Intercept)") next
          .lcat("  ", coefficients_df$Variable[i], ": ",
              round(coefficients_df$p.value[i], 2), "\n", sep = "")
        }

        # Show VIF if computed
        if (!is.null(vif_df)) {
          .lcat("\nVIF values:\n")
          .lprint(vif_df, row.names = FALSE)
        }

        # --- Remove variable loop ---
        repeat {
          if (!.ask_yn("\nWould you like to remove a variable?")) break

          remove_name <- .ask("Which variable would you like to remove? Enter the name: ")
          if (!remove_name %in% predictors) {
            .lcat("'", remove_name, "' is not in your current predictors. Try again.\n", sep = "")
            next
          }

          predictors <- setdiff(predictors, remove_name)
          if (!is.null(categorical)) {
            categorical <- intersect(categorical, predictors)
          }
          .lcat("Removed '", remove_name, "'. Re-training model...\n\n", sep = "")

          model <- retrain_model(predictors, train_set)
          model_summary <- summary(model)
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
          rse <- model_summary$sigma

          # Print updated summary
          display_df <- coefficients_df
          display_df$Estimate <- round(display_df$Estimate, 2)
          display_df$Std.Error <- round(display_df$Std.Error, 2)
          display_df$t.value <- round(display_df$t.value, 2)
          display_df$p.value <- round(display_df$p.value, 2)
          print(display_df, row.names = FALSE)
          .lcat("\nR-squared: ", round(r_squared, 2),
              "  |  RSE: ", round(rse, 2), "\n", sep = "")

          # Update VIF
          vif_df <- compute_vif(model)
          if (!is.null(vif_df)) {
            .lcat("\nUpdated VIF:\n")
            .lprint(vif_df, row.names = FALSE)
          }
        }

        # --- Interaction term ---
        if (.ask_yn("\nWould you like to add an interaction term?")) {
          inter_input <- .ask("Enter the two variable names separated by * (e.g., temperature*humidity): ")
          parts <- .parse_comma_list(gsub("\\*", ",", inter_input))
          if (length(parts) == 2) {
            check <- .validate_columns(parts, predictors)
            if (check$valid) {
              inter_term <- paste(parts[1], parts[2], sep = ":")
              fstr <- paste(outcome, "~", paste(predictors, collapse = " + "), "+", inter_term)
              model <- stats::lm(stats::as.formula(fstr), data = train_set)
              model_summary <- summary(model)
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
              rse <- model_summary$sigma

              .lcat("\nModel updated with interaction ", inter_input, ".\n\n", sep = "")
              display_df <- coefficients_df
              display_df$Estimate <- round(display_df$Estimate, 2)
              display_df$Std.Error <- round(display_df$Std.Error, 2)
              display_df$t.value <- round(display_df$t.value, 2)
              display_df$p.value <- round(display_df$p.value, 2)
              .lprint(display_df, row.names = FALSE)
              .lcat("\nR-squared: ", round(r_squared, 2),
                  "  |  RSE: ", round(rse, 2), "\n", sep = "")
            } else {
              .lcat("Variable(s) not found: ", paste(check$bad, collapse = ", "),
                  ". Interaction not added.\n", sep = "")
            }
          } else {
            .lcat("Could not parse interaction. Expected format: var1*var2\n")
          }
        }

        .lcat("\nReminder: Any addition or removal of variables must be justified with a\n")
        .lcat("sound, logical argument. Avoid 'fishing expeditions' -- changes should\n")
        .lcat("be grounded in business reasoning.\n")

      } else if (choice == 3L) {
        break
      }
    }

  } else {
    # --- Non-interactive: just compute VIF ---
    vif_df <- compute_vif(model)
  }

  list(
    data            = data,
    outcome         = outcome,
    predictors      = predictors,
    categorical     = categorical,
    factor_levels   = factor_levels,
    train_set       = train_set,
    test_set        = test_set,
    split_ratio     = split_ratio,
    model           = model,
    model_summary   = model_summary,
    coefficients_df = coefficients_df,
    r_squared       = r_squared,
    rse             = rse,
    vif_df          = vif_df
  )
}
