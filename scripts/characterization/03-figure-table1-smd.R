# Figure 2: "Table 1" as a picture -- standardized mean differences (SMD),
# celecoxib vs diclofenac, for a hand-picked set of baseline covariates.
library(framework)
scaffold()

smd_all <- data_read("data/characterization/smd_all_covariates.csv")

# Covariates to show (FeatureExtraction covariate ids), with a short label
picked <- tribble(
  ~covariateId, ~covariate,                  ~domain,
  8532001,      "Female",                    "Demographics",
  6003,         "Age 30-34",                 "Demographics",
  7003,         "Age 35-39",                 "Demographics",
  8003,         "Age 40-44",                 "Demographics",
  9003,         "Age 45-49",                 "Demographics",
  4285898210,   "Polyp of colon",            "Condition",
  30753210,     "Esophagitis",               "Condition",
  81893210,     "Ulcerative colitis",        "Condition",
  4310024210,   "Angiodysplasia of stomach", "Condition",
  4112343210,   "Acute viral pharyngitis",   "Condition",
  4283893210,   "Sinusitis",                 "Condition",
  260139210,    "Acute bronchitis",          "Condition",
  372328210,    "Otitis media",              "Condition",
  81151210,     "Sprain of ankle",           "Condition",
  1125315410,   "Acetaminophen",             "Drug",
  1713332410,   "Amoxicillin",               "Drug",
  1177480410,   "Ibuprofen",                 "Drug",
  1115008410,   "Naproxen",                  "Drug",
  1112807410,   "Aspirin",                   "Drug",
  1322184410,   "Clopidogrel",               "Drug"
)

# FeatureExtraction's stdDiff is (comparator - target) / pooled SD;
# flip the sign so positive = more common in celecoxib.
table1 <- picked |>
  left_join(smd_all, by = "covariateId") |>
  transmute(
    covariate, domain,
    pct_celecoxib = round(100 * mean1, 1),
    pct_diclofenac = round(100 * mean2, 1),
    smd = round(-stdDiff, 3)
  )
data_save(table1, "data/characterization/table1_smd.csv", force = TRUE)

# ---- Plot ------------------------------------------------------------------
p <- ggplot(table1, aes(x = smd, y = reorder(covariate, smd))) +
  annotate("rect", xmin = -0.1, xmax = 0.1, ymin = -Inf, ymax = Inf,
           fill = jhu_colors$Gray1, alpha = 0.6) +
  geom_vline(xintercept = 0, color = jhu_colors$Gray3) +
  geom_point(aes(color = abs(smd) > 0.1), size = 3.5) +
  scale_color_manual(values = c(`FALSE` = jhu_colors$Gray3, `TRUE` = jhu_colors$HopkinsBlue),
                     guide = "none") +
  labs(
    title = "Celecoxib users had more prior GI disease than diclofenac users",
    subtitle = "Standardized mean difference; shaded band = |SMD| < 0.1 (\"balanced\")",
    x = "SMD (positive = more common in celecoxib)", y = NULL
  ) +
  theme_jhu()

ggsave("images/characterization/table1-smd-plot.png", p,
       width = 10, height = 5.6, dpi = 200, device = ragg::agg_png)
