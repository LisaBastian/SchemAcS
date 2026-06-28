# %%
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
import os
from omegaconf import OmegaConf
from utils import *


#load data 
CONFIG_PATH = os.path.dirname(__file__)
cfg = OmegaConf.load(f'{CONFIG_PATH}/config.yaml')
save_dir = '/Volumes/T7/01_SchemAcS/06_Ergebnisse/Questionnaires/plots'

DATA_PATH = cfg.DATA_PATH

# %% plot SSS

SSS_data = pd.read_csv(f'{DATA_PATH}/final/SSS_final.csv')

x_ticks = ["TP1","TP2","TP3","TP4","TP5","TP6"]
ylim = (0, 5)
x_label = 'Measurement Timepoint'
save = f'{save_dir}/SSS.pdf'
markers = ['o', 'o', 'o']  
hue_val = "condition"
palette = {"S": "#00008B", "W": "#E41A1C", "K": "#696969"}
day_breaks = {
    'day1': [5, 6],
}

plot_scores(data=SSS_data, y_input="Schlafrigkeit", hue_val=hue_val, day_breaks=day_breaks,
    palette=palette, markers=markers, x_ticks=x_ticks, x_label=x_label, y_label='Sleepiness', save_dir=save, ylim=ylim)

# %% plot MDBF
MDBF_data=pd.read_csv(f'{DATA_PATH}/final/MDBF_final.csv')

#reverse negative scores
negatives = ['unruhig', 'schlecht', 'schlapp', 'mude', 'ruhelos', 'unruhig']

for neg in negatives:
    MDBF_data[neg] = reverse_score(MDBF_data[neg])

#define the subscales
scales = {
    'mood': ['zufrieden', 'gut','unwohl','schlecht'],
    'wake': ['ausgeruht', 'munter','schlapp', 'mude',],
    'calm': ['gelassen', 'entspannt', 'ruhelos', 'unruhig']
}

#plot
for scale,value in scales.items(): 

    MDBF_data[scale]=MDBF_data[value].mean(axis=1)

    #set plotting variables
    x_ticks = ["TP1","TP2","TP3","TP4","TP5","TP6"]
    ylim = (0, 5)
    x_label = 'Measurement Timepoint'
    save = f'{save_dir}/MDBF_{scale}.pdf'
    markers = ['o', 'o', 's', 's', 'o', 's']  
    hue_val = 'condition'
    palette = {
        'K': "#696969", 
        "W": "#E41A1C", 
        "S": "#00008B",
    }
    day_breaks = {
        'day1': [5, 6],
    }

    plot_scores(data = MDBF_data, y_input=scale, hue_val = hue_val, day_breaks=day_breaks,
        palette = palette, markers=markers, x_ticks=x_ticks, x_label=x_label, y_label=scale, save_dir=save, ylim=ylim)



# %% plot MISC
MISC_data = pd.read_csv(f'{DATA_PATH}/final/MISC_final.csv')

x_ticks = ["TP1","TP2","TP3","TP4","TP5","TP6"]
ylim = (0, 5)
x_label = 'Measurement Timepoint'
save = f'{save_dir}/MISC.pdf'
markers = ['o', 'o', 'o']  
hue_val = "condition"
palette = {"S": "#00008B", "W": "#E41A1C", "K": "#696969"}
day_breaks = {
    'day1': [5, 6],
}

plot_scores(data=MISC_data, y_input="Symptome", hue_val=hue_val, day_breaks=day_breaks,
    palette=palette, markers=markers, x_ticks=x_ticks, x_label=x_label, y_label='Motion Sickness', save_dir=save, ylim=ylim)

# %%
