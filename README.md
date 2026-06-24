# SchemAcS
Analysis code for **Bastian, Hamann, Näher, Rauss & Born — _Sleep enhances spatial schema memory formation in humans_**.

This repository contains the scripts that reproduce the behavioral, eye-tracking, and electrophysiological analyses reported in the manuscript and supplementary information. The underlying data are deposited separately on the Open Science Framework (see https://osf.io/8kg2j/overview).

---

## Overview

Sixty healthy young adults navigated a virtual-reality hexagonal arena and learned, across five sessions, a spatial distribution of object-category ratios (children's toys vs. household items hidden in boxes at different locations). After schema build-up, participants either slept in the laboratory with polysomnography (**Sleep**, *n* = 20), were sleep-deprived for one night (**Wake**, *n* = 20), or were tested after a 30-min wake delay (**Short-delay**, *n* = 20). The Sleep and Wake groups were tested three days later following two recovery nights. At retrieval, participants navigated to 54 boxes (34 old + 20 new) and reported, for each, whether it was old or new and its category ratio — inferring the ratio at new locations as a measure of spatial interpolation (the Schema Memory Index, SMI).

The code covers four analysis strands:

- **Schema build-up** — category-recall and object-recognition accuracy across the five learning sessions.
- **Schema retrieval** — category-ratio accuracy, episodic-vs-schema memory, and the Schema Memory Index.
- **Eye tracking** — cue fixation duration and gaze transition entropy, and their relation to the SMI.
- **Sleep electrophysiology** — slow-oscillation–spindle coupling and its relation to the SMI.

---

## Software requirements

**R** (analyses run with RStudio 2023.12.1)
- `emmeans`, plus base R; additional packages as listed in `environment/` (e.g. `afex`/`car` for mixed ANOVAs, `tidyverse` for data handling, `igraph` for the SMI graphs, `boot` for resampling).
- Dependencies are pinned in `environment/renv.lock`; restore with `renv::restore()`.

**MATLAB** R2024b
- Toolboxes used in the EEG pipeline (e.g. Signal Processing Toolbox, Statistics and Machine Learning Toolbox).
- Adaptive superlet transform (Moca et al., 2021) for time–frequency analysis.
- Any sleep-staging / event-detection toolboxes you relied on (list explicitly here).

---

## Citation

If you use this code, please cite the article:

> Bastian, L., Hamann, H., Näher, T., Rauss, K., & Born, J. Sleep enhances spatial schema memory formation in humans. [bioRxiv, 2026, DOI:10.64898/2026.06.16.732347].



---

## Contact

Lisa Bastian / Jan Born — Institute of Medical Psychology and Behavioral Neurobiology, University of Tübingen.
Questions and issues: please open a GitHub issue or contact jan.born@uni-tuebingen.de.

