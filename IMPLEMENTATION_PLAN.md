# Implementation Plan: basic_ml_for_lscm

Based on PRD.md. This document defines the file creation order, dependencies between files, pseudocode for non-trivial logic, and naming conventions.

---

## Naming Conventions

### Functions
- Exported functions: `ml_workflow`, `ml_run`, `export_xlsx`
- S3 methods: `print.ml_result`, `plot.ml_result`
- Internal step functions: `step1_collect`, `step2_prepare`, `step3_train`, `step4_evaluate`, `step5_test`
- Internal helpers: prefixed with `.` (e.g., `.ask`, `.ask_yn`, `.menu`, `.validate_columns`)

### Parameters
- `file_path` — path to xlsx file (used in `ml_workflow`, `ml_run`)
- `outcome` — name of outcome column (character)
- `predictors` — names of predictor columns (character vector)
- `categorical` — names of categorical predictor columns (character vector or NULL)
- `factor_levels` — named list of character vectors, one per categorical variable (or NULL)
- `split_ratio` — numeric between 0 and 1 (default 0.8)
- `data` — the working dataframe (passed between internal steps)
- `train_set`, `test_set` — partitioned dataframes
- `model` — the `lm` object

### S3 Class
- Class name: `"ml_result"`
- Constructor: `new_ml_result(...)` (internal, not exported)

---

## File Creation Order

Files are listed in dependency order. Each phase must be complete before the next begins.

### Phase A: Package Scaffolding (no R logic)

| Order | File | Purpose | Dependencies |
|-------|------|---------|-------------|
| A1 | `DESCRIPTION` | Package metadata, imports, suggests | None |
| A2 | `LICENSE` | MIT license in DCF format | None |
| A3 | `NAMESPACE` | Placeholder (roxygen2 regenerates) | None |
| A4 | `.Rbuildignore` | Exclude non-package files from build | None |
| A5 | `.gitignore` | Standard R gitignore | None |
| A6 | `tests/testthat.R` | Test runner boilerplate | A1 |

### Phase B: Utilities and S3 Class (foundation layer)

| Order | File | Purpose | Dependencies |
|-------|------|---------|-------------|
| B1 | `R/utils.R` | Shared helpers for console interaction and validation | A1 |
| B2 | `R/ml_result.R` | S3 class constructor, print method, plot method | B1 |

### Phase C: Step Functions (core logic, one file per step)

| Order | File | Purpose | Dependencies |
|-------|------|---------|-------------|
| C1 | `R/step1_collect.R` | Read xlsx, identify variables, convert factors | B1 |
| C2 | `R/step2_prepare.R` | Missing data, plots, correlation, train/test split | B1, C1 |
| C3 | `R/step3_train.R` | Build lm formula, train model, print interpretation | B1, C2 |
| C4 | `R/step4_evaluate.R` | VIF check, variable removal/addition, re-train loop | B1, C3 |
| C5 | `R/step5_test.R` | Predict, compute MAD/MSE, actual vs predicted plot | B1, C4 |

### Phase D: Exported Entry Points

| Order | File | Purpose | Dependencies |
|-------|------|---------|-------------|
| D1 | `R/ml_workflow.R` | Interactive entry point, chains steps C1–C5 | C1–C5, B2 |
| D2 | `R/ml_run.R` | Single-shot entry point, calls steps non-interactively | C1–C5, B2 |
| D3 | `R/export_xlsx.R` | Excel export with openxlsx | B2 |

### Phase E: Tests

| Order | File | Purpose | Dependencies |
|-------|------|---------|-------------|
| E1 | `tests/testthat/test_utils.R` | Test input validation helpers | B1 |
| E2 | `tests/testthat/test_steps.R` | Test each step function non-interactively | C1–C5 |
| E3 | `tests/testthat/test_ml_run.R` | Integration test via ml_run | D2 |
| E4 | `tests/testthat/test_ml_result.R` | Test print and plot methods | B2 |
| E5 | `tests/testthat/test_export.R` | Test export_xlsx output | D3 |

### Phase F: Documentation and AI Integration

| Order | File | Purpose | Dependencies |
|-------|------|---------|-------------|
| F1 | `README.md` | Installation, quick start, function reference | D1–D3 |
| F2 | `AI_ASSISTANT_SYSTEM_PROMPT.md` | Coding Brutus system prompt | D1–D3, F1 |

### Phase G: Build, Check, Ship

| Order | Task | Dependencies |
|-------|------|-------------|
| G1 | `devtools::document()` | All R/ files |
| G2 | `devtools::test()` | All test files |
| G3 | `devtools::check()` | G1, G2 |
| G4 | Manual test: `install_github()` from clean session | G3 |
| G5 | Git push to GitHub | G4 |

---

## Pseudocode

### B1: `R/utils.R` — Console Interaction Helpers

```
.ask(prompt)
  # Wraps readline(). Prints prompt via cat(), reads one line, trims whitespace.
  # Returns the trimmed string.

.ask_yn(prompt)
  # Calls .ask() with prompt. Accepts "y", "yes", "n", "no" (case-insensitive).
  # Loops until valid input. Returns TRUE for yes, FALSE for no.

.menu(title, choices)
  # Prints title, then numbered choices. Calls .ask("Enter your choice:").
  # Validates input is a valid number. Loops until valid. Returns integer.

.parse_comma_list(input)
  # Splits a comma-separated string into a trimmed character vector.
  # e.g., "temperature, humidity, windspeed" -> c("temperature", "humidity", "windspeed")

.validate_columns(selected, available)
  # Checks that every name in 'selected' exists in 'available'.
  # Returns list(valid = TRUE/FALSE, bad = character vector of invalid names).

.print_header(text)
  # Prints "=== text ===" with blank lines above and below.

.print_subheader(text)
  # Prints "--- text ---" with a blank line below.

.pause()
  # Prints "Press Enter to continue..." and waits for readline().
```

### B2: `R/ml_result.R` — S3 Class

```
new_ml_result(data, outcome, predictors, categorical, factor_levels,
              train_set, test_set, split_ratio,
              model, model_summary, vif,
              predictions, mad, mse, r_squared, rse, coefficients)
  # Constructs a list with all fields.
  # Sets class to "ml_result".
  # Returns the object.

print.ml_result(x, ...)
  # Prints formatted summary per PRD Section 4.
  # Uses cat() throughout, no print().
  # Returns invisible(x).

plot.ml_result(x, ...)
  # Saves old par, sets par(mfrow = c(1, 2)).
  # Left panel: ggplot2 actual vs predicted with geom_abline.
  #   — But since we're in a 2-panel base layout, use base plot for both:
  #   — plot(x$predictions$Actual, x$predictions$Predicted) with abline(0,1)
  #   — Title: "Actual vs Predicted"
  # Right panel: residuals plot
  #   — residuals = Actual - Predicted
  #   — plot(x$predictions$Predicted, residuals) with abline(h=0)
  #   — Title: "Residuals vs Predicted"
  # Restores par via on.exit().
  # Returns invisible(x).
  #
  # NOTE: The ggplot2 actual-vs-predicted in Step 5 is shown during the
  # interactive flow. The plot.ml_result method uses base R for the 2-panel
  # layout so both panels render together without grid complexity.
```

### C1: `R/step1_collect.R` — Collect Data

```
step1_collect(file_path, interactive = TRUE)
  # --- Input validation ---
  # Check file_path ends with .xlsx or .xls
  # Check file exists on disk

  # --- Read data ---
  # data <- readxl::read_excel(file_path)

  # --- Display info ---
  # Print number of observations and columns.
  # Print each column name with its class (numeric, character, etc.)

  IF interactive:
    # --- Outcome variable ---
    # Ask student to enter outcome column name.
    # Validate it exists. Loop until valid.

    # --- Categorical variables ---
    # Ask y/n if any categorical predictors.
    # If yes:
    #   Ask for column names (comma-separated). Validate each exists.
    #   For each categorical column:
    #     Ask for level names (comma-separated).
    #     First level = reference.
    #     Convert column to factor with those levels.

    # --- Predictor variables ---
    # Display remaining columns (exclude outcome).
    # Ask student to enter predictor names (comma-separated).
    # Validate each exists and is not the outcome.
    # If any categorical columns were declared, ensure they're included
    # in predictors (warn if not).

    # --- Summary ---
    # Print confirmation of outcome, predictors (continuous vs categorical),
    # and observation count.
    # Pause.

  ELSE (non-interactive, called by ml_run):
    # outcome, predictors, categorical, factor_levels passed as arguments.
    # Validate and convert factors silently.

  RETURN list(data, outcome, predictors, categorical, factor_levels)
```

### C2: `R/step2_prepare.R` — Prepare Data

```
step2_prepare(collect_result, interactive = TRUE, split_ratio = 0.8)
  # Unpack collect_result into data, outcome, predictors, categorical.

  # Track completion of sub-tasks:
  # split_done <- FALSE

  IF interactive:
    LOOP until student selects [6] (continue):
      # Display menu: [1] Missing data, [2] Scatter plots, [3] Box plots,
      #               [4] Correlation matrix, [5] Train/test split, [6] Continue

      choice <- .menu(...)

      SWITCH choice:
        1: # --- Missing data check ---
           # has_na <- any(is.na(data))
           # If TRUE:
           #   Print which columns have NAs and count per column.
           #   Ask y/n to remove rows with NAs.
           #   If yes: data <- na.omit(data). Print new row count.
           # If FALSE: print "No missing data found."

        2: # --- Scatter plots (continuous predictors only) ---
           # continuous_preds <- setdiff(predictors, categorical)
           # For each continuous predictor:
           #   plot(data[[predictor]], data[[outcome]],
           #        xlab = predictor, ylab = outcome,
           #        main = paste("Impact of", predictor, "on", outcome))
           #   .pause() between plots

        3: # --- Box plots (categorical predictors only) ---
           # If no categorical predictors: print "No categorical predictors declared."
           # For each categorical predictor:
           #   boxplot(data[[outcome]] ~ data[[predictor]],
           #           xlab = predictor, ylab = outcome,
           #           main = paste(outcome, "by", predictor))
           #   .pause() between plots

        4: # --- Correlation matrix ---
           # Select outcome + continuous predictors only.
           # cor_data <- data[, c(continuous_preds, outcome)]
           # corrplot::corrplot(cor(cor_data), type = "lower", method = "number",
           #                    tl.cex = 0.8, number.cex = 0.8)
           # Print interpretation guidance text.

        5: # --- Train/test split ---
           # Ask y/n for 80/20 default.
           # If no: ask for custom percentage.
           # set.seed(4321)
           # split <- caTools::sample.split(data[[outcome]], SplitRatio = split_ratio)
           # train_set <- subset(data, split == TRUE)
           # test_set <- subset(data, split == FALSE)
           # Print row counts for train and test.
           # split_done <- TRUE

        6: # --- Continue ---
           # If NOT split_done:
           #   Print "You haven't split the data yet. Please complete task [5] first."
           #   Continue loop.
           # Else: break loop.

  ELSE (non-interactive):
    # Check for NAs silently (don't remove, just warn).
    # Do the split with the provided split_ratio.
    # No plots, no menus.

  RETURN list(data, train_set, test_set, split_ratio, outcome, predictors,
              categorical, factor_levels)
```

### C3: `R/step3_train.R` — Train Model

```
step3_train(prepare_result, interactive = TRUE)
  # Unpack prepare_result.

  IF interactive:
    # Print current predictor list.
    # Ask "Ready to train the model with these predictors? (y/n)"
    # If no: ask "Would you like to change your predictors? (y/n)"
    #   If yes: re-prompt for predictor selection (same logic as step1).
    #   Update predictors.

  # --- Build formula ---
  # formula_str <- paste(outcome, "~", paste(predictors, collapse = " + "))
  # formula_obj <- as.formula(formula_str)

  # --- Train ---
  # model <- lm(formula_obj, data = train_set)
  # model_summary <- summary(model)

  # --- Extract results ---
  # coefficients_df <- data.frame(
  #   Variable = rownames(model_summary$coefficients),
  #   Estimate = model_summary$coefficients[, "Estimate"],
  #   Std.Error = model_summary$coefficients[, "Std. Error"],
  #   t.value = model_summary$coefficients[, "t value"],
  #   p.value = model_summary$coefficients[, "Pr(>|t|)"]
  # )
  # r_squared <- model_summary$r.squared
  # rse <- model_summary$sigma
  # f_stat <- model_summary$fstatistic
  # f_pvalue <- pf(f_stat[1], f_stat[2], f_stat[3], lower.tail = FALSE)

  IF interactive:
    # --- Print interpretations ---
    # .print_subheader("Coefficients")
    # Print coefficients table.
    #
    # For each predictor row (skip intercept):
    #   name <- row variable name
    #   beta <- estimate
    #   pval <- p.value
    #
    #   Determine if this is a categorical level:
    #     Check if name starts with any categorical variable name.
    #     e.g., "MembershipTypeStandard" starts with "MembershipType"
    #
    #   If categorical level:
    #     Extract the level name (strip the factor prefix).
    #     Find the reference level from factor_levels.
    #     cat("  [name]: [level] is associated with a [beta] difference in
    #          [outcome] compared to [ref_level].")
    #     If pval < 0.05: cat("  (Statistically significant)")
    #     Else: cat("  (Not statistically significant — interpret with caution)")
    #
    #   If continuous:
    #     cat("  [name]: A 1-unit increase in [name] is associated with
    #          a [beta] change in [outcome].")
    #     If pval < 0.05: cat("  (Statistically significant)")
    #     Else: cat("  (Not statistically significant — interpret with caution)")
    #
    # .print_subheader("Model Fit")
    # Print RSE interpretation.
    # Print R-squared interpretation.
    # Print F-stat p-value interpretation.
    # (All per PRD wording.)

  RETURN list(model, model_summary, coefficients_df, r_squared, rse,
              train_set, test_set, split_ratio, outcome, predictors,
              categorical, factor_levels, data)
```

### C4: `R/step4_evaluate.R` — Evaluate Model

```
step4_evaluate(train_result, interactive = TRUE)
  # Unpack train_result.
  # vif_done <- FALSE

  IF interactive:
    LOOP until student selects [3] (continue):
      # Display menu: [1] VIF, [2] Improve model, [3] Continue
      choice <- .menu(...)

      SWITCH choice:
        1: # --- VIF ---
           # If only 1 predictor: print "VIF requires at least 2 predictors. Skipping."
           # Else:
           #   vif_raw <- car::vif(model)
           #   Detect if result is matrix (categorical present) or named vector.
           #
           #   If matrix (has GVIF column):
           #     vif_df <- data.frame(
           #       Variable = rownames(vif_raw),
           #       GVIF = vif_raw[, "GVIF"],
           #       Df = vif_raw[, "Df"],
           #       GVIF_adjusted = vif_raw[, "GVIF^(1/(2*Df))"]
           #     )
           #     Print table. Flag rows where GVIF_adjusted > 5.
           #   Else (named vector):
           #     vif_df <- data.frame(Variable = names(vif_raw), VIF = vif_raw)
           #     Print table. Flag rows where VIF > 5.
           #
           #   Print interpretation text.
           #   vif_done <- TRUE

        2: # --- Improve model ---
           # Print current predictors with p-values and VIF (if computed).
           #
           # --- Remove variable loop ---
           # LOOP:
           #   Ask "Would you like to remove a variable? (y/n)"
           #   If no: break.
           #   Ask "Which variable?" Validate.
           #   Remove from predictors list.
           #   Re-build formula, re-train model, re-summarize.
           #   Print updated coefficients and fit stats.
           #   Ask "Would you like to remove another variable? (y/n)"
           #
           # --- Interaction term ---
           # Ask "Would you like to add an interaction term? (y/n)"
           # If yes:
           #   Ask "Enter the two variable names separated by * :"
           #   Parse into var1 and var2. Validate both exist.
           #   Add interaction to formula: "var1:var2" appended.
           #   Re-train, re-summarize, print.
           #
           # Print fishing expedition warning.

        3: # --- Continue ---
           # Proceed to Step 5.

  ELSE (non-interactive):
    # Compute VIF silently.
    # No removal/interaction (ml_run doesn't modify variables).

  RETURN list(model, model_summary, coefficients_df, r_squared, rse, vif_df,
              train_set, test_set, split_ratio, outcome, predictors,
              categorical, factor_levels, data)
```

### C5: `R/step5_test.R` — Test Model

```
step5_test(evaluate_result, interactive = TRUE)
  # Unpack evaluate_result.

  # --- Predict ---
  # predicted <- predict(model, newdata = test_set)
  # predictions <- data.frame(
  #   Actual = test_set[[outcome]],
  #   Predicted = predicted,
  #   Error = test_set[[outcome]] - predicted,
  #   Absolute_Error = abs(test_set[[outcome]] - predicted)
  # )

  # --- Accuracy metrics ---
  # mad_val <- mean(predictions$Absolute_Error)
  # mse_val <- mean(predictions$Error^2)

  IF interactive:
    # .print_header("Step 5: Test the Model")
    # Print MAD with interpretation.
    # Print MSE with interpretation.
    #
    # --- Actual vs Predicted plot ---
    # ggplot(predictions, aes(x = Actual, y = Predicted)) +
    #   geom_point() +
    #   geom_abline(color = "red") +
    #   labs(title = "Actual vs Predicted",
    #        x = paste("Actual", outcome),
    #        y = paste("Predicted", outcome))
    # print(gg)  # required to render ggplot in function context
    #
    # --- Export prompt ---
    # Ask "Would you like to export all results to an Excel file? (y/n)"
    # If yes:
    #   Ask "Enter file name (e.g., results.xlsx):"
    #   Call export_xlsx(result, file_name)

  # --- Build ml_result ---
  # result <- new_ml_result(
  #   data, outcome, predictors, categorical, factor_levels,
  #   train_set, test_set, split_ratio,
  #   model, model_summary, vif_df,
  #   predictions, mad_val, mse_val, r_squared, rse, coefficients_df
  # )

  RETURN result
```

### D1: `R/ml_workflow.R` — Interactive Entry Point

```
ml_workflow(file_path)
  # .print_header("Supervised ML Regression Workflow")
  # Print welcome message explaining the 5 steps.

  # Step 1
  collect <- step1_collect(file_path, interactive = TRUE)

  # Step 2
  prepare <- step2_prepare(collect, interactive = TRUE)

  # Step 3
  train <- step3_train(prepare, interactive = TRUE)

  # Step 4
  evaluate <- step4_evaluate(train, interactive = TRUE)

  # Step 5
  result <- step5_test(evaluate, interactive = TRUE)

  # Print completion message.
  # cat("\nWorkflow complete! Your results are stored in the returned object.")
  # cat("\nUse print(result) to see a summary, plot(result) for visuals,")
  # cat("\nor export_xlsx(result, 'file.xlsx') to export to Excel.\n")

  RETURN result (invisible)
```

### D2: `R/ml_run.R` — Single-Shot Entry Point

```
ml_run(file_path, outcome, predictors, categorical = NULL,
       factor_levels = NULL, split_ratio = 0.8)

  # --- Input validation ---
  # Validate all parameters are correct types.

  # --- Warning ---
  # Print warning text from PRD.
  # Ask "Type 'yes' to proceed:"
  # If not "yes": stop("Aborted.") or return NULL.

  # --- Execute steps non-interactively ---
  # collect <- step1_collect(file_path, interactive = FALSE,
  #              outcome = outcome, predictors = predictors,
  #              categorical = categorical, factor_levels = factor_levels)
  # prepare <- step2_prepare(collect, interactive = FALSE, split_ratio = split_ratio)
  #   Print: "Step 2 complete. Train: N rows, Test: N rows."
  # train <- step3_train(prepare, interactive = FALSE)
  #   Print: "Step 3 complete. R-squared: X, RSE: X"
  # evaluate <- step4_evaluate(train, interactive = FALSE)
  #   Print: "Step 4 complete. Max VIF: X"
  # result <- step5_test(evaluate, interactive = FALSE)
  #   Print: "Step 5 complete. MAD: X, MSE: X"

  # Print completion message.
  RETURN result (invisible)
```

### D3: `R/export_xlsx.R` — Excel Export

```
export_xlsx(x, file)
  # --- Validate ---
  # if (!inherits(x, "ml_result")) stop(...)
  # if (!requireNamespace("openxlsx", quietly = TRUE))
  #   stop("Package 'openxlsx' is required. Install with: install.packages('openxlsx')")

  # --- Build workbook ---
  # wb <- openxlsx::createWorkbook()
  #
  # Tab 1: "Coefficients"
  #   openxlsx::addWorksheet(wb, "Coefficients")
  #   openxlsx::writeData(wb, "Coefficients", x$coefficients)
  #
  # Tab 2: "Model Fit"
  #   fit_df <- data.frame(
  #     RSE = x$rse,
  #     R_squared = x$r_squared,
  #     Adj_R_squared = summary(x$model)$adj.r.squared,
  #     F_statistic = summary(x$model)$fstatistic[1],
  #     F_pvalue = pf(...)
  #   )
  #   openxlsx::addWorksheet(wb, "Model Fit")
  #   openxlsx::writeData(wb, "Model Fit", fit_df)
  #
  # Tab 3: "VIF"
  #   openxlsx::addWorksheet(wb, "VIF")
  #   openxlsx::writeData(wb, "VIF", x$vif)
  #
  # Tab 4: "Predictions"
  #   openxlsx::addWorksheet(wb, "Predictions")
  #   openxlsx::writeData(wb, "Predictions", x$predictions)
  #
  # Tab 5: "Accuracy"
  #   acc_df <- data.frame(MAD = x$mad, MSE = x$mse)
  #   openxlsx::addWorksheet(wb, "Accuracy")
  #   openxlsx::writeData(wb, "Accuracy", acc_df)
  #
  # openxlsx::saveWorkbook(wb, file, overwrite = TRUE)

  # cat("Results exported to:", file, "\n")
  RETURN invisible(file)
```

---

## Test Strategy

### What gets tested automatically (via `devtools::test()`)

All tests use the test case xlsx files from the course. Tests call internal step functions with `interactive = FALSE` or use `ml_run()` directly.

| Test File | What It Covers |
|-----------|---------------|
| `test_utils.R` | `.parse_comma_list()` returns correct vector; `.validate_columns()` catches bad names; edge cases (extra spaces, empty input) |
| `test_steps.R` | `step1_collect()` reads xlsx and returns correct structure; `step2_prepare()` splits data at correct ratio; `step3_train()` returns valid lm object; `step4_evaluate()` returns VIF dataframe; `step5_test()` returns predictions with correct dimensions |
| `test_ml_run.R` | Full integration: `ml_run()` on Test Case 1 (stockouts) returns negative ReorderPoint coefficient; `ml_run()` on Test Case 5 (shipping) returns GVIF matrix; all result fields are populated and non-NULL |
| `test_ml_result.R` | `print.ml_result()` returns `invisible(x)`; `plot.ml_result()` runs without error |
| `test_export.R` | `export_xlsx()` creates file with 5 tabs; tab names match spec; errors on non-ml_result input; `skip_if_not_installed("openxlsx")` |

### What gets tested manually

- `ml_workflow()` — full interactive walkthrough with each of the 5 test case datasets
- VIF improvement loop — remove a variable, verify re-training works
- Interaction term — add one, verify model updates
- Edge cases: file not found, misspelled column names, selecting 0 predictors
- `install_github()` from clean R session

### Test data file handling

Tests need access to the xlsx files. Options:
- Place test copies in `tests/testthat/testdata/`
- Use `testthat::test_path("testdata", "bikes.xlsx")` to reference them
- Add `tests/testthat/testdata/` to `.Rbuildignore` to keep package size down
- Use only the smallest dataset (stockouts) for automated tests to keep test time fast; use larger datasets for manual testing only

---

## Key Design Decisions

### 1. Interactive vs non-interactive flag

Every step function accepts `interactive = TRUE/FALSE`. When `interactive = TRUE`, the function uses `readline()` for input and `cat()` for output. When `FALSE`, it accepts parameters directly and prints minimal status messages. This allows `ml_workflow()` to be interactive while `ml_run()` and tests call the same logic non-interactively.

### 2. State passing between steps

Each step function returns a list containing everything the next step needs. This avoids global state or environments. The chain is:

```
collect_result -> step2_prepare -> prepare_result -> step3_train -> train_result
  -> step4_evaluate -> evaluate_result -> step5_test -> ml_result
```

Each result is a superset of the previous (carries forward all fields plus new ones).

### 3. Formula construction

The `lm()` formula is built as a string then converted with `as.formula()`. This makes it easy to add/remove predictors and interaction terms dynamically:

```r
formula_str <- paste(outcome, "~", paste(predictors, collapse = " + "))
# With interaction:
formula_str <- paste(formula_str, "+", paste(var1, var2, sep = ":"))
```

### 4. VIF output format detection

`car::vif()` returns a named numeric vector when all predictors are continuous, but a matrix with GVIF/Df/GVIF^(1/(2*Df)) columns when factors are present. The code checks `is.matrix(vif_raw)` to determine which format to display.

### 5. Plot rendering in function context

`ggplot2` plots don't render automatically inside functions — they require an explicit `print()` call. The Step 5 actual-vs-predicted plot uses `print(gg)`. The `plot.ml_result()` method uses base R for the 2-panel layout to avoid ggplot2/grid complexity.

### 6. readline() only works interactively

`readline()` does not work in non-interactive R sessions (e.g., R CMD check, Rscript). All `readline()` calls are gated behind the `interactive` flag. Tests never invoke interactive mode.

---

## Estimated Complexity by File

| File | Lines (est.) | Complexity |
|------|-------------|-----------|
| `utils.R` | 60–80 | Low — simple wrappers |
| `ml_result.R` | 80–100 | Low — constructor + formatted printing |
| `step1_collect.R` | 100–130 | Medium — input validation loops |
| `step2_prepare.R` | 150–180 | Medium — menu loop with 5 sub-tasks |
| `step3_train.R` | 120–150 | Medium — interpretation text generation |
| `step4_evaluate.R` | 140–170 | High — VIF format detection + improvement loop |
| `step5_test.R` | 80–100 | Low — predict, compute, plot |
| `ml_workflow.R` | 30–40 | Low — chains step calls |
| `ml_run.R` | 60–80 | Low — validation + step calls |
| `export_xlsx.R` | 50–70 | Low — workbook assembly |
| **Total R code** | **~900–1100** | |
