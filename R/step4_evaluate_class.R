#' Step 4 (Classification): Evaluate the Model
#'
#' Checks for multicollinearity (VIF) and provides an improvement loop
#' for removing variables or adding interactions (classification version).
#'
#' @param train_result List returned by step3_train_class().
#' @param interactive Logical. If TRUE, shows menus.
#'
#' @return A list extending train_result with: vif_df.
#'
#' @importFrom car vif
#' @noRd
step4_evaluate_class <- function(train_result, interactive = TRUE) {

  data            <- train_result$data
  outcome         <- train_result$outcome
  positive_class  <- train_result$positive_class
  predictors      <- train_result$predictors
  categorical     <- train_result$categorical
  factor_levels   <- train_result$factor_levels
  train_set       <- train_result$train_set
  test_set        <- train_result$test_set
  split_ratio     <- train_result$split_ratio
  model           <- train_result$model
  model_summary   <- train_result$model_summary
  coefficients_df <- train_result$coefficients_df

  vif_df <- NULL

  # --- Compute VIF (shared logic) ---
  compute_vif <- function(mdl) {
    if (length(attr(mdl$terms, "term.labels")) < 2) return(NULL)
    vif_raw <- car::vif(mdl)
    if (is.matrix(vif_raw)) {
      data.frame(
        Variable       = rownames(vif_raw),
        GVIF           = round(vif_raw[, "GVIF"], 2),
        Df             = vif_raw[, "Df"],
        GVIF_adjusted  = round(vif_raw[, "GVIF^(1/(2*Df))"], 2),
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

  # --- Retrain helper (glm) ---
  retrain_model <- function(preds, trn) {
    fstr <- paste(.bt(outcome), "~", paste(.bt(preds), collapse = " + "))
    stats::glm(stats::as.formula(fstr), data = trn, family = stats::binomial)
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

        .lcat("\nP-values:\n")
        for (i in seq_len(nrow(coefficients_df))) {
          if (coefficients_df$Variable[i] == "(Intercept)") next
          .lcat("  ", coefficients_df$Variable[i], ": ",
              round(coefficients_df$p.value[i], 2), "\n", sep = "")
        }

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
            Variable    = rownames(model_summary$coefficients),
            Estimate    = model_summary$coefficients[, "Estimate"],
            Std.Error   = model_summary$coefficients[, "Std. Error"],
            z.value     = model_summary$coefficients[, "z value"],
            p.value     = model_summary$coefficients[, "Pr(>|z|)"],
            Odds_Ratio  = exp(model_summary$coefficients[, "Estimate"]),
            stringsAsFactors = FALSE
          )
          rownames(coefficients_df) <- NULL

          display_df <- coefficients_df
          display_df$Estimate <- round(display_df$Estimate, 2)
          display_df$Std.Error <- round(display_df$Std.Error, 2)
          display_df$z.value <- round(display_df$z.value, 2)
          display_df$p.value <- round(display_df$p.value, 2)
          display_df$Odds_Ratio <- round(display_df$Odds_Ratio, 2)
          print(display_df, row.names = FALSE)
          .lcat("\nAIC: ", round(model$aic, 2), "\n", sep = "")

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
              inter_term <- paste(.bt(parts[1]), .bt(parts[2]), sep = ":")
              fstr <- paste(.bt(outcome), "~", paste(.bt(predictors), collapse = " + "), "+", inter_term)
              model <- stats::glm(stats::as.formula(fstr), data = train_set,
                                  family = stats::binomial)
              model_summary <- summary(model)
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

              .lcat("\nModel updated with interaction ", inter_input, ".\n\n", sep = "")
              display_df <- coefficients_df
              display_df$Estimate <- round(display_df$Estimate, 2)
              display_df$Std.Error <- round(display_df$Std.Error, 2)
              display_df$z.value <- round(display_df$z.value, 2)
              display_df$p.value <- round(display_df$p.value, 2)
              display_df$Odds_Ratio <- round(display_df$Odds_Ratio, 2)
              .lprint(display_df, row.names = FALSE)
              .lcat("\nAIC: ", round(model$aic, 2), "\n", sep = "")
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
    vif_df <- compute_vif(model)
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
    coefficients_df = coefficients_df,
    vif_df          = vif_df
  )
}
