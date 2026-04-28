# Artifact Guide

This document summarizes the repository components that support the availability
and reproducibility expectations of VLDB-style artifact evaluation.

## Availability Checklist

### 1. Prototype System

The source code and experiment scripts are included in this repository under:

- algorithm implementations: `AdaCSE/`, `Algorithms/`, `Adapt_Algorithms/`,
  `Subprogram/`
- TE artifact package:
  - `TE_Industrial_Application_Package/Code/`

### 2. Input Data

- Standard benchmark datasets used in the paper are included under:
  - `[Datasets]/`
- TE industrial process benchmark files are included under:
  - `TE_Industrial_Application_Package/Data/raw/`
- The prepared TE experiment input is included under:
  - `TE_Industrial_Application_Package/Data/prepared/`

### 3. Experiment Definitions

The runnable experiment scripts and parameter settings for the TE artifact are
documented in:

- `TE_Industrial_Application_Package/README.md`
- `TE_Industrial_Application_Package/EXPERIMENTS.md`

### 4. Figure Generation Scripts

The scripts used to transform experimental outputs into paper figures are
included under:

- `Figure_Scripts/`

This folder contains:

- plotting scripts,
- plotting input tables,
- a README with expected inputs and outputs,
- a Python requirements file.

## Reproducibility Scope

The central claims supported by the uploaded TE artifact are:

- AdaCSE outperforms the compared evolutionary CSL baselines on the TE
  industrial process benchmark under the benchmark evaluator used in the paper.
- AdaCSE remains competitive under the stricter exact-direction protocol used
  for comparison with IGES-RCI.

The exact files supporting these claims are described in:

- `TE_Industrial_Application_Package/RESULTS.md`
