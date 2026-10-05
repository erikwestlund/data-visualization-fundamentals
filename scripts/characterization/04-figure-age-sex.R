# Figure 3: four views of the same age-by-sex data for both drug cohorts.
library(framework)
scaffold()

age_sex <- data_read("data/characterization/age_sex_counts.csv") |>
  group_by(cohort) |>
  mutate(
    pct = 100 * persons / sum(persons),
    age = paste0(ageGroup, "-", ageGroup + 4),
    pct_signed = if_else(sex == "Female", -pct, pct)  # females to the left
  ) |>
  ungroup()

sex_colors <- c(Female = jhu_colors$Purple, Male = jhu_colors$BlueLight)
title <- "Age and sex distribution by cohort"
subtitle <- "Percent of each cohort by age group and sex at drug start"

save_age_sex <- function(plot, name) {
  ggsave(sprintf("images/characterization/age-sex-%s.png", name), plot,
         width = 10, height = 5.6, dpi = 200, device = ragg::agg_png)
}

theme_age_sex <- function() {
  theme_jhu() +
    theme(legend.position = "top", strip.text = element_text(size = 13, face = "bold"))
}

# 1. Stacked bars: women and men stacked within each age group
p_stacked <- ggplot(age_sex, aes(x = age, y = pct, fill = sex)) +
  geom_col(width = 0.7) +
  facet_wrap(~cohort) +
  scale_fill_manual(values = sex_colors) +
  scale_y_continuous(labels = \(x) paste0(x, "%")) +
  labs(
    title = title,
    subtitle = subtitle,
    x = "Age (years)", y = "Percent of cohort", fill = NULL
  ) +
  theme_age_sex()
save_age_sex(p_stacked, "stacked")

# 2. Pyramid: women to the left, men to the right
p_pyramid <- ggplot(age_sex, aes(x = pct_signed, y = age, fill = sex)) +
  geom_col(width = 0.8) +
  geom_text(aes(label = sprintf("%.0f%%", pct),
                hjust = if_else(sex == "Female", 1.15, -0.15)), size = 3.8) +
  facet_wrap(~cohort) +
  scale_x_continuous(labels = \(x) paste0(abs(x), "%"), limits = c(-30, 30)) +
  scale_fill_manual(values = sex_colors) +
  labs(
    title = title,
    subtitle = subtitle,
    x = "Percent of cohort", y = "Age (years)", fill = NULL
  ) +
  theme_age_sex()
save_age_sex(p_pyramid, "pyramid")

# 3. Facets: one panel per cohort and sex
p_faceted <- ggplot(age_sex, aes(x = pct, y = age, fill = sex)) +
  geom_col(width = 0.7) +
  geom_text(aes(label = sprintf("%.0f%%", pct)), hjust = -0.15, size = 3.8) +
  facet_grid(sex ~ cohort) +
  scale_x_continuous(labels = \(x) paste0(x, "%"), limits = c(0, 30)) +
  scale_fill_manual(values = sex_colors, guide = "none") +
  labs(
    title = title,
    subtitle = subtitle,
    x = "Percent of cohort", y = "Age (years)"
  ) +
  theme_age_sex()
save_age_sex(p_faceted, "faceted")

# 4. Connected dot plot: women and men side by side on one scale
p_dotplot <- ggplot(age_sex, aes(x = pct, y = age)) +
  geom_line(aes(group = age), color = jhu_colors$Gray2, linewidth = 1.2) +
  geom_point(aes(color = sex), size = 4) +
  facet_wrap(~cohort) +
  scale_x_continuous(labels = \(x) paste0(x, "%"), limits = c(0, NA)) +
  scale_color_manual(values = sex_colors) +
  labs(
    title = title,
    subtitle = subtitle,
    x = "Percent of cohort", y = "Age (years)", color = NULL
  ) +
  theme_age_sex()
save_age_sex(p_dotplot, "dotplot")
