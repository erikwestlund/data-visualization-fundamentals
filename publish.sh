#!/usr/bin/env bash
# Render the deck and copy it to docs/index.html for GitHub Pages.
set -euo pipefail
cd "$(dirname "$0")"

deck="2026-10-07-fundamentals-data-visualization"

quarto render "$deck.qmd"
mkdir -p docs
cp "$deck.html" docs/index.html
touch docs/.nojekyll
