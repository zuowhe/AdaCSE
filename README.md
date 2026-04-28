# AdaCSE: Adaptive Constraint-Search Evolutionary Optimization for Causal Structure Learning

This repository contains the official MATLAB implementation of the **AdaCSE** algorithm. AdaCSE is a novel evolutionary approach for Causal Structure Learning (CSL), specifically designed to efficiently and accurately learn Bayesian Network (BN) structures from observational data.

## 📌 Overview

AdaCSE addresses the challenges of large search spaces and local optima in traditional evolutionary CSL algorithms by introducing two key innovations:
1. **MI-Guided Dual-Stage Structural Perturbation**: A targeted genetic operator that utilizes Mutual Information (MI) to intelligently guide the search process, balancing exploration and exploitation.
2. **Adaptive Constraint Mechanism**: A dynamic strategy that adjusts the conditional independence (CI) testing threshold ($\alpha$) during the evolutionary process, seamlessly integrating constraint-based space reduction with score-based optimization.

## ⚙️ Prerequisites and Environment

To run this code, you will need:
* **MATLAB** (R2020a or newer recommended)
* **Bayes Net Toolbox (BNT)** for MATLAB: Ensure the BNT library is added to your MATLAB path.

## 🚀 Usage

1. Clone this repository to your local machine:
   ```bash
   git clone https://github.com/zuowhe/AdaCSE.git
   ```

## TE Industrial Application Package

The TE industrial application assets are organized under:

`VLDB-AdaCSE/TE_Industrial_Application_Package`

This package includes:

- `Code/`: TE experiment scripts
- `Data/raw/`: official TE raw files from CIPCaD-Bench
- `Data/prepared/`: prepared discrete TE data used by the MATLAB experiments
- `Results/TE_Real_Application_Batch/`: structure-learning outputs, learned DAGs, and TKDE-style recomputed metrics
- `Results/TE_Real_Downstream_Ranking/`: downstream-ranking exploration outputs

### TE structure-learning comparison

Run the TE comparison among the evolutionary CSL methods:

```matlab
cd('VLDB-AdaCSE');
addpath(genpath(pwd));
[all_results, summary_file] = run_real_te_comparison_experiment(10, 100, 200, 7, ...
    {'AdaCSE','PSX','EKGA-std','AESL-GA','hybrid-SLA','MIGA','MAGA'});
```

### TE exact-direction metric recomputation

Recompute the TE metrics under the IGES-RCI exact-direction evaluation protocol:

```matlab
cd('VLDB-AdaCSE');
addpath(genpath(pwd));
recompute_te_metrics_tkde(fullfile(pwd, 'TE_Industrial_Application_Package', 'Results', 'TE_Real_Application_Batch'));
```

### TE downstream-ranking analysis

Run downstream-ranking analysis on the saved TE learned DAGs:

```matlab
cd('VLDB-AdaCSE');
addpath(genpath(pwd));
[all_rows, summary_file] = run_real_te_application_batch_analysis( ...
    fullfile(pwd, 'TE_Industrial_Application_Package', 'Results', 'TE_Real_Application_Batch'), ...
    {'X1','X22'}, 3);
```

### Notes

- The TE dataset is used here as an industrial process benchmark from CIPCaD-Bench.
- The downstream-ranking results are kept in the package for completeness, even though the paper mainly emphasizes the structure-learning results.
