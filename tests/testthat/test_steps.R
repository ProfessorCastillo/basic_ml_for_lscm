# ---------- Step Function Tests (Non-Interactive) ----------

stockouts_path <- test_path("testdata", "stockouts.xlsx")
bikes_path     <- test_path("testdata", "bikes.xlsx")
shipping_path  <- test_path("testdata", "globalShippingTimes.xlsx")

# ---------- Step 1: Collect ----------

test_that("step1_collect reads data and returns correct structure", {
  result <- basicMLforLSCM:::step1_collect(
    stockouts_path, interactive = FALSE,
    outcome = "Stockouts", predictors = "ReorderPoint"
  )
  expect_true(is.data.frame(result$data))
  expect_equal(result$outcome, "Stockouts")
  expect_equal(result$predictors, "ReorderPoint")
  expect_null(result$categorical)
})

test_that("step1_collect errors on missing file", {
  expect_error(
    basicMLforLSCM:::step1_collect("nonexistent.xlsx", interactive = FALSE,
                                   outcome = "x", predictors = "y"),
    "File not found"
  )
})

test_that("step1_collect handles categorical variables", {
  result <- basicMLforLSCM:::step1_collect(
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
  expect_true(is.factor(result$data$destination_country))
  expect_true(is.factor(result$data$shipment_mode))
  expect_equal(levels(result$data$shipping_company), c("SC1", "SC2", "SC3"))
})

# ---------- Step 2: Prepare ----------

test_that("step2_prepare splits data at correct ratio", {
  collect <- basicMLforLSCM:::step1_collect(
    stockouts_path, interactive = FALSE,
    outcome = "Stockouts", predictors = "ReorderPoint"
  )
  result <- basicMLforLSCM:::step2_prepare(collect, interactive = FALSE, split_ratio = 0.8)

  expect_true(is.data.frame(result$train_set))
  expect_true(is.data.frame(result$test_set))
  expect_equal(nrow(result$train_set) + nrow(result$test_set), nrow(result$data))
  expect_equal(result$split_ratio, 0.8)
})

# ---------- Step 3: Train ----------

test_that("step3_train returns a valid lm model", {
  collect <- basicMLforLSCM:::step1_collect(
    stockouts_path, interactive = FALSE,
    outcome = "Stockouts", predictors = "ReorderPoint"
  )
  prepare <- basicMLforLSCM:::step2_prepare(collect, interactive = FALSE)
  result <- basicMLforLSCM:::step3_train(prepare, interactive = FALSE)

  expect_s3_class(result$model, "lm")
  expect_true(is.data.frame(result$coefficients_df))
  expect_true(result$r_squared >= 0 && result$r_squared <= 1)
  expect_true(result$rse > 0)
})

test_that("step3_train produces negative coefficient for ReorderPoint", {
  collect <- basicMLforLSCM:::step1_collect(
    stockouts_path, interactive = FALSE,
    outcome = "Stockouts", predictors = "ReorderPoint"
  )
  prepare <- basicMLforLSCM:::step2_prepare(collect, interactive = FALSE)
  result <- basicMLforLSCM:::step3_train(prepare, interactive = FALSE)

  rp_row <- result$coefficients_df[result$coefficients_df$Variable == "ReorderPoint", ]
  expect_true(rp_row$Estimate < 0)
})

# ---------- Step 4: Evaluate ----------

test_that("step4_evaluate returns VIF dataframe for multiple predictors", {
  collect <- basicMLforLSCM:::step1_collect(
    bikes_path, interactive = FALSE,
    outcome = "rentals",
    predictors = c("temperature", "realfeel", "humidity", "windspeed")
  )
  prepare <- basicMLforLSCM:::step2_prepare(collect, interactive = FALSE)
  train <- basicMLforLSCM:::step3_train(prepare, interactive = FALSE)
  result <- basicMLforLSCM:::step4_evaluate(train, interactive = FALSE)

  expect_true(is.data.frame(result$vif_df))
  expect_true("VIF" %in% names(result$vif_df))
})

test_that("step4_evaluate returns NULL VIF for single predictor", {
  collect <- basicMLforLSCM:::step1_collect(
    stockouts_path, interactive = FALSE,
    outcome = "Stockouts", predictors = "ReorderPoint"
  )
  prepare <- basicMLforLSCM:::step2_prepare(collect, interactive = FALSE)
  train <- basicMLforLSCM:::step3_train(prepare, interactive = FALSE)
  result <- basicMLforLSCM:::step4_evaluate(train, interactive = FALSE)

  expect_null(result$vif_df)
})

test_that("step4_evaluate returns GVIF for categorical predictors", {
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
  result <- basicMLforLSCM:::step4_evaluate(train, interactive = FALSE)

  expect_true(is.data.frame(result$vif_df))
  expect_true("GVIF_adjusted" %in% names(result$vif_df))
})

# ---------- Step 5: Test ----------

test_that("step5_test returns ml_result with correct predictions", {
  collect <- basicMLforLSCM:::step1_collect(
    stockouts_path, interactive = FALSE,
    outcome = "Stockouts", predictors = "ReorderPoint"
  )
  prepare <- basicMLforLSCM:::step2_prepare(collect, interactive = FALSE)
  train <- basicMLforLSCM:::step3_train(prepare, interactive = FALSE)
  evaluate <- basicMLforLSCM:::step4_evaluate(train, interactive = FALSE)
  result <- basicMLforLSCM:::step5_test(evaluate, interactive = FALSE)

  expect_s3_class(result, "ml_result")
  expect_true(is.data.frame(result$predictions))
  expect_equal(nrow(result$predictions), nrow(result$test_set))
  expect_true(result$mad >= 0)
  expect_true(result$mse >= 0)
})
