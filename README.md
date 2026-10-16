# Differentiability Explorer

**Nicholas A. Bowen · Mathematics in AI · Project 3**

An interactive R Shiny project explaining the relationship between continuity,
tangent lines, and differentiability. The portfolio brings the application,
mathematical modeling report, and complete source code together.

## Project materials

- [Read the mathematical modeling report](files/modeling-report.pdf)
- [View the complete R Shiny source](app.R)
- [Read the application refinements](APP_UPDATES.md)
- [Set up the portfolio website with GitHub Pages](GITHUB_SETUP.md)

The portfolio website includes an interactive illustration of the five functions,
a PDF reader and download, a syntax-colored R source viewer, and instructions for
running the full Shiny app. Its relative file paths work with a GitHub Pages
project website.

## The mathematical question

A function is differentiable at a point when its difference quotients approach
the same finite value from both sides. Continuity is necessary, but it does not
by itself guarantee differentiability.

At zero, the included functions illustrate the following cases:

| Function | Continuous at zero? | Derivative at zero |
| --- | --- | --- |
| Quadratic, x² | Yes | Exists and equals 0 |
| Absolute value, \|x\| | Yes | Does not exist: slopes −1 and +1 |
| Cube root, ∛x | Yes | No finite derivative: vertical tangent |
| Piecewise corner, −x below zero and 2x otherwise | Yes | Does not exist: slopes −1 and +2 |
| Jump, 0 below zero and 1 otherwise | No | Does not exist: discontinuity |

Away from zero, the four nonsmooth examples have ordinary derivatives on their
smooth branches. The application lets the user inspect the function, point,
secant, tangent, and numerical evidence together.

## Run the full Shiny application

1. Download `app.R` and open it in RStudio.
2. In the R console, install Shiny once:

   ```r
   install.packages("shiny")
   ```

3. With `app.R` open, click **Run App**.

The full application runs in R. The portfolio's browser illustration uses exact
formulas and does not replace the Shiny application's numerical diagnostics.
GitHub Pages hosts the HTML, CSS, JavaScript, PDF, and downloadable R source;
it does not run the R server.

## Numerical refinements

The current code separates analytical conclusions from numerical evidence. It
uses stable divided differences, excludes unusable floating-point samples, keeps
diagnostic samples on the local smooth branch near zero, and distinguishes
unresolved evidence from mathematical failure. A CSV download preserves the
sample distances, stable and direct-subtraction slopes, references, and
tolerances. The graph can automatically include the selected secant endpoint.

The PDF is preserved as supplied and documents the original project analysis.
The subsequent refinements are documented in [APP_UPDATES.md](APP_UPDATES.md).

## Repository contents

| File or folder | Purpose |
| --- | --- |
| `index.html` | Portfolio homepage |
| `styles.css` | Responsive page styling |
| `app.mjs`, `models.mjs` | Portfolio controls and exact mathematical illustration |
| `source-data.mjs` | Code viewer content generated from app.R |
| `app.R` | Complete R Shiny application |
| `files/modeling-report.pdf` | Six-page modeling report |
| `assets/` | Report cover and site icon |
| `tests/` | Mathematical, reactive, rendering, and portfolio interaction checks |
| `tools/update-source.py` | Refresh the code viewer after editing app.R |
| `GITHUB_SETUP.md` | Browser upload and GitHub Pages instructions |

## Validation and maintenance

From the repository folder:

```sh
Rscript tests/test_app.R
node tests/test_portfolio.mjs
node --check app.mjs
```

The R checks cover the five analytical cases, nearby smooth branches,
floating-point cancellation, unusable coordinates, invalid inputs, Shiny
reactive outputs, and plot rendering. The portfolio checks cover the function
geometry, controls, keyboard navigation, and exact source copying using a DOM
fixture. They are not a browser visual test.

After editing `app.R`, run:

```sh
python tools/update-source.py
```

Commit both `app.R` and the regenerated `source-data.mjs` so the code viewer
matches the downloadable application.

## Scope

The analytical conclusions and stable identities apply to the five included
functions. Finite sampling does not prove differentiability for an arbitrary
function. Adding another function requires its domain, special points,
analytical reference, and suitable numerical treatment. The project does not
measure student learning outcomes.
