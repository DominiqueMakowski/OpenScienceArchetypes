#!/bin/bash
#SBATCH --job-name=osa_fit
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=8G
#SBATCH --partition=general
#SBATCH --output=fit_%j.out
#SBATCH --error=fit_%j.err
#SBATCH --mail-type=END,FAIL

# One job = one model (OSA_MODEL) = 4 chains x 2 threads. No --time: the job
# gets general's 8-hour maximum (hub: jobs.md#wall-time). Job name, logs, mail
# and the OSA_* variables come from `./hpc fit`; submitted by hand, export
# OSA_MODEL yourself.

PROJECT_DIR="${OSA_USERS_DIR:-$SLURM_SUBMIT_DIR}"
export OSA_MODELS_DIR="${OSA_MODELS_DIR:-$PROJECT_DIR/models}"
cd "$PROJECT_DIR" || exit 1
mkdir -p "$OSA_MODELS_DIR"
echo "Running on $(hostname) at $(date '+%F %T'); model ${OSA_MODEL:-<unset>}"

# 'module' is undefined in a batch shell, and compute nodes cannot see the
# EasyBuild tree unless told (hub: toolchain.md#modules)
[ -n "${LMOD_CMD:-}" ] || [ ! -f /etc/profile.d/lmod.sh ] || . /etc/profile.d/lmod.sh
module use "${OSA_EB_MODULES:-/mnt/shared/easybuild/modules/all}"
module load "${OSA_R_MODULE:-CmdStanR/0.7.1-foss-2023a-R-4.3.2}"
# Project library first, so it shadows the module
[ -z "${OSA_R_LIBS:-}" ] || export R_LIBS="${OSA_R_LIBS}${R_LIBS:+:$R_LIBS}"

Rscript fit_model.R
status=$?   # Propagate R's exit status: never add a command after Rscript without it
echo "FINISHED at $(date '+%F %T') with status $status"
exit $status
