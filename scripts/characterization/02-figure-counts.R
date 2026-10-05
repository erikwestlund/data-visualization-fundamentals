# Figure 1: how many people are in each cohort? Plain draft vs polished.
library(framework)
scaffold()

counts <- data_read("data/characterization/cohort_counts.csv")

# ---- Plain: the first thing ggplot gives you --------------------------------
p_plain <- ggplot(counts, aes(x = cohort, y = persons)) +
  geom_col() +
  theme_gray()

ggsave("images/characterization/counts-plain.png", p_plain,
       width = 10, height = 5.6, dpi = 200, device = ragg::agg_png)

# ---- Polished: ordered, horizontal, labelled -------------------------------
p_polished <- ggplot(counts, aes(x = persons, y = reorder(cohort, persons))) +
  geom_col(fill = jhu_colors$HopkinsBlue, width = 0.6) +
  geom_text(aes(label = scales::comma(persons)), hjust = -0.2, size = 5) +
  scale_x_continuous(expand = expansion(mult = c(0, 0.12)), labels = scales::comma) +
  labs(
    title = "Celecoxib users outnumber diclofenac users about 2 to 1",
    subtitle = "People in each cohort, Eunomia GiBleed (synthetic data)",
    x = "People", y = NULL
  ) +
  theme_jhu() +
  theme(axis.text.y = element_text(size = 14), panel.grid.major.y = element_blank())

ggsave("images/characterization/counts-polished.png", p_polished,
       width = 10, height = 5.6, dpi = 200, device = ragg::agg_png)
