# Fit ONE model (OSA_MODEL, see models.R) with MCMC, in a single job: the models
# here are small, so there are no shards to combine. Submitted by
# `./hpc fit <model>`; writes <OSA_MODELS_DIR>/<model>.rds.
#
# Run-shaping variables (forwarded by ./hpc when set):
#   OSA_WARMUP (1000), OSA_SAMPLES (1000), OSA_CHAINS (4), OSA_SEED (123),
#   OSA_ADAPT_DELTA (0.95), OSA_FILE_REFIT ("on_change")

library(brms)
source("models.R")

spec <- osa_model(Sys.getenv("OSA_MODEL", unset = ""))

cores <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", unset = "4"))
chains <- as.integer(Sys.getenv("OSA_CHAINS", unset = "4"))
threads <- max(1L, cores %/% chains)
warmup <- as.integer(Sys.getenv("OSA_WARMUP", unset = "1000"))
samples <- as.integer(Sys.getenv("OSA_SAMPLES", unset = "1000"))
seed <- as.integer(Sys.getenv("OSA_SEED", unset = "123"))
adapt_delta <- as.numeric(Sys.getenv("OSA_ADAPT_DELTA", unset = "0.95"))
file_refit <- Sys.getenv("OSA_FILE_REFIT", unset = "on_change")
models_dir <- Sys.getenv("OSA_MODELS_DIR", unset = "models")
dir.create(models_dir, recursive = TRUE, showWarnings = FALSE)

# Pushed from analysis/models/ by ./hpc push
data <- read.csv(file.path("data", spec$data))
cat(sprintf(
  "config: model=%s rows=%d chains=%d threads/chain=%d warmup=%d samples=%d seed=%d adapt_delta=%g refit=%s brms=%s\n",
  spec$name, nrow(data), chains, threads, warmup, samples, seed, adapt_delta, file_refit, packageVersion("brms")
))

# One summary line so runs can be compared from the .out logs alone (grep REPORT)
report_fit <- function(m, name, wall_min) {
  np <- brms::nuts_params(m)
  stat <- vapply(split(np$Value, np$Parameter), mean, numeric(1))
  cat(sprintf(
    "REPORT %s | wall %.1f min | n_leapfrog %.0f | treedepth %.2f | stepsize %.3g | divergent %d | max Rhat %.3f | min neff_ratio %.3f | n params %d\n",
    name, wall_min, stat[["n_leapfrog__"]], stat[["treedepth__"]], stat[["stepsize__"]],
    as.integer(sum(np$Value[np$Parameter == "divergent__"])), max(brms::rhat(m), na.rm = TRUE),
    min(brms::neff_ratio(m), na.rm = TRUE), length(brms::rhat(m))
  ))
}

t0 <- Sys.time()
m <- brm(spec$formula,
  data = data,
  family = spec$family,
  prior = spec$prior,
  chains = chains,
  cores = chains,
  threads = threading(threads),
  warmup = warmup,
  iter = warmup + samples,
  seed = seed,
  control = list(adapt_delta = adapt_delta),
  backend = "cmdstanr",
  # Same as FakeArt's fits, so the account's precompiled header variant
  # (model_header_threads_nochecks_12_3) is reused (hub: toolchain.md)
  stan_model_args = list(
    stanc_options = list("O1"),
    cpp_options = list(STAN_CPP_OPTIMS = TRUE, STAN_NO_RANGE_CHECKS = TRUE)
  ),
  file = file.path(models_dir, spec$name),
  file_refit = file_refit
)
wall_min <- as.numeric(difftime(Sys.time(), t0, units = "mins"))

cat(spec$name, ": wrote", file.path(models_dir, paste0(spec$name, ".rds")), "with", ndraws(m), "draws. SUCCESSFUL.\n")
tryCatch(report_fit(m, spec$name, wall_min),
  error = function(e) cat("REPORT failed:", conditionMessage(e), "\n")
)
