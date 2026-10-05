# Run HADES characterization on Eunomia GiBleed and save the tables we plot.
#   Cohorts (Eunomia::createCohorts): 1 celecoxib, 2 diclofenac, 3 GI bleed.
#   - Cohort counts
#   - FeatureExtraction aggregate covariates (Table 1 + SMD), age/sex counts
#   - CohortIncidence: GI bleed IR by age group, sex, year (TAR = 365 days from start)
#   - Time from drug start to first GI bleed
library(framework)
scaffold()

out_dir <- "data/characterization"
cohort_names <- c("1" = "Celecoxib", "2" = "Diclofenac", "3" = "GI bleed")

connection_details <- Eunomia::getEunomiaConnectionDetails()
Eunomia::createCohorts(connection_details)
con <- DatabaseConnector::connect(connection_details)

# ---- 1. Cohort counts -------------------------------------------------------
cohort_counts <- DatabaseConnector::querySql(
  con,
  "SELECT cohort_definition_id, COUNT(DISTINCT subject_id) AS persons
     FROM main.cohort WHERE cohort_definition_id IN (1, 2, 3)
    GROUP BY cohort_definition_id",
  snakeCaseToCamelCase = TRUE
) |>
  mutate(cohort = cohort_names[as.character(cohortDefinitionId)])
data_save(cohort_counts, file.path(out_dir, "cohort_counts.csv"), force = TRUE)

# ---- 2. Baseline covariates (FeatureExtraction, aggregated) ----------------
covariate_settings <- FeatureExtraction::createCovariateSettings(
  useDemographicsGender = TRUE,
  useDemographicsAge = TRUE,
  useDemographicsAgeGroup = TRUE,
  useConditionGroupEraLongTerm = TRUE,
  useDrugGroupEraLongTerm = TRUE,
  longTermStartDays = -365,
  endDays = -1
)

get_covariates <- function(cohort_id) {
  FeatureExtraction::getDbCovariateData(
    connectionDetails = connection_details,
    cdmDatabaseSchema = "main",
    cohortDatabaseSchema = "main",
    cohortTable = "cohort",
    cohortIds = cohort_id,
    covariateSettings = covariate_settings,
    aggregated = TRUE
  )
}
cov_target <- get_covariates(1)
cov_comparator <- get_covariates(2)

smd <- FeatureExtraction::computeStandardizedDifference(cov_target, cov_comparator) |>
  as_tibble()
data_save(smd, file.path(out_dir, "smd_all_covariates.csv"), force = TRUE)

# Age group (5-year) x sex counts per cohort (from the binary age-group / gender covariates
# we only get marginals, so query the joint distribution directly).
age_sex <- DatabaseConnector::renderTranslateQuerySql(
  con,
  "SELECT c.cohort_definition_id,
          FLOOR((YEAR(c.cohort_start_date) - p.year_of_birth) / 5) * 5 AS age_group,
          p.gender_concept_id,
          COUNT(*) AS persons
     FROM main.cohort c
     JOIN main.person p ON p.person_id = c.subject_id
    WHERE c.cohort_definition_id IN (1, 2)
    GROUP BY c.cohort_definition_id,
             FLOOR((YEAR(c.cohort_start_date) - p.year_of_birth) / 5) * 5,
             p.gender_concept_id",
  snakeCaseToCamelCase = TRUE
) |>
  mutate(
    cohort = cohort_names[as.character(cohortDefinitionId)],
    sex = if_else(genderConceptId == 8507, "Male", "Female")
  )
data_save(age_sex, file.path(out_dir, "age_sex_counts.csv"), force = TRUE)

# ---- 3. Incidence (CohortIncidence) -----------------------------------------
ir_design <- CohortIncidence::createIncidenceDesign(
  targetDefs = list(
    CohortIncidence::createCohortRef(id = 1, name = "Celecoxib"),
    CohortIncidence::createCohortRef(id = 2, name = "Diclofenac")
  ),
  outcomeDefs = list(
    CohortIncidence::createOutcomeDef(id = 1, name = "GI bleed", cohortId = 3, cleanWindow = 9999)
  ),
  tars = list(
    CohortIncidence::createTimeAtRiskDef(id = 1, startWith = "start", endWith = "start", endOffset = 365)
  ),
  analysisList = list(
    CohortIncidence::createIncidenceAnalysis(targets = c(1, 2), outcomes = 1, tars = 1)
  ),
  strataSettings = CohortIncidence::createStrataSettings(
    byAge = TRUE, ageBreaks = c(35, 40, 45), byGender = TRUE, byYear = TRUE
  )
)

ir_results <- CohortIncidence::executeAnalysis(
  connectionDetails = connection_details,
  incidenceDesign = ir_design,
  buildOptions = CohortIncidence::buildOptions(
    cohortTable = "main.cohort",
    cdmDatabaseSchema = "main",
    sourceName = "Eunomia GiBleed",
    refId = 1
  )
)

age_groups <- ir_results$age_group_def |> select(age_group_id, age_group_name)
incidence <- ir_results$incidence_summary |>
  rename_with(tolower) |>
  left_join(age_groups, by = "age_group_id") |>
  mutate(
    cohort = cohort_names[as.character(target_cohort_definition_id)],
    sex = case_when(gender_id == 8507 ~ "Male", gender_id == 8532 ~ "Female"),
    person_years = person_days / 365.25,
    ir_per_1000py = 1000 * outcomes / person_years
  )
data_save(incidence, file.path(out_dir, "incidence_summary.csv"), force = TRUE)

# ---- 4. Time to event: drug start -> first GI bleed after start -------------
tte <- DatabaseConnector::renderTranslateQuerySql(
  con,
  "SELECT t.cohort_definition_id, t.subject_id,
          MIN(DATEDIFF(DAY, t.cohort_start_date, o.cohort_start_date)) AS days_to_event
     FROM main.cohort t
     JOIN main.cohort o
       ON o.subject_id = t.subject_id
      AND o.cohort_definition_id = 3
      AND o.cohort_start_date >= t.cohort_start_date
    WHERE t.cohort_definition_id IN (1, 2)
    GROUP BY t.cohort_definition_id, t.subject_id",
  snakeCaseToCamelCase = TRUE
) |>
  mutate(cohort = cohort_names[as.character(cohortDefinitionId)])
data_save(tte, file.path(out_dir, "time_to_event.csv"), force = TRUE)

DatabaseConnector::disconnect(con)
