# Internal utility functions for console interaction and validation
# None of these are exported.

#' Prompt user and return trimmed input
#' @noRd
.ask <- function(prompt) {
  cat(prompt)
  trimws(readline())
}

#' Ask a yes/no question. Returns TRUE for yes, FALSE for no.
#' @noRd
.ask_yn <- function(prompt) {
  repeat {
    answer <- tolower(.ask(paste0(prompt, " (y/n): ")))
    if (answer %in% c("y", "yes")) return(TRUE)
    if (answer %in% c("n", "no")) return(FALSE)
    cat("Please enter 'y' or 'n'.\n")
  }
}

#' Display a numbered menu and return the selected integer.
#' @noRd
.menu <- function(title, choices) {
  cat("\n", title, "\n", sep = "")
  for (i in seq_along(choices)) {
    cat("  [", i, "] ", choices[i], "\n", sep = "")
  }
  repeat {
    answer <- .ask("Enter your choice: ")
    num <- suppressWarnings(as.integer(answer))
    if (!is.na(num) && num >= 1L && num <= length(choices)) return(num)
    cat("Please enter a number between 1 and ", length(choices), ".\n", sep = "")
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

#' Print a section header.
#' @noRd
.print_header <- function(text) {
  cat("\n=== ", text, " ===\n\n", sep = "")
}

#' Print a sub-header.
#' @noRd
.print_subheader <- function(text) {
  cat("\n--- ", text, " ---\n\n", sep = "")
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
    cat("  [", i, "] ", nms[i], "  (", col_class, ")\n", sep = "")
  }
}
