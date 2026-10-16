# Run from the project root: Rscript tests/test_app.R
args <- commandArgs(trailingOnly = TRUE)
app_path <- if (length(args)) args[1] else "app.R"
expressions <- parse(app_path)
math <- new.env(parent = globalenv())
for (expr in expressions) {
  if (is.call(expr) && identical(expr[[1]], as.name("library"))) break
  eval(expr, math)
}
with(math, {
  near <- function(x, y, tol = 1e-10) stopifnot(isTRUE(all.equal(x, y, tolerance = tol)))
  fails <- function(expr) stopifnot(inherits(try(force(expr), silent = TRUE), "try-error"))
  stopifnot(analytic_result("smooth", 0)$exists)
  for (choice in c("absolute", "vertical", "corner", "jump")) {
    z <- diagnose(choice, 0, 0.1)
    stopifnot(!z$exact$exists, !z$supported)
    stopifnot(z$exact$continuous == (choice != "jump"))
  }
  for (a in c(-3, -1, 0, 0.3, 1, 4)) {
    z <- diagnose("smooth", a, 0.1)
    stopifnot(z$exact$exists, z$supported)
    near(z$estimate, 2 * a)
  }
  # A coarse setting must not misclassify the differentiable origin.
  z <- diagnose("smooth", 0, 1)
  stopifnot(z$exact$exists, z$supported)
  # Singularities are handled locally; nearby points are not singular.
  for (choice in c("absolute", "vertical", "corner", "jump")) {
    for (a in c(-1e-10, 1e-10)) {
      z <- diagnose(choice, a, 0.1)
      stopifnot(z$exact$exists, z$supported,
                all(z$data$requested_distance < abs(a)), length(z$warnings) > 0)
    }
  }
  # Stable divided differences agree with independently known cases.
  near(stable_slope("smooth", 1, 1.5), 2.5)
  near(stable_slope("absolute", -1, 2), 1 / 3)
  near(stable_slope("corner", -1, 1), 0.5)
  near(stable_slope("vertical", -8, 1), 1 / 3)
  near(stable_slope("jump", -1, 1), 0.5)
  # Cancellation: direct subtraction at a large coordinate loses information.
  a <- 1e8; b <- a + 1e-8
  near(stable_slope("smooth", a, b), a + b)
  stopifnot(abs((b^2 - a^2) / (b - a) - (a + b)) > 1e6)
  z <- diagnose("smooth", 1.23456789, 1e-12)
  stopifnot(z$supported, any(!z$data$usable),
            any(grepl("Direct subtraction", z$warnings)))
  z <- diagnose("smooth", 1, 1e-40)
  stopifnot(z$exact$exists, !z$supported, all(!z$data$usable), is.na(z$secant))
  # Secant direction must not change the symmetric diagnostic samples.
  p <- diagnose("smooth", 1, 0.1); n <- diagnose("smooth", 1, -0.1)
  near(p$data$left_slope, n$data$left_slope)
  near(p$data$right_slope, n$data$right_slope)
  near(p$secant, 2.1); near(n$secant, 1.9)
  fails(diagnose("missing", 0, 0.1))
  fails(diagnose("smooth", NA_real_, 0.1))
  fails(diagnose("smooth", 0, 0))
  fails(diagnose("smooth", 0, Inf))
  fails(diagnose("smooth", 0, 0.1, refinements = 2))
  fails(diagnose("smooth", 0, 0.1, atol = -1))
})
cat("PASS: analytical cases, local branches, cancellation, collapsed coordinates, and validation.\n")

if (!requireNamespace("shiny", quietly = TRUE)) {
  cat("SKIP: Shiny server checks (install shiny to run them).\n")
  quit(status = 0)
}
app_env <- new.env(parent = globalenv())
for (expr in head(expressions, -1L)) eval(expr, app_env)
shiny::testServer(app_env$server, {
  session$setInputs(fun = "smooth", a = 1, range = c(-2, 2), logh = -1,
                   direction = "1", secant = TRUE, tangent = TRUE, autofit = TRUE)
  stopifnot(d()$supported, d()$exact$slope == 2)
  stopifnot(grepl("Differentiable at a", output$conclusion$html))
  stopifnot(length(output$graph) > 0)
  session$setInputs(fun = "absolute", a = 0)
  stopifnot(!d()$exact$exists, !d()$supported)
  stopifnot(grepl("Not differentiable", output$conclusion$html))
  session$setInputs(fun = "vertical", a = 0)
  stopifnot(!d()$exact$exists, length(output$graph) > 0)
  session$setInputs(fun = "jump", a = 0)
  stopifnot(!d()$exact$continuous, length(output$graph) > 0)
  session$setInputs(fun = "corner", a = 0.01)
  stopifnot(d()$supported, d()$exact$slope == 2)
  session$setInputs(fun = "smooth", a = 2, range = c(-2, 2), logh = 0)
  stopifnot(d()$secant_x == 3, length(output$graph) > 0)
  session$setInputs(range = c(0, 0))
  stopifnot(inherits(try(d(), silent = TRUE), "try-error"))
})
cat("PASS: Shiny reactive outputs, exceptional cases, plot rendering, and range validation.\n")
