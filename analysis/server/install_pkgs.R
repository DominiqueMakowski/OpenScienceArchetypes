# Check / build the project R library on Artemis (`./hpc install [pkg...]`;
# naming a package, or "all", force-reinstalls it). The CmdStanR module ships
# brms and mgcv; the library, shared by the account's projects, adds a
# cmdstanr >= 0.8 (hub: toolchain.md). CmdStan is built if the account has none.

lib <- Sys.getenv("OSA_R_LIBS", unset = file.path(
  "/mnt/lustre/users/psych", Sys.getenv("USER"),
  "cluster_R_libs/x86_64-pc-linux-gnu-library",
  paste(R.version$major, strsplit(R.version$minor, ".", fixed = TRUE)[[1]][1], sep = ".")
))
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
cat("target library:", lib, "| node:", Sys.info()[["nodename"]], "\n")

force <- strsplit(Sys.getenv("OSA_FORCE", unset = ""), "[, ]+")[[1]]
forced <- function(p) "all" %in% force || p %in% force
pkg_version <- function(p) {
  tryCatch(as.character(utils::packageVersion(p, lib.loc = .libPaths())), error = function(e) NA_character_)
}

if (is.na(pkg_version("cmdstanr")) || forced("cmdstanr") || package_version(pkg_version("cmdstanr")) < "0.8.0") {
  install.packages("cmdstanr", lib = lib, repos = c("https://stan-dev.r-universe.dev", "https://cloud.r-project.org"))
}
for (p in c("brms", "mgcv")) {
  if (is.na(pkg_version(p)) || forced(p)) install.packages(p, lib = lib, repos = "https://cloud.r-project.org")
}

have_cmdstan <- tryCatch({ cmdstanr::cmdstan_version(); TRUE }, error = function(e) FALSE)
if (!have_cmdstan) {
  cat("no CmdStan found -- building one (~15-25 min, once per account)\n")
  cmdstanr::install_cmdstan(cores = as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", unset = "4")), overwrite = FALSE)
}

cat("=== FINAL CHECK ===\n")
for (p in c("brms", "cmdstanr", "mgcv")) {
  v <- pkg_version(p)
  cat(sprintf("%-10s %s\n", p, if (is.na(v)) "MISSING" else paste("OK", v)))
}
cat("cmdstan:", tryCatch(as.character(cmdstanr::cmdstan_version()), error = function(e) "MISSING"), "\n")
