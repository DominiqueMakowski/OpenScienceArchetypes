# Build the CmdStan precompiled header ONCE, with the exact cpp_options that
# fit_model.R uses. Run by `./hpc precompile` (hub: toolchain.md#precompiled-header).
#

suppressMessages(library(cmdstanr))
cat("cmdstan:", cmdstan_path(), "|", as.character(cmdstan_version()), "\n")
cat("node   :", Sys.info()[["nodename"]], "\n")

gch <- list.files(file.path(cmdstan_path(), "stan/src/stan/model"),
  pattern = "[.]gch$", full.names = TRUE
)
cat("PCH before:\n")
if (length(gch)) cat(paste0("  ", basename(gch), collapse = "\n"), "\n") else cat("  (none)\n")

stan <- write_stan_file("
data { int<lower=0> N; vector[N] y; }
parameters { real mu; }
model { y ~ normal(mu, 1); }
")

# Must match fit_model.R's stan_model_args exactly, or a different variant is
# keyed and the race comes back.
m <- cmdstan_model(stan,
  cpp_options = list(
    stan_threads = TRUE, # brms sets this whenever threads = threading(n)
    STAN_CPP_OPTIMS = TRUE,
    STAN_NO_RANGE_CHECKS = TRUE
  ),
  stanc_options = list("O1"),
  force_recompile = TRUE
)
cat("compiled OK:", basename(m$exe_file()), "\n")

gch <- list.files(file.path(cmdstan_path(), "stan/src/stan/model"),
  pattern = "[.]gch$", full.names = TRUE
)
cat("PCH after:\n")
for (g in gch) cat(sprintf("  %-45s %.0f MB\n", basename(g), file.size(g) / 1e6))
