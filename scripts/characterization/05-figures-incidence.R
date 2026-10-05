# Figure 4: GI bleed incidence rate by age group and sex, both drug cohorts.
# Source: CohortIncidence, time at risk = 365 days from drug start.
library(framework)
scaffold()

age_labels <- c("<35" = "30-34", "35 - 39" = "35-39", "40 - 44" = "40-44", ">=45" = "45-49")

ir <- data_read("data/characterization/incidence_summary.csv") |>
  filter(is.na(start_year), !is.na(age_group_name), !is.na(sex)) |>
  mutate(
    age_group = factor(age_labels[age_group_name], levels = age_labels),
    # exact Poisson 95% CI for the rate
    lower = 1000 * qchisq(0.025, 2 * outcomes) / 2 / person_years,
    upper = 1000 * qchisq(0.975, 2 * (outcomes + 1)) / 2 / person_years
  )
data_save(ir, "data/characterization/incidence_age_sex.csv", force = TRUE)

# ---- Plain: default dodged bars --------------------------------------------
# Defaults only: text age groups sort alphabetically, four colors to decode.
p_plain <- ggplot(ir, aes(x = age_group_name, y = ir_per_1000py,
                          fill = paste(cohort, sex))) +
  geom_col(position = "dodge")

ggsave("images/characterization/incidence-plain.png", p_plain,
       width = 10, height = 5.6, dpi = 200, device = ragg::agg_png)

# ---- Workhorse: ordered ages, one panel per sex, axis from zero -------------
p_workhorse <- ggplot(ir, aes(x = age_group, y = ir_per_1000py, color = cohort)) +
  geom_line(aes(group = cohort)) +
  geom_point() +
  facet_wrap(~sex) +
  expand_limits(y = 0)

ggsave("images/characterization/incidence-workhorse.png", p_workhorse,
       width = 10, height = 5.6, dpi = 200, device = ragg::agg_png)

# ---- Show pony: the workhorse with direct labels, colors, titles, theme -----
drug_colors <- c(Celecoxib = jhu_colors$HopkinsBlue, Diclofenac = jhu_colors$Green)

p_polished <- p_workhorse +
  geom_text(data = \(d) filter(d, age_group == "45-49"), aes(label = cohort),
            hjust = -0.25, fontface = "bold", size = 4.5) +
  scale_color_manual(values = drug_colors, guide = "none") +
  scale_x_discrete(expand = expansion(add = c(0.4, 1.3))) +
  labs(
    title = "Celecoxib users bled more often in most age-sex groups",
    subtitle = "GI bleeds per 1,000 person-years in the year after drug start (age 45-49: under 10 bleeds per group)",
    x = "Age at drug start", y = "GI bleeds per 1,000 person-years"
  ) +
  theme_jhu() +
  theme(strip.text = element_text(size = 13, face = "bold"))

ggsave("images/characterization/incidence-polished.png", p_polished,
       width = 10, height = 5.6, dpi = 200, device = ragg::agg_png)
