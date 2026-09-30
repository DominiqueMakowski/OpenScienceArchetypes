# Cluster fits (Artemis)

> **Cluster-level instructions live in the lab HPC hub**:
> <https://github.com/RealityBending/Lab/tree/main/hpc> (start at `hpc/README.md`).
> Prefer a local clone of `RealityBending/Lab` if there is one — it also holds
> your gitignored `hpc/private/` notes. The hub wins over anything here that
> contradicts it; this file only holds what is specific to this project.

Models too slow for the notebook are fitted with MCMC on the cluster. The
notebook writes each model's data to `analysis/models/data_<Model>.csv`, and
reads the fit back from `analysis/models/<Model>.rds` (both gitignored). If
the fit is missing or was fitted on other data, the notebook shows the model
as pending.

From `analysis/server/`, VPN connected:

```bash
./hpc push             # scripts + analysis/models/data_*.csv
./hpc fit Profile      # one job: 4 chains x 2 threads on `general`
./hpc progress Profile # latest iteration per chain, REPORT line
./hpc pull             # analysis/models/*.rds (staged, size-checked)
```

Then re-render `analysis/analysis.qmd`. A new account first runs
`./hpc setup && ./hpc install` and sets `OSA_HPC_USER=<you>` in `hpc.local`.

| file | role |
| --- | --- |
| `models.R` | registry: formula, family and data file of each model |
| `fit_model.R`, `fit.slurm` | fit one model (`OSA_MODEL`) |
| `install_pkgs.R`, `precompile.R` | toolchain check, precompiled header |
| `AGENT.md` | decisions and measured runs |
