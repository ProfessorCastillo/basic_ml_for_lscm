# Basic Machine Learning for Logistics and Supply Chain Management (basicMLforLSCM)

An interactive R package that guides students through the 5-step supervised machine learning regression workflow using linear regression. Built for **BUSML 4382 — Logistics and Supply Chain Analytics** at The Ohio State University.

## Installation

```r
# Install devtools if you don't have it
install.packages("devtools")

# Install the package from GitHub
devtools::install_github("ProfessorCastillo/basic_ml_for_lscm")

# Load the package
library(basicMLforLSCM)
```

## Quick Start

### Option 1: Interactive Workflow (Recommended)

The guided, step-by-step experience. The package walks you through each decision with menus and prompts.

```r
result <- ml_workflow("mydata.xlsx")
```

The package will ask for your OSU name.# (e.g., `castillo.230`) at the start. This is used to name all output files and generate a unique train/test split for your analysis.

You'll be guided through:

1. **Collect Data** — identify your outcome variable, categorical predictors, and predictor variables
2. **Prepare Data** — check for missing data, create scatter/box plots, view the correlation matrix, split into training and testing sets
3. **Train Model** — fit the regression, see coefficient interpretations and model fit statistics
4. **Evaluate Model** — check for multicollinearity (VIF), remove or add variables if needed
5. **Test Model** — predict on the test set, see MAD and MSE accuracy metrics

You can **go back to a previous step** at any time without starting over. Each step's menu includes a go-back option, and Step 1 asks you to confirm your selections before moving on.

### Option 2: Single-Shot Run

For students confident in the material who want to run everything at once.

```r
result <- ml_run(
  file_path  = "bikes.xlsx",
  outcome    = "rentals",
  predictors = c("temperature", "humidity", "windspeed"),
  split_ratio = 0.8
)
```

With categorical predictors:

```r
result <- ml_run(
  file_path    = "globalShippingTimes.xlsx",
  outcome      = "shipping_time",
  predictors   = c("destination_country", "cost", "shipment_mode", "shipping_company"),
  categorical  = c("destination_country", "shipment_mode", "shipping_company"),
  factor_levels = list(
    destination_country = c("IN", "BD"),
    shipment_mode       = c("Air", "Ocean"),
    shipping_company    = c("SC1", "SC2", "SC3")
  )
)
```

## Working with Results

After completing either workflow, you get back a result object you can inspect, plot, and export.

```r
# Print a formatted summary
print(result)

# View a 2-panel plot (Actual vs Predicted + Residuals)
plot(result)

# Export everything to Excel (requires openxlsx)
# The workflow prompts for this automatically at the end.
# You can also export manually:
export_xlsx(result, "my_results.xlsx")
```

### Understanding the Print Output

```
=== ML Regression Results ===

Outcome Variable: rentals
Predictors:       temperature, humidity, windspeed

--- Model Fit ---
R-squared:              0.4532
Residual Standard Error: 1245.67

--- Coefficients ---
      Variable  Estimate Std.Error  t.value   p.value
   (Intercept)  1234.567   345.678   3.5714 4.123e-04
   temperature    45.678    12.345   3.7003 2.891e-04
      humidity   -12.345     5.678  -2.1741 3.012e-02
     windspeed   -34.567    15.432  -2.2402 2.567e-02

--- VIF ---
    Variable    VIF
 temperature 1.2345
    humidity 1.1234
   windspeed 1.0567

--- Predictive Accuracy (Test Set) ---
MAD: 987.6543
MSE: 1543210.1234

Train/Test Split: 80/20 (600 / 150 observations)
```

### Understanding the Excel Export

The `export_xlsx()` function creates one workbook with 6 tabs:

| Tab | Contents |
|-----|----------|
| **Coefficients** | Variable names, estimates, standard errors, t-values, p-values |
| **Model Fit** | RSE, R-squared, Adjusted R-squared, F-statistic, F p-value |
| **VIF** | Variance Inflation Factor values for each predictor |
| **Predictions** | Actual values, predicted values, errors, and absolute errors |
| **Accuracy** | MAD and MSE |
| **Console Log** | Full record of the interactive session (decisions, outputs, interpretations) |

## Function Reference

| Function | Description |
|----------|-------------|
| `ml_workflow(file_path)` | Interactive 5-step ML workflow with console menus |
| `ml_run(file_path, outcome, predictors, ...)` | Single-shot ML workflow (all steps at once) |
| `print(result)` | Display formatted summary of results |
| `plot(result)` | 2-panel plot: Actual vs Predicted and Residuals |
| `export_xlsx(result, file)` | Export all results to a multi-tab Excel workbook |

## Requirements

The following packages are installed automatically with `basicMLforLSCM`:

- `readxl` — reading Excel files
- `caTools` — train/test splitting
- `corrplot` — correlation matrix visualization
- `car` — VIF multicollinearity checks
- `ggplot2` — plotting

Optional (for Excel export):
- `openxlsx` — install with `install.packages("openxlsx")`

## Output Files

All output files are automatically prefixed with your OSU name.# and saved to your working directory:

| File | Example |
|------|---------|
| Excel export | `castillo.230_results.xlsx` |
| Session log | `castillo.230_session_log.txt` |
| Scatter plots | `castillo.230_scatter_Temperature_vs_DeliveryTime.png` |
| Box plots | `castillo.230_boxplot_DeliveryTime_by_Market.png` |
| Correlation matrix | `castillo.230_correlation_matrix.png` |
| Actual vs Predicted | `castillo.230_actual_vs_predicted_DeliveryTime.png` |
| Diagnostic plots | `castillo.230_diagnostic_plots_DeliveryTime.png` |

## Tips

- **Flexible column entry** — When the package asks for a column name, you can enter the exact name, the column number (e.g., `3` or `[3]`), or even a case-insensitive name (e.g., `stockouts` will match `Stockouts`).
- **Made a mistake?** — If you accidentally answer "yes" to having categorical variables, just press Enter with no input at the next prompt and choose to skip. At the end of Step 1, you'll be asked "Does this look correct?" — answer "no" to redo your selections.
- **Go back** — Every step has a go-back option in its menu. You don't have to start over if you want to change something from a previous step.
- **Export at the end** — The workflow automatically prompts you to export to Excel after Step 5. Press Enter to accept the suggested filename.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `Error: File not found` | Check your file path. Use `getwd()` to see your working directory and make sure your `.xlsx` file is there. |
| `Column not found` | Check spelling, or just enter the column number instead. The package also accepts case-insensitive names. |
| `Package 'openxlsx' is required` | Run `install.packages("openxlsx")` then try again. |
| Plot doesn't appear | Make sure you're running in RStudio (not the basic R console). Check the Plots panel in the bottom-right. |
| VIF requires at least 2 predictors | VIF only works with multiple regression. Add more predictors or skip this step. |
| Accidentally said yes to categorical | Press Enter with no input at the next prompt, then choose to skip. Or answer "no" at the confirmation to redo Step 1. |

## AI Assistant

An AI assistant system prompt is available for use with this package. See `AI_ASSISTANT_SYSTEM_PROMPT.md` in the repository for a Coding Brutus prompt that guides students through installation and usage.

## Author

Professor Vince Castillo — The Ohio State University
