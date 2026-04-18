# Internal utility functions for console interaction and validation
# None of these are exported.

# --- Session log ---
# Package-level environment to accumulate log lines during ml_workflow().
.ml_env <- new.env(parent = emptyenv())
.ml_env$log <- character(0)
.ml_env$logging <- FALSE
.ml_env$student_name <- "student"
.ml_env$student_seed <- 4321
.ml_env$project_name <- ""

#' Start logging.
#' @noRd
.log_start <- function() {
  .ml_env$log <- character(0)
  .ml_env$logging <- TRUE
}

#' Stop logging and return the accumulated log.
#' @noRd
.log_stop <- function() {
  .ml_env$logging <- FALSE
  .ml_env$log
}

#' Append text to the log (if logging is active).
#' @noRd
.log_append <- function(...) {
  if (.ml_env$logging) {
    text <- paste0(...)
    .ml_env$log <- c(.ml_env$log, text)
  }
}

#' Cat and log. Prints to console AND appends to log.
#' @noRd
.lcat <- function(...) {
  text <- paste0(...)
  cat(text)
  .log_append(text)
}

#' Prompt user and return trimmed input. Logs both prompt and response.
#' @noRd
.ask <- function(prompt) {
  cat(prompt)
  .log_append(prompt)
  response <- trimws(readline())
  .log_append("> ", response, "\n")
  response
}

#' Ask a yes/no question. Returns TRUE for yes, FALSE for no.
#' @noRd
.ask_yn <- function(prompt) {
  repeat {
    answer <- tolower(.ask(paste0(prompt, " (y/n): ")))
    if (answer %in% c("y", "yes")) return(TRUE)
    if (answer %in% c("n", "no")) return(FALSE)
    .lcat("Please enter 'y' or 'n'.\n")
  }
}

#' Display a numbered menu and return the selected integer.
#' @noRd
.menu <- function(title, choices) {
  .lcat("\n", title, "\n")
  for (i in seq_along(choices)) {
    .lcat("  [", i, "] ", choices[i], "\n")
  }
  repeat {
    answer <- .ask("Enter your choice: ")
    num <- suppressWarnings(as.integer(answer))
    if (!is.na(num) && num >= 1L && num <= length(choices)) return(num)
    .lcat("Please enter a number between 1 and ", length(choices), ".\n")
  }
}

#' Split a comma-separated string into a trimmed character vector.
#' Returns character(0) for empty/whitespace-only input.
#' @noRd
.parse_comma_list <- function(input) {
  input <- trimws(input)
  if (nchar(input) == 0L) return(character(0))
  parts <- strsplit(input, ",")[[1]]
  parts <- trimws(parts)
  parts[nchar(parts) > 0L]
}

#' Validate that all selected names exist in the available names.
#' Returns a list with $valid (logical) and $bad (character vector of invalid names).
#' @noRd
.validate_columns <- function(selected, available) {
  bad <- selected[!selected %in% available]
  list(valid = length(bad) == 0L, bad = bad)
}

#' Resolve a column reference that may be a name, number, or wrong case.
#' Returns the corrected column name, or NULL if not found.
#' @noRd
.resolve_column <- function(input, available) {
  input <- trimws(input)
  # Try exact match first
  if (input %in% available) return(input)
  # Try as a number (e.g., "3" or "[3]")
  num_str <- gsub("[\\[\\]]", "", input, perl = TRUE)
  num <- suppressWarnings(as.integer(num_str))
  if (!is.na(num) && num >= 1L && num <= length(available)) {
    return(available[num])
  }
  # Try case-insensitive match
  match_idx <- which(tolower(available) == tolower(input))
  if (length(match_idx) == 1L) {
    return(available[match_idx])
  }
  NULL
}

#' Resolve a comma-separated list of column references.
#' Returns a list with $resolved (character vector) and $bad (character vector).
#' @noRd
.resolve_columns <- function(input_vec, available) {
  resolved <- character(0)
  bad <- character(0)
  for (inp in input_vec) {
    r <- .resolve_column(inp, available)
    if (!is.null(r)) {
      resolved <- c(resolved, r)
    } else {
      bad <- c(bad, inp)
    }
  }
  list(resolved = resolved, bad = bad, valid = length(bad) == 0L)
}

#' Wrap column names in backticks if they are non-syntactic (spaces, etc.).
#' @noRd
.bt <- function(x) {
  vapply(x, function(nm) {
    if (make.names(nm) != nm) paste0("`", nm, "`") else nm
  }, character(1), USE.NAMES = FALSE)
}

#' Sanitize a string for use in a file name (replace non-alphanumeric with _).
#' @noRd
.safe_name <- function(x) {
  gsub("[^a-zA-Z0-9._-]", "_", x)
}

#' Build the output file name prefix from student name and project name.
#' Returns "studentname_projectname" or "studentname" if no project name is set.
#' @noRd
.file_prefix <- function() {
  pn <- .ml_env$project_name
  if (!is.null(pn) && nchar(pn) > 0L) {
    paste0(.ml_env$student_name, "_", pn)
  } else {
    .ml_env$student_name
  }
}

#' Print a section header.
#' @noRd
.print_header <- function(text) {
  .lcat("\n=== ", text, " ===\n\n")
}

#' Print a sub-header.
#' @noRd
.print_subheader <- function(text) {
  .lcat("\n--- ", text, " ---\n\n")
}

#' Pause and wait for the user to press Enter.
#' @noRd
.pause <- function() {
  .ask("Press Enter to continue...")
  invisible(NULL)
}

#' Print a column listing with types.
#' @noRd
.print_columns <- function(data) {
  nms <- names(data)
  for (i in seq_along(nms)) {
    col_class <- class(data[[nms[i]]])[1]
    .lcat("  [", i, "] ", nms[i], "  (", col_class, ")\n")
  }
}

#' Print an object and log the output.
#' @noRd
.lprint <- function(x, ...) {
  out <- utils::capture.output(print(x, ...))
  for (line in out) {
    .lcat(line, "\n")
  }
}

#' Save the current plot to a PNG file in the working directory.
#' @noRd
.save_plot <- function(filename, width = 800, height = 600) {
  grDevices::png(filename, width = width, height = height, res = 120)
}

#' Finish saving a plot (close the device) and print confirmation.
#' @noRd
.save_plot_done <- function(filename) {
  grDevices::dev.off()
  .lcat("  Plot saved to: ", filename, "\n")
}
