dataDir = '/Volumes/T7/01_SchemAcS/04_Data/EEG_Recordings/raw_B2_wake/';

%% 1. Load BrainVision files using ft_preprocessing
cfg1 = [];
cfg1.dataset = strcat(dataDir, 'SchemAcS_06W_B2.vhdr');  % point to the .vhdr file
cfg1.continuous = 'yes';
data1 = ft_preprocessing(cfg1);

cfg2 = [];
cfg2.dataset = strcat(dataDir, 'SchemAcS_06W_B2_02.vhdr');
cfg2.continuous = 'yes';
data2 = ft_preprocessing(cfg2);

%% 2. Append the two datasets
cfg = [];
cfg.keepsampleinfo = 'no';  % avoids sample offset conflicts between files
mergedData = ft_appenddata(cfg, data1, data2);

%% 3. Build header and event structures for writing
% Reconstruct header from merged data
hdr = [];
hdr.Fs          = mergedData.fsample;
hdr.nChans      = length(mergedData.label);
hdr.label       = mergedData.label;
hdr.nTrials     = 1;
hdr.nSamplesPre = 0;
hdr.nSamples    = size(mergedData.trial{1}, 2);

% Convert cell trial to matrix (works for continuous data)
dat = mergedData.trial{1};  % [nChans x nSamples]

%% 4. Read and merge events/markers from both original files
event1 = ft_read_event(fullfile(dataDir, 'SchemAcS_06W_B2.vhdr'));
event2 = ft_read_event(fullfile(dataDir, 'SchemAcS_06W_B2_02.vhdr'));

% Shift event2 sample indices by the length of data1
nSamples1 = size(data1.trial{1}, 2);
for i = 1:length(event2)
    event2(i).sample = event2(i).sample + nSamples1;
end

% Merge event arrays
events = [event1, event2];

%% 5. Write output in BrainVision format
outputFile = fullfile(dataDir, 'concatenated.vhdr');
ft_write_data(outputFile, dat, ...
    'header', hdr, ...
    'event',  events, ...
    'dataformat', 'brainvision_eeg');

disp('Done! Files written: concatenated.vhdr / .eeg / .vmrk');