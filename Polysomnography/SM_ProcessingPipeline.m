%%
clear all;
close all;
clc;
folder_path = '/Volumes/T7/01_SchemAcS/';

%analysis scripts
addpath('/Applications/CircStat2012a')
addpath(strcat(folder_path,'05_Analysis/SleepAnalysis/Scripts/fun_lib/'))
addpath(strcat(folder_path,'05_Analysis/SleepAnalysis/Scripts/'))
addpath(strcat(folder_path,'05_Analysis/SleepAnalysis/Scripts/ArtefactRejection_Hongi/'))
addpath(strcat(folder_path,'05_Analysis/SleepAnalysis/Scripts/cbrewer/'))

channel_list = {'F3','Fz','F4','C3','Cz','C4','P3','Pz','P4'};
condition = 'sleep'; %either wake or sleep

%% Preprocessing 

addpath('/Applications/fieldtrip-20240515')
ft_defaults

dirData  = strcat(folder_path,'04_Data/EEG_Recordings/raw/',condition,'/');
dirExcel = strcat(folder_path,'04_Data/EEG_Recordings/SleepEEG_Info_',condition,'.xlsx');
dirSave  = strcat(folder_path,'04_Data/EEG_Recordings/preproc/',condition,'/');

SM_FilterRereference(dirData,dirExcel,dirSave)


%% BEFORE CONTINUE: remove the fieldtrip path from MATLAB 

%% Read Scoring 
addpath('/Applications/sleeptrip-master_2024')
st_defaults

dirScoring = strcat(folder_path,'05_Analysis/SleepAnalysis/Scorings/final/',condition,'/');
dirSave     = strcat(folder_path,'05_Analysis/SleepAnalysis/Scorings/mat_files/',condition,'/');
dirFig      = strcat(folder_path,'05_Analysis/SleepAnalysis/Scorings/figures/',condition,'/');

SM_ReadScoring(dirScoring,dirSave,dirFig)

%% Plot Power densities
dirData = strcat(folder_path,'04_Data/EEG_Recordings/preproc/',condition,'/');
dirSave = strcat(folder_path,'06_Ergebnisse/EEG/freqspecs/',condition,'/');
dirScoring = strcat(folder_path,'05_Analysis/SleepAnalysis/Scorings/mat_files/',condition,'/');

SM_PowerDensity(dirScoring,dirData,dirSave,channel_list

%% SO Detection
dirData   = strcat(folder_path,'04_Data/EEG_Recordings/preproc/',condition,'/');
dirSaveSO = strcat(folder_path,'06_Ergebnisse/EEG/SlowOscillations/',condition,'/');
dirScoring = strcat(folder_path,'05_Analysis/SleepAnalysis/Scorings/mat_files/',condition,'/');

fu_SO = 4;
fl_SO = 0.3;
SM_SODetection(dirScoring,dirData,dirSaveSO,fu_SO,fl_SO,channel_list)

%% Detect Spindle Freqpeaks
dirData = strcat(folder_path,'06_Ergebnisse/EEG/freqspecs/');
dirSave = strcat(folder_path,'06_Ergebnisse/EEG/Spindles/');
wrkDirs = condition;
nPeaks = 2;

SM_DetectFreqPeaks(dirData,dirSave,wrkDirs,nPeaks)

%% Spindle Detection
dirData   = strcat(folder_path,'04_Data/EEG_Recordings/preproc/',condition,'/');
dirSaveSP = strcat(folder_path,'06_Ergebnisse/EEG/Spindles/',condition,'/');
dirFreqs  = strcat(folder_path,'/06_Ergebnisse/EEG/freqpeaks/'); 
dirScoring = strcat(folder_path,'05_Analysis/SleepAnalysis/Scorings/mat_files/',condition,'/');

WinLen = 1.2;
sp_type = 'Fast'; %'Fast' or 'Slow'
SM_SPDetection(dirScoring,dirData,dirFreqs,dirSaveSP,WinLen,channel_list,sp_type,condition)


%% BEFORE CONTINUE: remove the sleeptrip path from MATLAB 

%% PETHS
addpath('/Applications/fieldtrip-20240515')
ft_defaults

%REMOVE
sp_type = 'Fast';
dirCouple = strcat(folder_path,'06_Ergebnisse/EEG/Coupling/',condition,'/',sp_type,'/');
dirSOs    = strcat(folder_path,'06_Ergebnisse/EEG/SlowOscillations/',condition,'/');
dirSave   = strcat(folder_path,'06_Ergebnisse/EEG/PETHs/',condition,'/',sp_type,'/');
dirSaveERP  = strcat(folder_path,'06_Ergebnisse/EEG/PETHs/',condition,'/');
dirData  = strcat(folder_path,'04_Data/EEG_Recordings/preproc/',condition,'/');
TOI = 1.2;
channel_list = {'Fz','Cz','Pz'};


SM_SPSO_PETHs(dirCouple,dirSOs,dirSave,dirData,dirSaveERP,TOI,sp_type,channel_list)



%% BEFORE CONTINUE: remove the fieldtrip path from MATLAB 


%% Time-Freq Analysis 

addpath('/Applications/sleeptrip-master_2024')
st_defaults

dirData   = strcat(folder_path,'04_Data/EEG_Recordings/preproc/',condition,'/');
dirScoring = strcat(folder_path,'05_Analysis/SleepAnalysis/Scorings/mat_files/',condition,'/');
dirSO      = strcat(folder_path,'06_Ergebnisse/EEG/SlowOscillations/',condition,'/');
dirSave    = strcat(folder_path,'06_Ergebnisse/EEG/TimeFreq/',condition,'/');

channs = {'Fz','Cz','Pz'}; %do the analysis for Fz, Cz, Pz & Oz
triallength = 6;
low_freq = 6;
high_freq = 20; 
freq_step = 0.125;
faslt_baseline = [-3 -1.5];

SM_TimeFreqPipeline(dirData,dirScoring,dirSO,dirSave, ...
    channs,triallength,low_freq,high_freq,freq_step,faslt_baseline)

%% Time-Freq Permutation Tests on T-maps

dirData    = strcat(folder_path,'06_Ergebnisse/EEG/TimeFreq/',condition,'/');
dirSave   = strcat(folder_path,'06_Ergebnisse/EEG/TimeFreq/',condition,'/');

channels = {'Fz'};%, 'Cz', 'Pz'
fsample = 500;

SM_TimeFreqTests(dirData,dirSave,channels,fsample)

%% Time-Freq Correlations
SPtype = 'fast';
time_vec = -1.2:0.002:1.2;
freq_vec = 6:0.125:20;
dirBehavior = '/Volumes/T7/01_SchemAcS/05_Analysis/Performance_Logs/SelectiveLog/Py_Analysis_s6/data/graph_metrics/summary_similarity_df_max_dist_other_node_norm.csv';% global_similarity_measures_0_1.csv';
dirSave = strcat('/Volumes/T7/01_SchemAcS/06_Ergebnisse/EEG/TimeFreq/',condition,'/stats/');
dirFig  = strcat('/Volumes/T7/01_SchemAcS/06_Ergebnisse/EEG/TimeFreq/',condition,'/figures/');
dirData = strcat('/Volumes/T7/01_SchemAcS/06_Ergebnisse/EEG/TimeFreq/',condition,'/');
channels = {'Fz'};
freq_step = 0.125;
behaviors = {'NormLaplacianEigenDist'};


SM_TimeFreqCorr(dirSave,dirFig,dirData,dirBehavior,behaviors,channels,SPtype,freq_step,condition)

%% Williams' T2 test: Fz vs Cz/Pz correlations within the Fz cluster
SPtype = 'fast';
dirBase     = strcat('/Volumes/T7/01_SchemAcS/06_Ergebnisse/EEG/TimeFreq/',condition,'/');
dirStats    = strcat(dirBase,'stats/');
dirSave    = dirStats;
dirBehavior = '/Volumes/T7/01_SchemAcS/05_Analysis/Performance_Logs/SelectiveLog/Py_Analysis_s6/data/graph_metrics/summary_similarity_df_max_dist_other_node_norm.csv';
behaviors   = {'NormLaplacianEigenDist'};
channels    = {'Fz','Cz','Pz'};
% Fz Tmaps live in a separate subfolder in this project; Cz/Pz live in dirBase
dirData = { strcat(dirBase,'frontal_TFparams/'), dirBase, dirBase };
refChannel  = 'Fz';
clusterDirection = 'positive';

SM_WilliamsT2(dirData,dirStats,dirSave,dirBehavior,behaviors,channels, ...
    refChannel,SPtype,condition,clusterDirection)