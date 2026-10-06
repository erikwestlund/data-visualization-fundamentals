# Data Visualization Fundamentals

This file provides guidance to AI assistants working with this Framework project.
It is the canonical context file; detailed workflow instructions live in the
skills listed below. Edit the sections without regeneration markers freely -
they won't be overwritten.


## Skills

Detailed instructions live in skill files, loaded on demand. Claude Code discovers
them automatically; other agents should read the relevant SKILL.md before working
on a matching task.

| Skill | Covers | Path |
|-------|--------|------|
| `framework-workflow` | scaffold() initialization, critical rules, creating notebooks/scripts | `.claude/skills/framework-workflow/SKILL.md` |
| `framework-data` | reading and saving data (data_read/data_save are mandatory) | `.claude/skills/framework-data/SKILL.md` |
| `framework-packages` | adding and managing R packages (package_add, never install.packages) | `.claude/skills/framework-packages/SKILL.md` |
| `framework-outputs` | results, caching, database queries, publishing | `.claude/skills/framework-outputs/SKILL.md` |

## Framework Environment <!-- @framework:regenerate -->

This project uses Framework for reproducible data analysis. **Every notebook and script
MUST begin with `scaffold()`** which initializes the environment.

### What scaffold() Does

When you call `scaffold()`, it automatically:

1. **Sets the working directory** to the project root (handles nested notebook execution)
2. **Loads environment variables** from `.env` (database credentials, API keys)
3. **Installs missing packages** listed in settings.yml
4. **Attaches packages** marked with `auto_attach: true` (see Packages section below)
5. **Sources all functions** from `functions/` directory - they are globally available
6. **Sets ggplot2 theme** to `theme_minimal()`

### CRITICAL RULES

**DO NOT** call `library()` for packages listed in the auto-attach section below.
They are already loaded by scaffold(). Calling library() again wastes time and clutters output.

**DO NOT** use `source()` to load functions from the functions/ directory.
They are auto-loaded by scaffold(). Just call them directly.


## Installed Packages <!-- @framework:regenerate -->

**Auto-attached** (loaded by scaffold): dplyr, ggplot2, tidyr, stringr, readr
**Installed** (call library() when needed): lubridate, glue, here

Add packages with `package_add("name")` or `package_add("name", auto_attach = TRUE)`.

## Data Management <!-- @framework:regenerate -->

**All data I/O MUST use `data_read()` and `data_save()`** - see the
`framework-data` skill for the full rules. This project's data directories:

| Purpose | Directory |
|---------|-----------|
| Data files | `data/` |
| Output files | `outputs/` |


## Presentation Workflow

This is a presentation project with minimal structure.

### Decks

| Date | File | Talk |
|------|------|------|
| Wed 10/7 | `2026-10-07-fundamentals-data-visualization.qmd` | Fundamentals of Data Visualization (ICTR seminar series, 60 min) |

Shared styling: `assets/jhu.scss` (revealjs) and `functions/theme_jhu.R` (ggplot).
Code is shown, never run: `_quarto.yml` sets `eval: false`. Shared images live in
`images/shared/`. Deck figures live in `images/fundamentals/`; `figures-notebook.qmd`
(which sets `eval: true`) regenerates all of them from the CSVs in `data/`, which come
from the course repo `erikwestlund/data-visualization-2026`.

### Rendering

```bash
quarto render 2026-10-07-fundamentals-data-visualization.qmd
```

### Creating Additional Presentations

```r
make_notebook("backup-slides", stub = "revealjs")
```


## Project Notes

*Add your project-specific notes, conventions, and documentation here.*
*This section is never modified by `ai_regenerate_context()`.*

