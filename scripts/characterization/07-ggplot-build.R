# Figure 6: building one plot layer by layer (grammar of graphics).
library(framework)
scaffold()

ir <- data_read("data/characterization/incidence_age_sex.csv") |>
  mutate(age_group = factor(age_group, levels = c("30-34", "35-39", "40-44", "45-49")))

save_step <- function(plot, step) {
  ggsave(sprintf("images/characterization/ggplot-build-%d.png", step), plot,
         width = 8, height = 5, dpi = 200, device = ragg::agg_png)
}

# 1. Data + aesthetic mapping: axes, but nothing drawn yet
p1 <- ggplot(ir, aes(x = age_group, y = ir_per_1000py))
save_step(p1, 1)

# 2. + a geometry: one point per row
p2 <- p1 + geom_point()
save_step(p2, 2)

# 3. + color by sex, lines, and one panel per drug
p3 <- p2 +
  aes(color = sex, group = sex) +
  geom_line() +
  facet_wrap(~cohort)
save_step(p3, 3)

# 4. + labels, colors and a theme
p4 <- p3 +
  scale_color_manual(values = c(Female = jhu_colors$Purple, Male = jhu_colors$BlueLight)) +
  labs(
    title = "GI bleed incidence by age and sex",
    x = "Age at drug start", y = "Per 1,000 person-years", color = NULL
  ) +
  expand_limits(y = 0) +
  theme_jhu() +
  theme(legend.position = "top", strip.text = element_text(size = 12, face = "bold"))
save_step(p4, 4)
