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
  meaningless; the Gaussian models of `analysis.qmd` keep Pathfinder (70-84%
  unique draws, checked in their tables).
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
| 2026-09-30 | Profile | 11417721 | general | 2.3 min (job 2:30) | 0 | 1.003 | N682 data, profiles labelled by pattern ("Profile A +Open ..."); min ESS 1,259. Current fit |
