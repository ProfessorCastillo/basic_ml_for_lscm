# ---------- ml_result S3 Methods ----------

stockouts_path <- test_path("testdata", "stockouts.xlsx")

# Helper to build a result object
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

test_that("print.ml_result returns invisible(x)", {
  result <- build_result()
  out <- capture.output(ret <- print(result))
  expect_s3_class(ret, "ml_result")
})

test_that("print.ml_result produces output", {
  result <- build_result()
  out <- capture.output(print(result))
  expect_true(length(out) > 5)
  expect_true(any(grepl("ML Regression Results", out)))
  expect_true(any(grepl("Stockouts", out)))
})

test_that("plot.ml_result runs without error", {
  result <- build_result()
  expect_no_error(plot(result))
})
