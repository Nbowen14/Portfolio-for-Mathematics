# Differentiability Explorer - Nicholas A. Bowen, Project 3
# Install once: install.packages("shiny")
# Save as app.R, open in RStudio, and click Run App.
# The exact answers below apply only to the five included functions.

FUNCTION_LABELS <- c(
  "Smooth: f(x) = x^2" = "smooth",
  "Corner: f(x) = |x|" = "absolute",
  "Vertical tangent: cube root of x" = "vertical",
  "Piecewise corner: -x below 0; 2x otherwise" = "corner",
  "Piecewise jump: 0 below 0; 1 otherwise" = "jump"
)

check_choice <- function(choice) {
  if (length(choice) != 1L || is.na(choice) ||
      !choice %in% unname(FUNCTION_LABELS)) stop("Choose a supported function.")
}

check_number <- function(x, name) {
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x))
    stop(paste(name, "must be one finite number."))
}

function_value <- function(x, choice) {
  check_choice(choice)
  switch(choice,
    smooth = x^2,
    absolute = abs(x),
    vertical = sign(x) * abs(x)^(1 / 3),
    corner = ifelse(x < 0, -x, 2 * x),
    jump = ifelse(x < 0, 0, 1)
  )
}

analytic_result <- function(choice, a) {
  check_choice(choice)
  check_number(a, "Point a")
  singular <- choice != "smooth" && a == 0
  if (singular) {
    reason <- switch(choice,
      absolute = "The left derivative is -1 and the right derivative is 1: a corner.",
      corner = "The left derivative is -1 and the right derivative is 2: a corner.",
      vertical = "The curve has a vertical tangent. Both slopes grow without bound, so no finite derivative exists.",
      jump = "The left limit is 0 and the right limit is 1. The discontinuity rules out differentiability."
    )
    return(list(exists = FALSE, continuous = choice != "jump",
                slope = NA_real_, reason = reason))
  }
  slope <- switch(choice,
    smooth = 2 * a,
    absolute = sign(a),
    vertical = 1 / (3 * abs(a)^(2 / 3)),
    corner = if (a < 0) -1 else 2,
    jump = 0
  )
  list(exists = TRUE, continuous = TRUE, slope = slope,
       reason = "The analytical derivative exists at this point.")
}

# Algebraically equivalent divided differences avoid subtracting almost equal
# function values. These identities are specific to the included examples.
stable_slope <- function(choice, x0, x1) {
  check_choice(choice)
  if (length(x0) != 1L || length(x1) != 1L ||
      !all(is.finite(c(x0, x1))) || x0 == x1) return(NA_real_)
  dx <- x1 - x0
  if (!is.finite(dx)) return(NA_real_)
  switch(choice,
    smooth = x0 + x1,
    absolute = {
      if (x0 >= 0 && x1 >= 0) 1 else if (x0 <= 0 && x1 <= 0) -1 else
        (abs(x1) - abs(x0)) / dx
    },
    vertical = {
      u <- function_value(x0, "vertical")
      v <- function_value(x1, "vertical")
      1 / (u * u + u * v + v * v)
    },
    corner = {
      if (x0 >= 0 && x1 >= 0) 2 else if (x0 <= 0 && x1 <= 0) -1 else
        (function_value(x1, choice) - function_value(x0, choice)) / dx
    },
    jump = (as.numeric(x1 >= 0) - as.numeric(x0 >= 0)) / dx
  )
}

diagnose <- function(choice, a, h, refinements = 24L,
                     rtol = 1e-4, atol = 1e-6) {
  check_choice(choice)
  check_number(a, "Point a")
  check_number(h, "Secant increment")
  if (h == 0) stop("The secant increment must be nonzero.")
  if (length(refinements) != 1L || !is.finite(refinements) ||
      refinements < 3 || refinements > 60 || refinements != floor(refinements))
    stop("Use between 3 and 60 diagnostic refinements.")
  check_number(rtol, "Relative tolerance")
  check_number(atol, "Absolute tolerance")
  if (rtol < 0 || atol < 0) stop("Tolerances must be nonnegative.")
  f <- function(x) function_value(x, choice)
  fa <- f(a)
  if (!is.finite(fa)) stop("The function value exceeds floating-point range.")
  exact <- analytic_result(choice, a)
  initial <- abs(h)
  # Stay on the local smooth branch near a known exceptional point.
  if (choice != "smooth" && a != 0) initial <- min(initial, abs(a) / 4)
  distance <- initial / 2^(seq_len(refinements) - 1L)
  xl <- a - distance
  xr <- a + distance
  dl <- a - xl
  dr <- xr - a
  spacing_floor <- 8 * .Machine$double.eps * max(abs(a), .Machine$double.xmin)
  valid <- is.finite(xl) & is.finite(xr) & is.finite(dl) & is.finite(dr) &
    dl > spacing_floor & dr > spacing_floor &
    !duplicated(dl) & !duplicated(dr) & is.finite(f(xl)) & is.finite(f(xr))
  left <- right <- raw_left <- raw_right <- rep(NA_real_, refinements)
  for (i in which(valid)) {
    left[i] <- stable_slope(choice, xl[i], a)
    right[i] <- stable_slope(choice, a, xr[i])
    # Use the actual representable coordinate differences, not nominal distances.
    raw_left[i] <- (fa - f(xl[i])) / dl[i]
    raw_right[i] <- (f(xr[i]) - fa) / dr[i]
  }
  valid <- valid & is.finite(left) & is.finite(right)
  left[!valid] <- right[!valid] <- NA_real_
  usable <- which(valid)
  recent <- tail(usable, 3L)
  estimate <- if (length(usable)) {
    j <- tail(usable, 1L)
    left[j] / 2 + right[j] / 2
  } else NA_real_
  tolerance <- if (length(recent))
    atol + rtol * max(abs(c(left[recent], right[recent]))) else NA_real_
  agreement <- length(recent) == 3L &&
    abs(tail(left[recent], 1L) - tail(right[recent], 1L)) <= tolerance
  stable <- length(recent) == 3L &&
    max(abs(c(diff(left[recent]), diff(right[recent])))) <= tolerance
  reference_match <- is.finite(estimate) && is.finite(exact$slope) &&
    abs(estimate - exact$slope) <= atol + rtol * abs(exact$slope)
  supported <- isTRUE(exact$exists && agreement && stable && reference_match)
  numerical_message <- if (!exact$exists) {
    "Read the exact explanation above; finite numerical samples alone do not prove a limit."
  } else if (supported) {
    "The usable left and right estimates agree, are stable, and match the analytical derivative within the stated tolerance."
  } else {
    "Numerical evidence is unresolved at these settings. This does not contradict the analytical derivative."
  }
  raw_error <- pmax(abs(raw_left - left), abs(raw_right - right))
  rounding <- any(valid & (is.na(raw_error) | !is.finite(raw_error) |
    raw_error > atol + rtol * pmax(abs(left), abs(right))), na.rm = TRUE)
  secant_x <- a + h
  secant <- stable_slope(choice, a, secant_x)
  warnings <- character()
  if (initial < abs(h)) warnings <- c(warnings,
    "Diagnostic samples were kept on the local branch so they do not cross the exceptional point at zero. The selected secant is unchanged.")
  if (any(!valid)) warnings <- c(warnings,
    "Samples with repeated coordinates, insufficient coordinate spacing, or nonfinite values were excluded.")
  if (rounding) warnings <- c(warnings,
    "Direct subtraction loses accuracy here. Stable algebraic slope formulas are used; the CSV retains both calculations for comparison.")
  if (!is.finite(secant)) warnings <- c(warnings,
    "The selected secant cannot be represented reliably. Change its increment to separate its endpoints.")
  data <- data.frame(
    requested_distance = distance, actual_left_distance = dl,
    actual_right_distance = dr, left_slope = left, right_slope = right,
    absolute_gap = abs(left - right), raw_left_slope = raw_left,
    raw_right_slope = raw_right, reference_derivative = exact$slope,
    usable = valid, check.names = FALSE
  )
  list(fa = fa, exact = exact, estimate = estimate, supported = supported,
       agreement = agreement, stable = stable, tolerance = tolerance,
       numerical_message = numerical_message, data = data,
       secant = secant, secant_x = secant_x, warnings = warnings,
       rtol = rtol, atol = atol)
}

library(shiny)

ui <- fluidPage(
  tags$head(tags$style(HTML("
    body{background:#f4f7fb;color:#193047} h2,h3{color:#173f65}
    .well{background:white;border-radius:12px}
    .tab-content{background:white;padding:20px;border-radius:0 0 12px 12px}
    .result{padding:15px;background:#eaf2fb;border-left:4px solid #286aa6;margin:15px 0}
    .caution{background:#fff6e8;border-color:#b56913}
    .table-wrap{overflow-x:auto} .small-note{color:#52667a;font-size:13px}
  "))),
  titlePanel("Differentiability Explorer"),
  p("Compare local slopes with the exact mathematics of five example functions."),
  sidebarLayout(
    sidebarPanel(
      selectInput("fun", "Choose a function", FUNCTION_LABELS),
      sliderInput("range", "Requested x-range", min = -5, max = 5,
                  value = c(-2, 2), step = 0.1),
      sliderInput("a", "Point a", min = -2, max = 2, value = 0, step = 0.01),
      sliderInput("logh", "Secant increment: log10(|h|)", min = -12, max = 0,
                  value = -1, step = 0.25),
      radioButtons("direction", "Secant direction",
                   c("Right (positive h)" = 1, "Left (negative h)" = -1)),
      textOutput("hvalue"),
      checkboxInput("secant", "Show selected secant", TRUE),
      checkboxInput("tangent", "Show exact tangent when a finite derivative exists", TRUE),
      checkboxInput("autofit", "Keep the secant endpoint in view", TRUE),
      actionButton("zero", "Set a = 0"),
      hr(),
      downloadButton("download", "Download diagnostic CSV"),
      helpText("The app separates exact mathematical conclusions from numerical evidence. All five examples have real domains; floating-point limits still apply.")
    ),
    mainPanel(tabsetPanel(
      tabPanel("Explore", plotOutput("graph", height = "440px"),
        uiOutput("conclusion"), h3("Values at the selected point"),
        div(class = "table-wrap", tableOutput("values")),
        h3("Numerical evidence"), uiOutput("numerical_status"),
        div(class = "table-wrap", tableOutput("convergence")),
        p(class = "small-note", "The table shows up to eight representative rows. Download the CSV for all samples and the direct-subtraction comparison. Decisions use unrounded values."),
        uiOutput("warning")),
      tabPanel("Theory",
        p("A function is differentiable at a point when the left and right difference quotients approach the same finite number. That number is the derivative and gives the slope of the tangent line."),
        p("Differentiability implies continuity, but continuity alone does not guarantee a derivative. The quadratic is smooth. Absolute value and the piecewise corner have unequal slopes at zero. Cube root is continuous at zero but has a vertical tangent and no finite derivative. The jump function is discontinuous there."),
        p("These conclusions follow from the formulas, not from rounded table entries. The app uses analytical derivatives as references and numerical calculations as supporting evidence. Finite sampling cannot prove differentiability for an arbitrary function.")),
      tabPanel("Help / Guide",
        tags$ol(
          tags$li("Choose a function and move point a. Use Set a = 0 to inspect its exceptional point."),
          tags$li("Compare the exact conclusion with the numerical evidence and the graph."),
          tags$li("Use the secant controls to compare two points. The exact tangent appears only where a finite derivative exists."),
          tags$li("Read excluded-sample and rounding notices. An unresolved numerical result does not mean a derivative fails to exist."),
          tags$li("Download the CSV to inspect unrounded calculations and both stable and direct-subtraction slopes.")
        ),
        p("The numerical support test uses absolute tolerance 1e-6 plus relative tolerance 1e-4 times the slope magnitude. It also checks the last three usable estimates. The known function formulas determine the exact conclusion."))
    ))
  )
)

server <- function(input, output, session) {
  observeEvent(input$range, {
    if (length(input$range) == 2L && all(is.finite(input$range)) && diff(input$range) > 0) {
      current <- if (is.null(input$a)) 0 else input$a
      updateSliderInput(session, "a", min = input$range[1], max = input$range[2],
        value = max(input$range[1], min(current, input$range[2])))
    }
  })
  observeEvent(input$zero, {
    req(input$range)
    if (input$range[1] <= 0 && input$range[2] >= 0)
      updateSliderInput(session, "a", value = 0)
  })
  h <- reactive({
    req(input$direction, input$logh)
    as.numeric(input$direction) * 10^input$logh
  })
  d <- reactive({
    req(input$fun, input$a, input$range)
    validate(
      need(input$fun %in% unname(FUNCTION_LABELS), "Choose a supported function."),
      need(length(input$range) == 2L && all(is.finite(input$range)) &&
        diff(input$range) > 0, "Choose a range with different endpoints."),
      need(length(input$a) == 1L && is.finite(input$a), "Choose a finite point."),
      need(input$a >= input$range[1] && input$a <= input$range[2],
           "Keep point a inside the selected interval."),
      need(is.finite(h()) && h() != 0, "Choose a finite, nonzero secant increment.")
    )
    diagnose(input$fun, input$a, h())
  })
  fmt <- function(x) ifelse(is.na(x), "Unavailable", formatC(x, digits = 10, format = "g"))
  output$hvalue <- renderText(paste("Selected h =", fmt(h())))
  output$conclusion <- renderUI({
    z <- d()
    div(class = "result", strong(if (z$exact$exists)
      "Differentiable at a - analytical result" else "Not differentiable at a - analytical result"),
      p(z$exact$reason), p(paste("Continuous at a:", if (z$exact$continuous) "Yes" else "No")))
  })
  output$values <- renderTable({
    z <- d()
    data.frame(Quantity = c("a", "f(a)", "Analytical derivative", "Selected secant slope",
                           "Numerical slope estimate"),
      Value = c(fmt(input$a), fmt(z$fa),
        if (z$exact$exists) fmt(z$exact$slope) else "Does not exist as a finite number",
        fmt(z$secant), if (z$supported) fmt(z$estimate) else "Unresolved / not applicable"))
  }, striped = TRUE, bordered = TRUE)
  output$numerical_status <- renderUI({
    z <- d()
    p(strong(if (z$supported) "Supported. " else if (z$exact$exists)
      "Unresolved. " else "Analytical explanation required. "), z$numerical_message)
  })
  output$convergence <- renderTable({
    data <- d()$data
    idx <- sort(unique(c(head(seq_len(nrow(data)), 2L),
                         tail(which(data$usable), 6L))))
    data.frame(`Sampling distance` = fmt(data$requested_distance[idx]),
      `Left slope` = fmt(data$left_slope[idx]), `Right slope` = fmt(data$right_slope[idx]),
      `Absolute gap` = fmt(data$absolute_gap[idx]),
      `Status` = ifelse(data$usable[idx], "Usable", "Excluded"), check.names = FALSE)
  }, striped = TRUE, bordered = TRUE)
  output$warning <- renderUI({
    z <- d()
    messages <- z$warnings
    outside <- is.finite(z$secant_x) &&
      (z$secant_x < input$range[1] || z$secant_x > input$range[2])
    if (isTRUE(input$secant) && outside) messages <- c(messages,
      if (isTRUE(input$autofit)) "The plot was widened to include the selected secant endpoint." else
        "The selected secant endpoint is outside the visible interval. Enable automatic fitting to see it.")
    if (length(messages)) div(class = "result caution", lapply(unique(messages), p))
  })
  output$download <- downloadHandler(
    filename = function() paste0("differentiability-", input$fun, ".csv"),
    content = function(file) {
      z <- d()
      data <- z$data
      data$function_id <- input$fun
      data$point_a <- input$a
      data$selected_h <- h()
      data$analytically_differentiable <- z$exact$exists
      data$absolute_tolerance <- z$atol
      data$relative_tolerance <- z$rtol
      # Explicit 17-digit formatting preserves double-precision values on reload.
      data[] <- lapply(data, function(column) {
        if (is.numeric(column)) {
          ifelse(is.na(column), NA_character_, sprintf("%.17g", column))
        } else column
      })
      write.csv(data, file, row.names = FALSE, na = "NA")
    }
  )
  output$graph <- renderPlot({
    z <- d()
    a <- input$a
    f <- function(x) function_value(x, input$fun)
    xr <- input$range
    if (isTRUE(input$secant) && isTRUE(input$autofit) && is.finite(z$secant))
      xr <- range(c(xr, z$secant_x))
    x <- sort(unique(c(seq(xr[1], xr[2], length.out = 1601), a,
      if (xr[1] <= 0 && xr[2] >= 0) 0)))
    y <- f(x)
    validate(need(any(is.finite(y)), "No finite function values in this interval."))
    yr <- range(y[is.finite(y)])
    pad <- max(0.2, diff(yr) * 0.12)
    plot(x, y, type = "n", xlim = xr, ylim = yr + c(-pad, pad),
         xlab = "x", ylab = "f(x)", main = "Function, selected secant, and exact tangent", las = 1)
    grid(col = "#e4e9ef")
    abline(h = 0, v = 0, col = "#bbc5cf")
    if (input$fun == "jump") {
      for (side in list(x[x < 0], x[x >= 0]))
        if (length(side) > 1L) lines(side, f(side), col = "#286aa6", lwd = 3)
      if (xr[1] <= 0 && xr[2] >= 0) {
        points(0, 0, pch = 21, bg = "white", col = "#286aa6", cex = 1.3)
        points(0, 1, pch = 19, col = "#286aa6", cex = 1.3)
      }
    } else lines(x, y, col = "#286aa6", lwd = 3)
    labels <- "Function"; cols <- "#286aa6"; types <- 1
    if (isTRUE(input$secant) && is.finite(z$secant)) {
      abline(a = z$fa - z$secant * a, b = z$secant, col = "#d47913", lty = 2, lwd = 2)
      points(z$secant_x, f(z$secant_x), pch = 19, col = "#d47913", cex = 1.2)
      labels <- c(labels, "Secant"); cols <- c(cols, "#d47913"); types <- c(types, 2)
    }
    if (isTRUE(input$tangent) && z$exact$exists && is.finite(z$exact$slope)) {
      abline(a = z$fa - z$exact$slope * a, b = z$exact$slope,
             col = "#238456", lty = 3, lwd = 2)
      labels <- c(labels, "Exact tangent"); cols <- c(cols, "#238456"); types <- c(types, 3)
    } else if (isTRUE(input$tangent) && input$fun == "vertical" && a == 0) {
      abline(v = 0, col = "#ad4c58", lty = 3, lwd = 2)
      labels <- c(labels, "Vertical tangent (no finite derivative)")
      cols <- c(cols, "#ad4c58"); types <- c(types, 3)
    }
    points(a, z$fa, pch = 19, cex = 1.4)
    legend("topleft", legend = labels, col = cols, lty = types,
           lwd = 2, bg = "white", cex = 0.78)
  })
}

shinyApp(ui, server)
