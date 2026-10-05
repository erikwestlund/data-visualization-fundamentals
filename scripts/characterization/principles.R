# Figures for the visualization-principles slides in the characterization deck:
# pie vs. common-scale bars, and a truncated vs. full y axis.
# Uses small illustrative numbers, not Eunomia.

library(framework)
scaffold()

library(patchwork)

out_dir <- "images/characterization"

save_slide <- function(plot, file, width = 10, height = 5.6) {
  ggsave(file.path(out_dir, file), plot,
         width = width, height = height, dpi = 200, device = ragg::agg_png)
}

# Pie vs. bars ---------------------------------------------------------------
# Five similar shares: hard to rank as wedges, easy to rank as bars.
shares <- tibble(
  drug = c("Drug A", "Drug B", "Drug C", "Drug D", "Drug E"),
  pct = c(23, 21, 20, 19, 17)
)

pie <- ggplot(shares, aes(x = "", y = pct, fill = drug)) +
  geom_col(width = 1, color = "white") +
  coord_polar(theta = "y") +
  scale_fill_manual(values = unname(unlist(jhu_colors[c(
    "HopkinsBlue", "Blue", "BlueLight", "Teal", "Tan"
  )]))) +
  labs(title = "Which drug is used most?", fill = NULL) +
  theme_void(base_family = "Tahoma") +
  theme(plot.title = element_text(hjust = 0.5, face = "bold", size = 16))

bars <- ggplot(shares, aes(x = pct, y = reorder(drug, pct))) +
  geom_col(fill = jhu_colors$HopkinsBlue, width = 0.7) +
  geom_text(aes(label = paste0(pct, "%")), hjust = -0.2, size = 5) +
  scale_x_continuous(limits = c(0, 27), expand = c(0, 0)) +
  labs(title = "Same data, common scale", x = "Share of users (%)", y = NULL) +
  theme_jhu()

save_slide(pie + bars, "principle-pie-vs-bars.png")

# Truncated vs. full axis ----------------------------------------------------
rates <- tibble(
  group = c("Cohort A", "Cohort B"),
  rate = c(10.4, 11.1)
)

truncated <- ggplot(rates, aes(x = group, y = rate)) +
  geom_col(fill = jhu_colors$Purple, width = 0.6) +
  coord_cartesian(ylim = c(10, 11.2)) +
  labs(title = "Axis starts at 10: a big gap?", x = NULL,
       y = "Events per 1,000 person-years") +
  theme_jhu()

full <- ggplot(rates, aes(x = group, y = rate)) +
  geom_col(fill = jhu_colors$HopkinsBlue, width = 0.6) +
  scale_y_continuous(limits = c(0, 12), expand = c(0, 0)) +
  labs(title = "Axis starts at 0: about the same", x = NULL,
       y = "Events per 1,000 person-years") +
  theme_jhu()

save_slide(truncated + full, "principle-honest-axis.png")

# Meaningful order -----------------------------------------------------------
# The same prevalences in alphabetical order and sorted by value.
conditions <- tibble(
  condition = c("Anemia", "Asthma", "Depression", "Diabetes", "GERD",
                "Hyperlipidemia", "Hypertension", "Osteoarthritis"),
  pct = c(6, 9, 14, 11, 8, 22, 31, 18)
)

alphabetical <- ggplot(conditions, aes(x = pct, y = factor(condition, levels = rev(sort(condition))))) +
  geom_col(fill = jhu_colors$Gray3, width = 0.7) +
  labs(title = "Alphabetical order", x = "Prevalence (%)", y = NULL) +
  theme_jhu()

sorted <- ggplot(conditions, aes(x = pct, y = reorder(condition, pct))) +
  geom_col(fill = jhu_colors$HopkinsBlue, width = 0.7) +
  labs(title = "Sorted by value", x = "Prevalence (%)", y = NULL) +
  theme_jhu()

save_slide(alphabetical + sorted, "principle-order.png")

# Direct labels --------------------------------------------------------------
# Four drugs' new users per year, with a legend and with labels on the lines.
drug_colors <- c(
  "Drug A" = jhu_colors$HopkinsBlue, "Drug B" = jhu_colors$BlueLight,
  "Drug C" = jhu_colors$Purple, "Drug D" = jhu_colors$Green
)

uptake <- expand_grid(drug = names(drug_colors), year = 2016:2024) |>
  mutate(
    users = case_when(
      drug == "Drug A" ~ 900 - 40 * (year - 2016),
      drug == "Drug B" ~ 300 + 70 * (year - 2016),
      drug == "Drug C" ~ 600 + 10 * (year - 2016),
      drug == "Drug D" ~ 150 + 25 * (year - 2016)
    )
  )

with_legend <- ggplot(uptake, aes(x = year, y = users, color = drug)) +
  geom_line(linewidth = 1.1) +
  scale_color_manual(values = drug_colors) +
  expand_limits(y = 0) +
  labs(title = "Legend", x = NULL, y = "New users", color = NULL) +
  theme_jhu() +
  theme(legend.position = "right")

with_labels <- ggplot(uptake, aes(x = year, y = users, color = drug)) +
  geom_line(linewidth = 1.1) +
  geom_text(data = filter(uptake, year == max(year)),
            aes(label = drug), hjust = -0.15, size = 4.5, fontface = "bold") +
  scale_color_manual(values = drug_colors, guide = "none") +
  scale_x_continuous(limits = c(2016, 2026), breaks = seq(2016, 2024, 2)) +
  expand_limits(y = 0) +
  labs(title = "Labels on the lines", x = NULL, y = "New users") +
  theme_jhu()

save_slide(with_legend + with_labels, "principle-direct-labels.png")

# Small multiples ------------------------------------------------------------
# Monthly incidence in six databases: one tangled panel vs. one panel each.
set.seed(20261005)
databases <- paste("Database", LETTERS[1:6])
monthly <- expand_grid(database = databases, month = 1:36) |>
  mutate(
    base = c(4, 6, 5, 3, 7, 5)[match(database, databases)],
    trend = c(0.02, -0.03, 0, 0.05, -0.01, 0)[match(database, databases)],
    # Database E has a coding change at month 18
    jump = if_else(database == "Database E" & month >= 18, -3, 0),
    rate = base + trend * month + jump + rnorm(n(), 0, 0.35)
  )

db_colors <- setNames(
  unname(unlist(jhu_colors[c("HopkinsBlue", "BlueLight", "Purple", "Green", "Tan", "Gray3")])),
  databases
)

tangled <- ggplot(monthly, aes(x = month, y = rate, color = database)) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = db_colors) +
  expand_limits(y = 0) +
  labs(title = "One panel", x = "Month", y = "Per 1,000 person-years", color = NULL) +
  theme_jhu() +
  theme(legend.position = "bottom", legend.text = element_text(size = 8))

multiples <- ggplot(monthly, aes(x = month, y = rate)) +
  geom_line(color = jhu_colors$HopkinsBlue, linewidth = 0.8) +
  facet_wrap(~database, ncol = 3) +
  expand_limits(y = 0) +
  labs(title = "One panel per database", x = "Month", y = "Per 1,000 person-years") +
  theme_jhu() +
  theme(strip.text = element_text(size = 10, face = "bold"))

save_slide(tangled + multiples, "principle-small-multiples.png")

# Color to highlight ---------------------------------------------------------
# Cohort size in eight databases: a color per bar vs. one highlighted bar.
sites <- tibble(
  database = c("REACH", paste("Database", LETTERS[1:7])),
  persons = c(4200, 8100, 6500, 5900, 3800, 3100, 2400, 1700)
)

rainbow <- ggplot(sites, aes(x = persons, y = reorder(database, persons), fill = database)) +
  geom_col(width = 0.7) +
  scale_fill_manual(values = unname(unlist(jhu_colors[c(
    "HopkinsBlue", "Blue", "BlueLight", "Purple", "LightPurple", "Teal", "Green", "Tan"
  )])), guide = "none") +
  labs(title = "A color for every bar", x = "Persons in cohort", y = NULL) +
  theme_jhu()

highlight <- ggplot(sites, aes(x = persons, y = reorder(database, persons),
                               fill = database == "REACH")) +
  geom_col(width = 0.7) +
  scale_fill_manual(values = c(`TRUE` = jhu_colors$HopkinsBlue, `FALSE` = jhu_colors$Gray1),
                    guide = "none") +
  labs(title = "Color only for REACH", x = "Persons in cohort", y = NULL) +
  theme_jhu()

save_slide(rainbow + highlight, "principle-highlight.png")

# Title states the finding ---------------------------------------------------
# The same bars under a topic title and under a finding title.
bleeds <- tibble(
  drug = c("Drug A", "Drug B", "Drug C"),
  rate = c(4.1, 8.3, 4.6)
)

bleed_bars <- function(title) {
  ggplot(bleeds, aes(x = drug, y = rate)) +
    geom_col(fill = if_else(bleeds$drug == "Drug B", jhu_colors$Purple, jhu_colors$Gray2),
             width = 0.6) +
    scale_y_continuous(limits = c(0, 10), expand = c(0, 0)) +
    labs(title = title, x = NULL, y = "GI bleeds per 1,000 person-years") +
    theme_jhu() +
    theme(plot.title = element_text(size = 14))
}

topic_title <- bleed_bars("GI bleed rate by drug")
finding_title <- bleed_bars("Drug B users bleed about twice as often")

save_slide(topic_title + finding_title, "principle-title.png")
