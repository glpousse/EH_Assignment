# EH Assignment 

This repo presents some breif code used in an assignmnet for an Economic History class taught by Professors [Moritz Schularick](https://www.moritzschularick.com/) and [Paul Bouscasse](https://www.paul-bouscasse.com/). 

The assignment focuses on crisis prediction and costs, and uses two open source data sources: 
- The Jordà, Schularick, Taylor (JST) macro panel dataset acccessible [here](https://www.macrohistory.net/database/#DownloadData).
- The Baron, Verner, Xiong (BVX) macro panel dataset acessible [here](https://www.financialhistorylab.org/data).

Overall, the script analyzes the relationship between credit growth and financial crises using logistic regression with fixed effects, testing for joint significance of multiple lags of real credit growth.

It compares both crisis datasets (JST and BVX) by merging them with a dummy dataset for recessions, and repeating the same credit-growth-based regressions to check robustness.

It evaluates predictive performance by training models on pre-1984 data, generating ROC curves to compare in-sample and out-of-sample prediction accuracy for credit, money supply, and public debt.

Finally, it examines the impact of recessions on GDP growth, estimating impulse response functions (IRFs) and their CI's over a five-year horizon for normal and financial recessions.
