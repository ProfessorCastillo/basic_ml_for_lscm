# ---------- Utils Tests ----------

test_that(".parse_comma_list splits and trims correctly", {
  result <- basicMLforLSCM:::.parse_comma_list("temperature, humidity, windspeed")
  expect_equal(result, c("temperature", "humidity", "windspeed"))
})

test_that(".parse_comma_list handles extra spaces", {
  result <- basicMLforLSCM:::.parse_comma_list("  a ,  b  , c ")
  expect_equal(result, c("a", "b", "c"))
})

test_that(".parse_comma_list handles single value", {
  result <- basicMLforLSCM:::.parse_comma_list("ReorderPoint")
  expect_equal(result, "ReorderPoint")
})

test_that(".validate_columns returns valid for matching names", {
  result <- basicMLforLSCM:::.validate_columns(c("a", "b"), c("a", "b", "c"))
  expect_true(result$valid)
  expect_equal(length(result$bad), 0)
})

test_that(".validate_columns catches bad names", {
  result <- basicMLforLSCM:::.validate_columns(c("a", "d"), c("a", "b", "c"))
  expect_false(result$valid)
  expect_equal(result$bad, "d")
})
