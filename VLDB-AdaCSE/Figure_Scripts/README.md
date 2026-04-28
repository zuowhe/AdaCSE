# Figure Scripts

This folder contains the scripts and plotting input tables used to generate the
main paper figures from experiment outputs or summarized plotting data.

## Requirements

Install the Python packages listed in `requirements.txt`.

## Files

- `plot_benchmark_ablation_radar.py`
  - generates the six radar charts for the ablation study
- `plot_benchmark_convergence_curves.py`
  - generates convergence plots from saved per-trial CSV outputs
- `plot_hybrid_sla_adaptive_threshold_f1.py`
  - generates the adaptive-threshold comparison plots for hybrid-SLA
- `plot_miga_adaptive_threshold_f1.py`
  - generates the adaptive-threshold comparison plots for MIGA

Plotting input tables are stored in `data/`.

## Example Commands

From the `VLDB-AdaCSE` directory:

```bash
python Figure_Scripts/plot_benchmark_ablation_radar.py
python Figure_Scripts/plot_benchmark_convergence_curves.py
python Figure_Scripts/plot_hybrid_sla_adaptive_threshold_f1.py
python Figure_Scripts/plot_miga_adaptive_threshold_f1.py
```

By default, generated figures are written to:

- `Figure_Scripts/output/`

The convergence plotting script reads trial CSVs from:

- `[result]/20260302/Convergence_Behavior/`

unless another input directory is provided explicitly.
