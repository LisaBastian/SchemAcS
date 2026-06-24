#%% 
import os
import warnings
import itertools

import numpy as np
import pandas as pd
from scipy.stats import pearsonr
from omegaconf import OmegaConf
from utils import run_stats_mixed, reverse_score
warnings.filterwarnings("ignore")
pd.set_option('display.max_rows', None)

CONFIG_PATH = "/Volumes/T7/01_SchemAcS/05_Analysis/Questionnaires/"
cfg = OmegaConf.load(f"{CONFIG_PATH}/config.yaml")
DATA_PATH = cfg.DATA_PATH

#%% stats SSS


# load and optionally filter
SSS_data = pd.read_csv(f'{DATA_PATH}/final/SSS_final.csv')
SSS_data = SSS_data[SSS_data['repID'] < 6] # keep only first 5 repetitions for stats, since not all participants have 6th repetition

#count unique participants per condition 
print("Unique participants per condition:")
print(SSS_data.groupby('condition')['partID'].nunique())

# convert to categorical
for c in ['participant_num','condition','repID']:
    SSS_data[c] = SSS_data[c].astype('category')

aov, sig, post = run_stats_mixed(
    df=SSS_data,
    dv="Schlafrigkeit",
    within="repID",
    between="condition",
    subject="partID",
    alpha=0.05,
    padjust="holm"
)

if sig:
    es_col = 'ng2' if 'ng2' in aov.columns else 'np2'
    print(f"Effect Sizes ({es_col}):")
    print(aov[['Source', es_col]].to_string(index=False))


# %% stats MDBF mood 
MDBF_data=pd.read_csv(f'{DATA_PATH}/final/MDBF_final.csv')
MDBF_data = MDBF_data[MDBF_data['repID'] < 6]

# convert to categorical
for c in ['participant_num','condition','repID']:
    MDBF_data[c] = MDBF_data[c].astype('category')


#reverse negative scores
negatives = ['unruhig', 'schlecht', 'schlapp', 'mude', 'ruhelos', 'unruhig']

for neg in negatives:
    MDBF_data[neg] = reverse_score(MDBF_data[neg])

#run lme analysis 

MDBF_data['mood']=MDBF_data[['zufrieden', 'gut','unwohl','schlecht']].mean(axis=1)

aov, sig, post = run_stats_mixed(
    df=MDBF_data,
    dv="mood",
    within="repID",
    between="condition",
    subject="partID",
    alpha=0.05,
    padjust="holm"
)

if sig:
    es_col = 'ng2' if 'ng2' in aov.columns else 'np2'
    print(f"Effect Sizes ({es_col}):")
    print(aov[['Source', es_col]].to_string(index=False))

# %% stats MISC 
MISC_data = pd.read_csv(f'{DATA_PATH}/final/MISC_final.csv')
MISC_data = MISC_data[MISC_data['repID'] < 6]

MISC_data['partID'] = MISC_data['partID'].astype('category')
MISC_data['condition'] = MISC_data['condition'].astype('category')
MISC_data['repID'] = MISC_data['repID'].astype('category')

aov, sig, post = run_stats_mixed(
    df=MISC_data,
    dv="Symptome",
    within="repID",
    between="condition",
    subject="partID",
    alpha=0.05,
    padjust="holm"
)

if sig:
    es_col = 'ng2' if 'ng2' in aov.columns else 'np2'
    print(f"Effect Sizes ({es_col}):")
    print(aov[['Source', es_col]].to_string(index=False))

# %%
