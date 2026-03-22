# ---------- export_xlsx Tests ----------

skip_if_not_installed("openxlsx")

stockouts_path <- test_path("testdata", "stockouts.xlsx")

build_result <- function() {
  collect <- basicmlforlscm:::step1_collect(
    stockouts_path, interactive = FALSE,
    outcome = "Stockouts", predictors = "ReorderPoint"
  )
  prepare <- basicmlforlscm:::step2_prepare(collect, interactive = FALSE)
  train <- basicmlforlscm:::step3_train(prepare, interactive = FALSE)
  evaluate <- basicmlforlscm:::step4_evaluate(train, interactive = FALSE)
  basicmlforlscm:::step5_test(evaluate, interactive = FALSE)
}

test_that("export_xlsx creates a file with 5 tabs", {
  result <- build_result()
  tmp <- tempfile(fileext = ".xlsx")
  on.exit(unlink(tmp))

  export_xlsx(result, tmp)
  expect_true(file.exists(tmp))

  wb <- openxlsx::loadWorkbook(tmp)
  sheets <- openxlsx::sheets(wb)
  expect_equal(sheets, c("Coefficients", "Model Fit", "VIF", "Predictions", "Accuracy"))
})

test_that("export_xlsx errors on non-ml_result input", {
  expect_error(export_xlsx(list(a = 1), "test.xlsx"), "ml_result")
})
