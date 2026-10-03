# Optional analyses (2026-10-03), on the notebook's cached data. Run from analysis/
suppressMessages({library(nnet); library(mclust)})
options(width = 200)
load_cache <- function(chunk) {
  e <- new.env(); f <- list.files("analysis_cache/html", pattern = paste0("^", chunk, "_.*[.]rdb$"), full.names = TRUE)
  lazyLoad(sub("[.]rdb$", "", f[1]), envir = e); e
}
d <- load_cache("country_comparison")$data_region   # N = 671 (one unreadable country)
nm <- c(A = "Idealists", B = "Aspirants", C = "Stewards", D = "Purists", E = "Traditionalists")
d$Name <- factor(nm[substr(d$Profile, 9, 9)], levels = nm)
d$Region <- factor(d$Region, levels = c("France", "Other European"))
d$Work_Discipline <- factor(d$Work_Discipline, levels = c("Social Sciences & Humanities", "Life Sciences", "Physical Sciences & Engineering"))
stopifnot(!anyNA(d$Name))
pct <- function(x) round(100 * x)
set.seed(2026)

if (Sys.getenv("PART2") == "") {
cat("\n################ 1. Profiles, discipline and country ################\n")
cat("\nComposition (% of each profile):\n")
print(cbind(n = table(d$Name),
            France = pct(tapply(d$Region == "France", d$Name, mean)),
            SSH = pct(tapply(d$Work_Discipline == "Social Sciences & Humanities", d$Name, mean)),
            Life = pct(tapply(d$Work_Discipline == "Life Sciences", d$Name, mean)),
            Physical = pct(tapply(d$Work_Discipline == "Physical Sciences & Engineering", d$Name, mean))))
cat("Sample: France", pct(mean(d$Region == "France")), "% | SSH", pct(mean(d$Work_Discipline == "Social Sciences & Humanities")), "%\n")

dm <- subset(d, Dem_Gender %in% c("Female", "Male") & !is.na(Dem_Age) & Dem_Age <= 65)
dm$Dem_Gender <- factor(dm$Dem_Gender)
cat("\nMultinomial models, N =", nrow(dm), "\n")
f0 <- Name ~ Dem_Gender * poly(Dem_Age, 2)
f1 <- Name ~ Dem_Gender * poly(Dem_Age, 2) + Work_Discipline + Region
f1_nogender <- Name ~ poly(Dem_Age, 2) + Work_Discipline + Region
f1_noage <- Name ~ Dem_Gender + Work_Discipline + Region
fit <- function(f, data) multinom(f, data = data, trace = FALSE, maxit = 500)
m0 <- fit(f0, dm); m1 <- fit(f1, dm)
lrt <- function(a, b) { s <- 2 * (logLik(b) - logLik(a)); df <- attr(logLik(b), "df") - attr(logLik(a), "df"); sprintf("chi2(%d) = %.1f, p = %.3g", df, s, pchisq(s, df, lower.tail = FALSE)) }
cat("Adding discipline + region to gender x age:", lrt(m0, m1), "\n")
cat("Gender terms, given age + discipline + region:", lrt(fit(f1_nogender, dm), m1), "\n")
cat("Age terms, given gender + discipline + region:", lrt(fit(f1_noage, dm), m1), "\n")
cat("AIC: gender x age", round(AIC(m0)), "| + discipline + region", round(AIC(m1)), "\n")

# Marginal (standardised) probabilities: everyone set to a gender and age, averaged
marg <- function(m, data, gender, age) { nd <- data; nd$Dem_Gender <- factor(gender, levels = levels(data$Dem_Gender)); nd$Dem_Age <- age; colMeans(predict(m, nd, type = "probs")) }
contrasts_of <- function(m, data) {
  rbind(`Men - women, at 25` = marg(m, data, "Male", 25) - marg(m, data, "Female", 25),
        `Men - women, at 55` = marg(m, data, "Male", 55) - marg(m, data, "Female", 55),
        `55 - 25, women` = marg(m, data, "Female", 55) - marg(m, data, "Female", 25),
        `55 - 25, men` = marg(m, data, "Male", 55) - marg(m, data, "Male", 25))
}
setof <- function(m, data, var, a, b) { na <- data; na[[var]] <- factor(a, levels = levels(data[[var]])); nb <- data; nb[[var]] <- factor(b, levels = levels(data[[var]]))
  colMeans(predict(m, na, type = "probs")) - colMeans(predict(m, nb, type = "probs")) }
comp_contrasts <- function(m, data) rbind(
  `Other Europe - France` = setof(m, data, "Region", "Other European", "France"),
  `SSH - Physical` = setof(m, data, "Work_Discipline", "Social Sciences & Humanities", "Physical Sciences & Engineering"),
  `SSH - Life` = setof(m, data, "Work_Discipline", "Social Sciences & Humanities", "Life Sciences"))
B <- 300
boot <- function(stat) {
  est <- stat(dm)
  draws <- replicate(B, { db <- dm[sample(nrow(dm), replace = TRUE), ]; stat(db) }, simplify = "array")
  lo <- apply(draws, c(1, 2), quantile, 0.025); hi <- apply(draws, c(1, 2), quantile, 0.975)
  out <- matrix(sprintf("%+.0f [%+.0f, %+.0f]", 100 * est, 100 * lo, 100 * hi), nrow(est), dimnames = dimnames(est))
  noquote(out)
}
cat("\nProfile probability differences (percentage points, 95% bootstrap CI), gender x age only:\n")
print(boot(function(x) contrasts_of(fit(f0, x), x)))
cat("\nSame, adjusted for discipline and region:\n")
print(boot(function(x) contrasts_of(fit(f1, x), x)))
cat("\nDiscipline and region effects on profile probabilities (adjusted for each other and gender x age):\n")
print(boot(function(x) comp_contrasts(fit(f1, x), x)))

}
cat("\n################ 2. Gaussian mixtures: how many profiles? ################\n")
cs <- load_cache("cluster_stability")
z <- cs$z
km <- rep(NA_character_, nrow(z)); for (p in names(cs$profile_members)) km[cs$profile_members[[p]]] <- nm[substr(p, 9, 9)]
km <- factor(km, levels = nm)
bic <- mclustBIC(z, G = 1:9, verbose = FALSE)
cat("\nTop BIC models (all covariance structures, G = 1-9):\n"); print(summary(bic, k = 6))
icl <- mclustICL(z, G = 1:9, verbose = FALSE)
cat("\nTop ICL models:\n"); print(summary(icl, k = 6))
best <- Mclust(z, x = bic, verbose = FALSE)
cat("\nBest-BIC model:", best$modelName, "with G =", best$G, "\n")
cat("Component means (standardised facets) and sizes:\n")
print(round(cbind(t(best$parameters$mean), n = as.vector(table(best$classification))), 2))
cat("Cross-tab k-means profiles (rows) x best GMM (cols):\n"); print(table(km, best$classification))
cat("ARI with k-means profiles:", round(adjustedRandIndex(km, best$classification), 2), "\n")
cat("Mean posterior probability of the assigned component:", round(mean(apply(best$z, 1, max)), 2), "\n")
# Best G per covariance family, and the classic LPA parameterisation (diagonal, varying: VVI)
cat("\nBest G by model family (BIC):\n")
bm <- as.matrix(bic[, , drop = FALSE]); print(apply(bm, 2, function(x) if (all(is.na(x))) NA else which.max(x)))
for (G in 4:6) {
  g <- Mclust(z, G = G, modelNames = "VVI", verbose = FALSE)
  e5 <- Mclust(z, G = G, modelNames = best$modelName, verbose = FALSE)
  a_e <- if (is.null(e5)) NA else adjustedRandIndex(km, e5$classification)
  cat(sprintf("G = %d: ARI with k-means, VVI = %.2f, %s = %.2f\n", G, adjustedRandIndex(km, g$classification), best$modelName, a_e))
}
g5 <- Mclust(z, G = 5, modelNames = "VVI", verbose = FALSE)
cat("\nVVI with G = 5: component means and cross-tab with k-means\n")
print(round(cbind(t(g5$parameters$mean), n = as.vector(table(g5$classification))), 2)); print(table(km, g5$classification))
# Stability of the best GMM partition (bootstrap ARI, assign everyone by the resampled fit)
ari_boot <- replicate(50, { i <- sample(nrow(z), replace = TRUE)
  g <- tryCatch(Mclust(z[i, ], G = best$G, modelNames = best$modelName, verbose = FALSE), error = function(e) NULL)
  if (is.null(g)) NA else adjustedRandIndex(best$classification, predict(g, z)$classification) })
cat("\nBootstrap ARI of the best GMM (50 resamples): median", round(median(ari_boot, na.rm = TRUE), 2),
    "[", round(quantile(ari_boot, .025, na.rm = TRUE), 2), ",", round(quantile(ari_boot, .975, na.rm = TRUE), 2), "], failed fits:", sum(is.na(ari_boot)), "\n")

cat("\n################ 3. Preregistration by career stage within disciplines ################\n")
ds <- subset(d, !is.na(Work_Career_Stage))
ds$Stage <- factor(ds$Work_Career_Stage, levels = c("PhD / Student", "Non-permanent", "Permanent"))
ds$Prereg <- as.numeric(ds$OS_Study_Preregistration == 1)
cat("\nPreregistration used (%), n in brackets:\n")
tab <- with(ds, tapply(Prereg, list(Work_Discipline, Stage), function(x) sprintf("%2.0f%% (%d)", 100 * mean(x), length(x))))
print(noquote(tab))
cat("\nWithin SSH, by region:\n")
ssh <- subset(ds, Work_Discipline == "Social Sciences & Humanities")
print(noquote(with(ssh, tapply(Prereg, list(Region, Stage), function(x) sprintf("%2.0f%% (%d)", 100 * mean(x), length(x))))))
pp_diff <- function(data, a, b, f = Prereg ~ Stage) {
  m <- glm(f, binomial, data)
  pr <- function(lv) { nd <- data; nd$Stage <- factor(lv, levels = levels(data$Stage)); mean(predict(m, nd, type = "response")) }
  pr(a) - pr(b)
}
boot_pp <- function(data, a, b, f = Prereg ~ Stage) {
  est <- pp_diff(data, a, b, f)
  dr <- replicate(1000, { db <- data[sample(nrow(data), replace = TRUE), ]; tryCatch(pp_diff(db, a, b, f), error = function(e) NA) })
  sprintf("%+.0f [%+.0f, %+.0f] points", 100 * est, 100 * quantile(dr, .025, na.rm = TRUE), 100 * quantile(dr, .975, na.rm = TRUE))
}
for (disc in levels(ds$Work_Discipline)) {
  x <- subset(ds, Work_Discipline == disc)
  cat(sprintf("\n%s (n = %d): Permanent - PhD %s | Permanent - Non-permanent %s\n", disc, nrow(x),
              boot_pp(x, "Permanent", "PhD / Student"), boot_pp(x, "Permanent", "Non-permanent")))
}
cat(sprintf("\nWhole sample, unadjusted: Permanent - PhD %s | Permanent - Non-permanent %s\n",
            boot_pp(ds, "Permanent", "PhD / Student"), boot_pp(ds, "Permanent", "Non-permanent")))
cat(sprintf("SSH working in France (n = %d): Permanent - PhD %s\n", sum(ssh$Region == "France"), boot_pp(subset(ssh, Region == "France"), "Permanent", "PhD / Student")))
mi0 <- glm(Prereg ~ Stage + Work_Discipline, binomial, ds); mi1 <- glm(Prereg ~ Stage * Work_Discipline, binomial, ds)
a <- anova(mi0, mi1, test = "LRT"); cat(sprintf("\nStage x discipline interaction: chi2(%d) = %.1f, p = %.3f\n", a$Df[2], a$Deviance[2], a$`Pr(>Chi)`[2]))
cat("\nRigorous Science (facet score) by stage within SSH, means:\n")
print(round(tapply(ssh$Rigorous_Science, ssh$Stage, mean), 2))
r_ssh <- lm(Rigorous_Science ~ Stage, ssh); print(round(cbind(Estimate = coef(r_ssh), confint(r_ssh))[-1, ], 2))
