# AGENT.md — OpenScienceArchetypes cluster notes

> **Cluster-level instructions live in the lab HPC hub**:
> <https://github.com/RealityBending/Lab/tree/main/hpc> (start at `hpc/README.md`).
> Prefer a local clone of `RealityBending/Lab` if there is one — it also holds
> your gitignored `hpc/private/` notes. The hub wins over anything here that
> contradicts it; this file only holds what is specific to this project.

Commands: [README.md](README.md). Variable prefix `OSA_`; cluster dir
`OpenScienceArchetypes/` (users + scratch).

## Decisions

- **Only the profile model runs here** (2026-09-30). With Pathfinder it
  collapsed onto 9 unique draws out of 3,000, twice, so its CIs were
  meaningless. Since 2026-09-30 (evening) every other brms model of
  `analysis.qmd` also uses MCMC, locally (`fit_brm()`: 4 chains x 1,000
  draws, cmdstanr); they are small enough not to need the cluster. The
  profile model also fits locally in ~3 min with the same script (2026-10-03,
  VPN down): copy `models.R`, `fit_model.R` and `data/data_Profile.csv` to a
  folder, run `OSA_MODEL=Profile SLURM_CPUS_PER_TASK=8 Rscript fit_model.R`,
  copy `models/Profile.rds` to `analysis/models/`.
- **Formula**: `Profile ~ Dem_Gender + s(Dem_Age, by = Dem_Gender)`. The
  `Dem_Gender` main effect was added on 2026-09-30 (user's decision): the
  smooths of a factor `by` are centred, so without it both genders were forced
  to the same average profile odds. Default brms priors.
- **Data are pushed, not read from GitHub.** `Profile` comes from the CFA and
  clustering in the notebook, which writes the exact rows the model gets
  (`analysis/models/data_Profile.csv`: Female/Male, age <= 65, missing ages set
  to the mean). The notebook reads the fit only if its data match the current
  export.
- **One job, no shards or combine**: the model is small (663 rows), so 4 chains
  x 2 threads in a single task on `general`, `file_refit = "on_change"`.
  `stan_model_args` match FakeArt's, reusing the account's
  `model_header_threads_nochecks_12_3` precompiled header.

## Runs

| date | model | job | partition / node | wall | divergent | max Rhat | notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 2026-09-30 | Profile | 11417708 | general / rtx-01 | 2.6 min (job 2:49, MaxRSS 1.4 GB) | 0 | 1.005 | N681 data, hand-named clusters; warmup 1000 + 1000 draws x 4 chains x 2 threads, seed 123; min ESS 1,066; 3.2 MB fit |
| 2026-09-30 | Profile | 11417711 | general | 2.5 min (job 2:43, MaxRSS 0.7 GB) | 0 | 1.005 | N682 data, superseded: the clusters reshuffled, so the hand-given names were wrong |
| 2026-09-30 | Profile | 11417721 | general | 2.3 min (job 2:30) | 0 | 1.003 | N682 data, profiles labelled by pattern ("Profile A +Open ..."); min ESS 1,259. Superseded |
| 2026-09-30 | Profile | 11417882 | general | ~3 min | 1 | 1.005 | Open science practices rescored as engagement ("not familiar" = 0, below "no plan"): new CFA scores and clusters; min ESS 1,085. Superseded |
| 2026-09-30 | Profile | 11417944 | general / rtx-00 | 2.9 min (job 3:11, MaxRSS 0.8 GB) | 0 | 1.004 | CFA with cross-loadings (two green beliefs also on Ethical Science): new facet scores and clusters (A 195, B 146, C 130, D 101, E 92); min ESS 1,368. Superseded |
| 2026-10-02 | Profile | 11422397 | general / a40-02 | 3.0 min (job 3:18) | 4 | 1.005 | Inclusion criterion applied (10 respondents working outside Europe excluded, N = 672; 654 rows): new clusters (A 247, B 142, C 97, D 96, E 90), profiles re-keyed in `profile_names`; min neff_ratio 0.196 (ESS ~780). 4 divergent transitions of 4,000 at adapt_delta 0.95: not refitted at 0.99 (`OSA_ADAPT_DELTA`). Superseded |
| 2026-10-03 | Profile | local (no job) | Windows laptop, R 4.5.3, 4 chains x 2 threads | 3.2 min | 0 | 1.004 | Clustering switched from hkmeans to k-means (best of 200 starts): hkmeans had stopped on a local optimum at N = 672. Same profiles as at N = 682 (A 189, B 140, C 128, D 102, E 95 of 654 rows); min neff_ratio 0.285. **Fitted locally** with `fit_model.R` (`OSA_MODEL=Profile SLURM_CPUS_PER_TASK=8`, data in `./data/`): Artemis unreachable (VPN down). Current fit |
