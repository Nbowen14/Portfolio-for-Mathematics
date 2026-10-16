"""Regenerate the portfolio code viewer after editing app.R."""
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
lines = (root / "app.R").read_text(encoding="utf-8").splitlines(keepends=True)


def find(prefix):
    return next(i for i, line in enumerate(lines) if line.startswith(prefix))


models = find("FUNCTION_LABELS <-")
diagnostics = find("stable_slope <-")
interface = find("ui <-")
server = find("server <-")
library = find("library(shiny)")
sections = {
    "models": (models, diagnostics - 2, "The five function definitions and analytical derivatives provide a mathematical reference for each selected point."),
    "diagnostics": (diagnostics, library, "Stable divided differences, local sampling, precision guards, and explicit convergence checks."),
    "interface": (interface, server, "The Shiny interface connects function selection, graph controls, diagnostic tables, and explanatory tabs."),
    "server": (server, len(lines), "Reactive expressions recalculate results and graphs, validate inputs, and export the full diagnostic CSV."),
    "full": (0, len(lines), "The complete application. Save as app.R, install shiny, and click Run App in RStudio."),
}
data = {
    "lineCount": len(lines),
    "sections": {
        key: {"start": start + 1, "code": "".join(lines[start:end]), "description": description}
        for key, (start, end, description) in sections.items()
    },
}
encoded = json.dumps(data, ensure_ascii=True).replace("<", "\\u003c")
(root / "source-data.mjs").write_text("export default " + encoded + ";\n", encoding="utf-8")
print(f"Updated code viewer from {len(lines)} lines of app.R.")
