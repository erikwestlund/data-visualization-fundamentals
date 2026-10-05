# Figure 5: three views of days from drug start to first GI bleed.
library(framework)
scaffold()

tte <- data_read("data/characterization/time_to_event.csv")

# Cumulative percent of each cohort's bleeds by day, so cohorts of
# different sizes share one scale
tte_cum <- tte |>
  arrange(cohort, daysToEvent) |>
  group_by(cohort) |>
  mutate(pct = 100 * row_number() / n()) |>
  ungroup()

# Bleeds per week, by the day each week starts
tte_weekly <- tte |>
  mutate(week_start = 7 * floor(daysToEvent / 7)) |>
  count(cohort, week_start)

drug_colors <- c(Celecoxib = jhu_colors$HopkinsBlue, Diclofenac = jhu_colors$Green)
title <- "Days from drug start to first GI bleed"
subtitle <- "People with a GI bleed: 355 of 1,844 celecoxib users and 124 of 850 diclofenac users"

save_tte <- function(plot, name) {
  ggsave(sprintf("images/characterization/time-to-event-%s.png", name), plot,
         width = 10, height = 5.6, dpi = 200, device = ragg::agg_png)
}

day_axis <- scale_x_continuous(breaks = seq(0, 91, by = 14), limits = c(0, 91))
pct_axis <- scale_y_continuous(labels = \(x) paste0(x, "%"), limits = c(0, 100))

# 1. Histogram: counts per week, one panel per drug
p_histogram <- ggplot(tte, aes(x = daysToEvent, fill = cohort)) +
  geom_histogram(binwidth = 7, boundary = 0, closed = "left", color = "white") +
  facet_wrap(~cohort, ncol = 1) +
  scale_fill_manual(values = drug_colors, guide = "none") +
  day_axis +
  labs(title = title, subtitle = subtitle,
       x = "Days since drug start", y = "People (per week)") +
  theme_jhu() +
  theme(strip.text = element_text(size = 13, face = "bold", hjust = 0))
save_tte(p_histogram, "histogram")

# 2. Weekly counts as connected lines on one panel, colored by drug
p_lines <- ggplot(tte_weekly, aes(x = week_start, y = n, color = cohort)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  geom_text(data = \(d) slice_max(d, week_start, by = cohort),
            aes(label = cohort), hjust = -0.15, fontface = "bold", size = 4.5) +
  scale_color_manual(values = drug_colors, guide = "none") +
  scale_x_continuous(breaks = seq(0, 91, by = 14), limits = c(0, 100)) +
  expand_limits(y = 0) +
  labs(title = title, subtitle = subtitle,
       x = "Days since drug start (week starting)", y = "People (per week)") +
  theme_jhu()
save_tte(p_lines, "lines")

# 3. Weekly counts as connected lines, one panel per drug
p_facets <- ggplot(tte_weekly, aes(x = week_start, y = n, color = cohort)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2.5) +
  facet_wrap(~cohort, ncol = 1) +
  scale_color_manual(values = drug_colors, guide = "none") +
  day_axis +
  expand_limits(y = 0) +
  labs(title = title, subtitle = subtitle,
       x = "Days since drug start (week starting)", y = "People (per week)") +
  theme_jhu() +
  theme(strip.text = element_text(size = 13, face = "bold", hjust = 0))
save_tte(p_facets, "facets")

# 4. Cumulative percent of each cohort's bleeds on one panel
p_cumulative <- ggplot(tte_cum, aes(x = daysToEvent, y = pct, color = cohort)) +
  geom_step(linewidth = 1) +
  geom_text(data = \(d) slice_max(d, daysToEvent, by = cohort, with_ties = FALSE),
            aes(label = cohort), hjust = -0.1, vjust = c(1.5, -0.5),
            fontface = "bold", size = 4.5) +
  scale_color_manual(values = drug_colors, guide = "none") +
  scale_x_continuous(breaks = seq(0, 91, by = 14), limits = c(0, 105)) +
  pct_axis +
  labs(title = title, subtitle = subtitle,
       x = "Days since drug start", y = "Cumulative percent of bleeds") +
  theme_jhu()
save_tte(p_cumulative, "cumulative")
