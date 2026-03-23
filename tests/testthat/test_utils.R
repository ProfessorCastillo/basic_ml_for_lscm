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

test_that(".parse_comma_list returns character(0) for empty input", {
  expect_equal(basicMLforLSCM:::.parse_comma_list(""), character(0))
  expect_equal(basicMLforLSCM:::.parse_comma_list("   "), character(0))
})

test_that(".resolve_column matches exact name", {
  cols <- c("Temperature", "Humidity", "WindSpeed")
  expect_equal(basicMLforLSCM:::.resolve_column("Humidity", cols), "Humidity")
})

test_that(".resolve_column matches by number", {
  cols <- c("Temperature", "Humidity", "WindSpeed")
  expect_equal(basicMLforLSCM:::.resolve_column("2", cols), "Humidity")
  expect_equal(basicMLforLSCM:::.resolve_column("[2]", cols), "Humidity")
})

test_that(".resolve_column matches case-insensitively", {
  cols <- c("Temperature", "Humidity", "WindSpeed")
  expect_equal(basicMLforLSCM:::.resolve_column("humidity", cols), "Humidity")
  expect_equal(basicMLforLSCM:::.resolve_column("WINDSPEED", cols), "WindSpeed")
})

test_that(".resolve_column returns NULL for no match", {
  cols <- c("Temperature", "Humidity")
  expect_null(basicMLforLSCM:::.resolve_column("Pressure", cols))
  expect_null(basicMLforLSCM:::.resolve_column("5", cols))
})

test_that(".resolve_columns resolves mixed input", {
  cols <- c("Temperature", "Humidity", "WindSpeed")
  result <- basicMLforLSCM:::.resolve_columns(c("1", "humidity", "WindSpeed"), cols)
  expect_true(result$valid)
  expect_equal(result$resolved, c("Temperature", "Humidity", "WindSpeed"))
})
