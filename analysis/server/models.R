# Model registry: one entry per model fitted on the cluster, and the only
# definition of that model. `data` is the CSV that analysis.qmd writes to
# analysis/models/ and `./hpc push` sends to the cluster's data/.
#
# Keep declaration lines as '  <name> = list(' at two-space indent: ./hpc reads
# the model names from them.

osa_models <- list(
  # Researcher profile (CFA factor scores -> hkmeans, in analysis.qmd) by gender
  # x age. Dem_Gender is also a main effect: the smooths of a factor `by` are
  # centred, so without it both genders get the same average profile odds.
  Profile = list(
    formula = Profile ~ Dem_Gender + s(Dem_Age, by = Dem_Gender),
    family = brms::categorical(),
    data = "data_Profile.csv"
  )
)

osa_model <- function(name) {
  if (!name %in% names(osa_models)) {
    stop("unknown model '", name, "'. Known: ", paste(names(osa_models), collapse = ", "), call. = FALSE)
  }
  c(list(name = name), osa_models[[name]])
}
