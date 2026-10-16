# Differentiability Explorer: app.R refinements

The updated app keeps the five original function examples and runs as one R Shiny file.

## Changes

- **Separate exact answers from numerical evidence.** The formulas determine whether a derivative exists for the five included functions. Numerical results have a separate supported or unresolved status. Unresolved evidence no longer produces a false mathematical classification.
- **Reduce cancellation.** Algebraically equivalent divided differences are used for the quadratic, cube root, and constant-slope branches. Calculations use the actual floating-point separation between coordinates.
- **Exclude unusable samples.** Repeated coordinates, insufficient coordinate spacing, and nonfinite values are excluded from the convergence checks.
- **Respect local behavior.** Near the exceptional point at zero, diagnostic samples stay on the selected point's smooth branch. The user's selected secant remains unchanged.
- **Show exact tangent lines.** Ordinary tangents use the analytical derivative. A cube-root vertical tangent is explicitly identified as having no finite derivative.
- **Clarify numerical tolerances.** Support requires agreement, stability among three recent usable samples, and agreement with the analytical reference. The default absolute tolerance is 1e-6 and relative tolerance is 1e-4. These are computational settings, not a definition of differentiability.
- **Make results inspectable.** CSV exports include stable and direct-subtraction slopes, actual sample distances, excluded rows, the analytical reference, and tolerances. Numeric exports use 17 significant digits.
- **Improve the graph.** An optional automatic fit keeps the selected secant endpoint visible. The jump is drawn with separate branches and correct open and closed endpoints.
- **Validate inputs and correct explanatory text.** Invalid intervals and nonfinite or zero secant increments are rejected with clear messages. The Theory and Help tabs distinguish continuity, corners, vertical tangents, and discontinuities.

## Scope

The analytical conclusions and stable identities are specific to these five known functions. Finite sampling does not establish a derivative for an arbitrary function. Adding a new function requires its domain, special points, analytical reference, and suitable numerical treatment. This project has not measured student learning outcomes.

## Run

1. Save the file as `app.R`.
2. In RStudio, run `install.packages("shiny")` once.
3. Open `app.R` and click **Run App**.

The accompanying modeling PDF is preserved as supplied; it describes the original analysis. These notes document the subsequent code improvements.
