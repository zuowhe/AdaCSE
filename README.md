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
   git clone [https://github.com/zuowhe/AdaCSE.git](https://github.com/zuowhe/AdaCSE.git)
