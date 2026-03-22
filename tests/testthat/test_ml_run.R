# ---------- ml_run Integration Tests ----------

# These tests use mockr or direct internal calls since ml_run() requires
# readline confirmation. We test via the step functions directly for
# full integration coverage.

stockouts_path <- test_path("testdata", "stockouts.xlsx")
shipping_path  <- test_path("testdata", "globalShippingTimes.xlsx")

test_that("Full pipeline produces valid ml_result for simple regression", {
  collect <- basicMLforLSCM:::step1_collect(
    stockouts_path, interactive = FALSE,
    outcome = "Stockouts", predictors = "ReorderPoint"
  )
  prepare <- basicMLforLSCM:::step2_prepare(collect, interactive = FALSE)
  train <- basicMLforLSCM:::step3_train(prepare, interactive = FALSE)
  evaluate <- basicMLforLSCM:::step4_evaluate(train, interactive = FALSE)
  result <- basicMLforLSCM:::step5_test(evaluate, interactive = FALSE)

  expect_s3_class(result, "ml_result")
  expect_equal(result$outcome, "Stockouts")
  expect_equal(result$predictors, "ReorderPoint")
  expect_null(result$categorical)
  expect_s3_class(result$model, "lm")
  expect_true(result$r_squared > 0)
  expect_true(result$mad > 0)
  expect_true(result$mse > 0)
})

test_that("Full pipeline works with categorical predictors", {
  collect <- basicMLforLSCM:::step1_collect(
    shipping_path, interactive = FALSE,
    outcome = "shipping_time",
    predictors = c("destination_country", "cost", "shipment_mode", "shipping_company"),
    categorical = c("destination_country", "shipment_mode", "shipping_company"),
    factor_levels = list(
      destination_country = c("IN", "BD"),
      shipment_mode = c("Air", "Ocean"),
      shipping_company = c("SC1", "SC2", "SC3")
    )
  )
  prepare <- basicMLforLSCM:::step2_prepare(collect, interactive = FALSE)
  train <- basicMLforLSCM:::step3_train(prepare, interactive = FALSE)
  evaluate <- basicMLforLSCM:::step4_evaluate(train, interactive = FALSE)
  result <- basicMLforLSCM:::step5_test(evaluate, interactive = FALSE)

  expect_s3_class(result, "ml_result")
  expect_equal(result$outcome, "shipping_time")
  expect_true("GVIF_adjusted" %in% names(result$vif))

  # Ocean should be significantly slower than Air
  ocean_row <- result$coefficients[grepl("Ocean", result$coefficients$Variable), ]
  expect_true(nrow(ocean_row) > 0)
  expect_true(ocean_row$Estimate > 0) # positive = slower
})

test_that("All ml_result fields are populated", {
  collect <- basicMLforLSCM:::step1_collect(
    stockouts_path, interactive = FALSE,
    outcome = "Stockouts", predictors = "ReorderPoint"
  )
  prepare <- basicMLforLSCM:::step2_prepare(collect, interactive = FALSE)
  train <- basicMLforLSCM:::step3_train(prepare, interactive = FALSE)
  evaluate <- basicMLforLSCM:::step4_evaluate(train, interactive = FALSE)
  result <- basicMLforLSCM:::step5_test(evaluate, interactive = FALSE)

  expect_true(!is.null(result$data))
  expect_true(!is.null(result$outcome))
  expect_true(!is.null(result$predictors))
  expect_true(!is.null(result$train_set))
  expect_true(!is.null(result$test_set))
  expect_true(!is.null(result$model))
  expect_true(!is.null(result$model_summary))
  expect_true(!is.null(result$predictions))
  expect_true(!is.null(result$mad))
  expect_true(!is.null(result$mse))
  expect_true(!is.null(result$r_squared))
  expect_true(!is.null(result$rse))
  expect_true(!is.null(result$coefficients))
})
