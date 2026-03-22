# PRD: basic_ml_for_lscm

## Product Requirements Document

**Package name:** basic_ml_for_lscm
**Author:** Vince Castillo (castillo.230@osu.edu)
**License:** MIT
**GitHub:** ProfessorCastillo/basic-ml-for-lscm-R
**Course:** BUSML 4382 — Logistics and Supply Chain Analytics, The Ohio State University
**Semester:** Spring 2026

---

## 1. Purpose

An interactive, teaching-oriented R package that guides business students through the 5-step supervised machine learning regression workflow using linear regression. Students learn by doing — the package runs inside the R console, presents menus at each step, and asks students to make analytical decisions (which variables to include, whether to remove a predictor, etc.) based on their own data.

**Who it's for:** Undergraduate business students with no prior coding experience. They use RStudio and receive guidance from an AI assistant ("Coding Brutus") whose system prompt is kept in sync with this package.

**What problem it solves:** Students currently copy-paste from long R scripts that are hard to adapt to new datasets. This package replaces that workflow with an interactive, menu-driven experience that teaches the 5-step ML process while producing publishable results (Excel workbook, plots).

---

## 2. Design Philosophy

- **Interactive and pedagogical.** Inspired by `swirl`. The package prints instructions, asks questions via `readline()`, and waits for student input at every decision point.
- **Students load their own data.** The package does not ship datasets. Students pass a file path to an `.xlsx` file; the package reads it and stores it as a dataframe internally.
- **Two modes:**
  - `ml_workflow()` — the guided, step-by-step interactive mode (recommended)
  - `ml_run()` — a single-shot mode that executes all steps at once; prints a warning that this skips inspection and should only be used by students confident in the material
- **Decisions belong to the student.** The package never auto-selects variables. It presents options and asks the student to choose.
- **Consistent with Coding Brutus.** The AI assistant system prompt references the same function names, parameter names, and output formats as this package.

---

## 3. The 5-Step ML Workflow

The interactive flow follows the 5-step process taught in lectures L12–L14:

### Step 1: Collect Data

**What the package does:**
1. Reads the student's `.xlsx` file into a dataframe.
2. Prints the first few rows and column names with types.
3. Asks: "Which column is your outcome variable (Y)?"
   - Student enters column name.
4. Asks: "Do you have any categorical predictor variables? (y/n)"
   - If yes: "Which column(s) are categorical? Enter name(s) separated by commas."
   - For each categorical column: "What are the level names for [column]? Enter them separated by commas (the first one listed becomes the reference level)."
   - Converts those columns to factors with the specified levels.
5. Asks: "Which columns are your predictor variables (X)? Enter name(s) separated by commas."
   - Student selects from available columns (outcome column excluded from display).
6. Prints a summary confirming: outcome variable, predictor variables (continuous and categorical), and total observations.

**Student decisions:** outcome variable, categorical columns and their levels, predictor variables.

### Step 2: Prepare the Data

Sub-tasks presented as a checklist menu:

```
Prepare the Data — select a task:
  [1] Check for missing data
  [2] Create scatter plots (continuous predictors)
  [3] Create box plots (categorical predictors)
  [4] Create correlation matrix (continuous variables)
  [5] Split into training and testing sets
  [6] Continue to Step 3 (Train the Model)
```

**[1] Check for missing data**
- Runs `any(is.na(data))` and reports result.
- If TRUE: reports which columns have NAs and how many. Asks: "Would you like to remove rows with missing data? (y/n)"
- If FALSE: prints "No missing data found. You're good to proceed."

**[2] Create scatter plots**
- For each continuous predictor, plots it against the outcome variable using base R `plot()`.
- Labels axes with variable names and units (if known) and adds a descriptive title.
- After each plot, pauses and asks: "Press Enter to see the next plot."

**[3] Create box plots**
- Only available if categorical predictors were declared in Step 1.
- For each categorical predictor, creates a `boxplot()` of outcome ~ category.

**[4] Create correlation matrix**
- Selects only continuous variables (outcome + continuous predictors).
- Displays `corrplot::corrplot()` with `type='lower', method='number'`.
- Prints interpretation guidance: "Look for predictors with strong correlations to your outcome (closer to +1 or -1). Also watch for predictors that are highly correlated with each other — this may cause multicollinearity issues in Step 4."

**[5] Split into training and testing sets**
- Default: 80% training / 20% testing. Seed: `4321`.
- Asks: "The recommended split is 80% training / 20% testing. Would you like to use this? (y/n)"
  - If no: "Enter your training percentage (e.g., 70 for 70%):"
- Uses `caTools::sample.split()` with `set.seed(4321)`.
- Prints number of rows in training and testing sets.
- Stores both sets internally.

**[6] Continue**
- Validates that the train/test split has been completed (required before proceeding).
- If not done, prompts: "You haven't split the data yet. Please complete task [5] first."

### Step 3: Train the Model

**What the package does:**
1. Confirms the predictor variables the student selected in Step 1.
2. Asks: "Ready to train the model with these predictors? (y/n)"
   - If no: "Would you like to change your predictors? (y/n)" — allows re-selection.
3. Runs `lm()` on the training set with the selected formula.
4. Captures `summary()` output.
5. Prints and explains key results:
   - Coefficient estimates with p-values
   - Interpretation guidance for continuous predictors: "A 1-unit increase in [X] is associated with a [beta] change in [Y]."
   - Interpretation guidance for categorical predictors: "[LevelName] is associated with a [beta] difference in [Y] compared to the reference level [RefLevel]."
   - Residual Standard Error (RSE) with interpretation: "RSE = [value]. This means your predictions will typically be off by about +/- [value] [units of Y]. A smaller RSE means more precise predictions."
   - Multiple R-squared with interpretation: "R-squared = [value]. This means [value*100]% of the variation in [Y] is explained by your predictors. The closer to 1 (100%), the better your model fits the data. The remaining [100 - value*100]% is unexplained — it could be random noise or factors you haven't included."
   - F-statistic and its p-value with interpretation: "F-statistic p-value = [value]. This tells you whether your model as a whole is statistically significant. If this value is less than 0.05, you can be at least 95% confident that your predictors, taken together, have a real relationship with [Y]. If it's greater than 0.05, the model may not be reliable."
6. Stores the model object internally.

### Step 4: Evaluate the Model

Sub-tasks presented as a checklist menu:

```
Evaluate the Model — select a task:
  [1] Check for multicollinearity (VIF)
  [2] Improve the model (remove/add variables)
  [3] Continue to Step 5 (Test the Model)
```

**[1] Check for multicollinearity (VIF)**
- Runs `car::vif()` on the trained model.
- If only continuous predictors: displays standard VIF values.
- If categorical predictors present: displays GVIF^(1/(2*Df)) values.
- Prints interpretation: "VIF values > 5 indicate problematic multicollinearity. Consider removing one of the highly correlated predictors."
- Flags any variables with VIF > 5.

**[2] Improve the model**
- Lists current predictors with their p-values and VIF values.
- Asks: "Would you like to remove a variable? (y/n)"
  - If yes: "Which variable would you like to remove?" — student enters name.
  - Re-trains the model (loops back to Step 3 logic internally).
  - Prints updated summary for comparison.
  - Asks: "Would you like to remove another variable? (y/n)"
- Asks: "Would you like to add an interaction term? (y/n)"
  - If yes: "Enter the two variable names separated by * (e.g., temperature*humidity):"
  - Re-trains with the interaction.
  - Prints updated summary.
- Prints reminder: "Any addition or removal of variables must be justified with a sound, logical argument. Avoid 'fishing expeditions' — changes should be grounded in business reasoning."

**[3] Continue**
- Proceeds to Step 5.

### Step 5: Test the Model

**What the package does:**
1. Runs `predict()` on the test set using the trained model.
2. Creates a dataframe of Actual vs. Predicted values.
3. Computes:
   - **MAD** (Mean Absolute Deviation): `mean(abs(actual - predicted))`
   - **MSE** (Mean Squared Error): `mean((actual - predicted)^2)`
4. Prints results with interpretation:
   - "MAD = [value]: On average, predictions are off by [value] units of [Y]."
   - "MSE = [value]: Larger errors are penalized more heavily."
5. Creates an Actual vs. Predicted scatter plot using `ggplot2` with a 45-degree reference line.
6. Asks: "Would you like to export all results to an Excel file? (y/n)"
   - If yes: calls the export function (see Section 5).

---

## 4. Function Specifications

### `ml_workflow(file_path)`

**The primary interactive function.**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `file_path` | character | Yes | Path to the student's `.xlsx` data file |

**Returns:** An S3 object of class `"ml_result"` containing:
- `$data` — the full original dataframe
- `$outcome` — name of outcome variable (character)
- `$predictors` — names of predictor variables (character vector)
- `$categorical` — names of categorical predictors (character vector, or NULL)
- `$factor_levels` — named list of factor levels per categorical variable (or NULL)
- `$train_set` — training dataframe
- `$test_set` — testing dataframe
- `$split_ratio` — numeric (e.g., 0.8)
- `$model` — the `lm` object from the final trained model
- `$model_summary` — output of `summary()` on the model
- `$vif` — VIF/GVIF values (dataframe)
- `$predictions` — dataframe with Actual and Predicted columns
- `$mad` — numeric
- `$mse` — numeric
- `$r_squared` — numeric
- `$rse` — numeric
- `$coefficients` — dataframe (Variable, Estimate, Std.Error, t.value, Pr)

### `ml_run(file_path, outcome, predictors, categorical = NULL, factor_levels = NULL, split_ratio = 0.8)`

**The single-shot function.**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `file_path` | character | Yes | — | Path to `.xlsx` file |
| `outcome` | character | Yes | — | Name of outcome column |
| `predictors` | character vector | Yes | — | Names of predictor columns |
| `categorical` | character vector | No | NULL | Names of categorical predictor columns |
| `factor_levels` | named list | No | NULL | List of factor level vectors, one per categorical variable. First level = reference. |
| `split_ratio` | numeric | No | 0.8 | Training set proportion |

**Behavior:**
- Prints a warning: "WARNING: ml_run() executes the entire 5-step ML process in one call. You will not be able to inspect each step individually. Only use this if you are confident in your variable selections and understand the process. For the guided, step-by-step experience, use ml_workflow() instead."
- Requires user to confirm: "Type 'yes' to proceed:"
- Executes all 5 steps silently (no menus), printing a summary at each step.
- Returns the same `"ml_result"` S3 object as `ml_workflow()`.

### `print.ml_result(x, ...)`

**S3 print method for the result object.**

Prints a formatted summary:
```
=== ML Regression Results ===

Outcome Variable: [Y]
Predictors: [X1], [X2], ...
Categorical Predictors: [C1] (levels: A, B), ...

--- Model Fit ---
R-squared: [value]
Residual Standard Error: [value]

--- Coefficients ---
[table of Variable, Estimate, Std.Error, t.value, p-value]

--- VIF ---
[table of Variable, VIF]

--- Predictive Accuracy (Test Set) ---
MAD: [value]
MSE: [value]

Train/Test Split: [ratio] ([n_train] / [n_test] observations)
```

### `plot.ml_result(x, ...)`

**S3 plot method for the result object.**

Produces a 2-panel layout:
- Left panel: Actual vs. Predicted scatter plot with 45-degree line
- Right panel: Residuals plot (predicted vs. residuals)

### `export_xlsx(x, file)`

**Exports all results to a single Excel workbook.**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `x` | ml_result | Yes | Result object from `ml_workflow()` or `ml_run()` |
| `file` | character | Yes | Output file path (e.g., `"results.xlsx"`) |

**Workbook tabs:**

| Tab Name | Contents |
|----------|----------|
| Coefficients | Variable, Estimate, Std.Error, t.value, p-value |
| Model Fit | RSE, R-squared, Adjusted R-squared, F-statistic, F p-value |
| VIF | Variable, VIF (or GVIF, Df, GVIF adjusted) |
| Predictions | Actual, Predicted, Error, Absolute Error |
| Accuracy | MAD, MSE |

Requires `openxlsx`. Uses `requireNamespace()` check with install instructions on failure.

**Returns:** `invisible(file)` (the file path).

---

## 5. Output Format

### Console Output During Interactive Flow

All printed output uses `cat()` for clean formatting (no `[1]` prefixes). Menus use numbered options. Confirmations use `(y/n)`. Variable selection uses comma-separated names.

Example interaction at Step 1:
```
=== Step 1: Collect Data ===

Reading file: mydata.xlsx
Found 500 observations and 8 columns.

Columns:
  [1] AvgSessionLength  (numeric)
  [2] TimeOnApp          (numeric)
  [3] TimeOnWebsite      (numeric)
  [4] LengthOfMembership (numeric)
  [5] YearlyAmountSpent  (numeric)
  [6] Email              (character)
  [7] Address            (character)
  [8] MembershipType     (character)

Which column is your outcome variable (Y)? Enter the column name:
> YearlyAmountSpent

Do you have any categorical predictor variables? (y/n):
> y

Which column(s) are categorical? Enter name(s) separated by commas:
> MembershipType

What are the levels for 'MembershipType'? Enter them separated by commas
(the first one listed becomes the reference level):
> Executive, Standard

Which columns are your predictor variables (X)? Enter name(s) separated by commas:
> AvgSessionLength, TimeOnApp, TimeOnWebsite, LengthOfMembership, MembershipType

--- Summary ---
Outcome:     YearlyAmountSpent
Predictors:  AvgSessionLength, TimeOnApp, TimeOnWebsite, LengthOfMembership
Categorical: MembershipType (levels: Executive [ref], Standard)
Observations: 500

Press Enter to continue to Step 2...
```

### Plots

- Scatter plots: base R `plot()` with labeled axes and descriptive titles
- Box plots: base R `boxplot()` with labeled axes
- Correlation matrix: `corrplot::corrplot()` with `type='lower', method='number'`
- Actual vs. Predicted: `ggplot2::ggplot()` with `geom_point()` and `geom_abline(color="red")`
- Residuals: base R or ggplot2

---

## 6. Dependencies

### Imports (installed automatically with the package)
- `readxl` — reading `.xlsx` files
- `caTools` — `sample.split()` for train/test partitioning
- `corrplot` — correlation matrix visualization
- `car` — `vif()` for multicollinearity checks
- `ggplot2` — actual vs. predicted plot
- `dplyr` — data manipulation
- `stats` — `lm()`, `predict()`
- `graphics` — base plotting
- `utils` — `readline()` console interaction

### Suggests (optional, with install prompts)
- `openxlsx` — Excel export via `export_xlsx()`
- `testthat` (>= 3.0.0) — testing

---

## 7. Test Cases

### Test Case 1: Simple Linear Regression (Stockouts)
- **File:** `simpleLinearRegressionDataStockouts.xlsx`
- **Outcome:** Stockouts
- **Predictors:** ReorderPoint
- **Categorical:** None
- **Expected:** Negative coefficient for ReorderPoint, significant p-value

### Test Case 2: Multiple Regression (Bikes)
- **File:** `bikes.xlsx`
- **Outcome:** rentals
- **Predictors:** temperature, realfeel, humidity, windspeed
- **Categorical:** None
- **Expected:** High VIF for temperature and realfeel (multicollinearity). After removing realfeel, VIFs drop below 5.
- **Seed:** 4321, split 80/20

### Test Case 3: Multiple Regression without Categorical (E-commerce)
- **File:** `Ecommerce Customers.xlsx`
- **Outcome:** YearlyAmountSpent
- **Predictors:** AvgSessionLength, TimeOnApp, TimeOnWebsite, LengthOfMembership
- **Categorical:** None
- **Expected:** All continuous predictors, standard VIF check. LengthOfMembership and TimeOnApp should be significant.
- **Seed:** 4321, split 80/20

### Test Case 4: Multiple Regression with Categorical (E-commerce)
- **File:** `Ecommerce Customers with Categories.xlsx`
- **Outcome:** YearlyAmountSpent
- **Predictors:** AvgSessionLength, TimeOnApp, TimeOnWebsite, LengthOfMembership, MembershipType
- **Categorical:** MembershipType (levels: Executive [ref], Standard)
- **Expected:** MembershipTypeStandard coefficient ~ -5.15, p < 0.05
- **Seed:** 4321, split 80/20

### Test Case 5: Multiple Categorical (Global Shipping)
- **File:** `globalShippingTimes.xlsx`
- **Outcome:** shipping_time
- **Predictors:** destination_country, cost, shipment_mode, shipping_company
- **Categorical:** destination_country (IN [ref], BD), shipment_mode (Air [ref], Ocean), shipping_company (SC1 [ref], SC2, SC3)
- **Expected:** GVIF used instead of VIF. Ocean shipments significantly slower than Air.
- **Seed:** 4321, split 80/20

---

## 8. Package Structure

```
basic_ml_for_lscm/
├── DESCRIPTION
├── LICENSE
├── NAMESPACE
├── .Rbuildignore
├── .gitignore
├── R/
│   ├── ml_workflow.R        # Main interactive function
│   ├── ml_run.R             # Single-shot function
│   ├── step1_collect.R      # Step 1: Collect Data (read file, identify variables)
│   ├── step2_prepare.R      # Step 2: Prepare Data (missing check, plots, corr, split)
│   ├── step3_train.R        # Step 3: Train Model (lm, summary, coefficients)
│   ├── step4_evaluate.R     # Step 4: Evaluate Model (VIF, improve loop)
│   ├── step5_test.R         # Step 5: Test Model (predict, MAD, MSE, plot)
│   ├── ml_result.R          # S3 class definition, print, plot methods
│   ├── export_xlsx.R        # Excel export function
│   └── utils.R              # Shared helpers (menu printing, readline wrappers, validation)
├── man/                     # Auto-generated by roxygen2
├── tests/
│   ├── testthat.R
│   └── testthat/
│       ├── test_ml_run.R
│       ├── test_ml_result.R
│       ├── test_export.R
│       └── test_steps.R
├── README.md
├── PRD.md
├── AI_ASSISTANT_SYSTEM_PROMPT.md
└── R_PACKAGE_DEV_GUIDE.md
```

---

## 9. Design Constraints

- **No auto-selection.** The package never picks variables for the student. Every analytical decision is made by the student via console input.
- **No shipped datasets.** Students bring their own `.xlsx` files.
- **Seed is fixed.** Always `set.seed(4321)` for reproducibility.
- **Split default is 80/20.** Changeable, but 80/20 is recommended and printed as the default.
- **Console interaction only.** No Shiny, no GUI. Everything runs via `readline()` in the R console.
- **Base R plotting for exploration.** Scatter plots and box plots use base R. The final actual-vs-predicted plot uses ggplot2.
- **Excel export is optional.** `openxlsx` is a suggested dependency, not required. The package prompts for installation if the student chooses to export.
- **Interactive functions cannot be tested headlessly.** `ml_workflow()` requires console input and is not unit-tested. All internal step functions are tested independently via `ml_run()` and direct calls.

---

## 10. Coding Brutus Integration

The `AI_ASSISTANT_SYSTEM_PROMPT.md` must reference:

1. **Package installation:** `devtools::install_github("ProfessorCastillo/basic_ml_for_lscm")`
2. **Loading:** `library(basicMLforLSCM)`
3. **Function names:** `ml_workflow()`, `ml_run()`, `export_xlsx()`, `plot()`, `print()`
4. **The interactive flow:** Brutus should know which menus appear and what the student sees at each step, so guidance is never contradictory.
5. **Common errors:** file not found, no xlsx extension, column name typos, forgetting to split before training.
6. **Output reference:** expected output format for each test case so Brutus can verify student results.

---

## 11. Checklist: Before Shipping

- [ ] All `devtools::test()` expectations pass
- [ ] `devtools::check()` returns 0 errors, 0 warnings, 0 notes
- [ ] `ml_workflow()` tested manually with all 4 test case datasets
- [ ] `ml_run()` tested with all 4 test case datasets
- [ ] `export_xlsx()` produces correct multi-tab workbook
- [ ] `plot.ml_result()` produces 2-panel plot without errors
- [ ] `print.ml_result()` output matches format in Section 5
- [ ] VIF improvement loop works (remove variable, re-train, re-check)
- [ ] Categorical variable handling works for 1, 2, and 3+ factor variables
- [ ] README has installation, quick start, and all function examples
- [ ] AI_ASSISTANT_SYSTEM_PROMPT.md is accurate and consistent with final package
- [ ] `.Rbuildignore` excludes PRD, guides, system prompt, .claude
- [ ] Manual test: `install_github()` from clean R session, load, run full workflow
