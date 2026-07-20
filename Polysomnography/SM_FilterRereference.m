function SM_FilterRereference(dirData,dirExcel,dirSave)

%save as mat, filtered
refInfo = readtable(dirExcel);
dataFiles = loadFile(dirData,'.eeg','end');

%remove hidden files 
dataFiles = dataFiles(~startsWith({dataFiles.name},'.'));

for iSub = 1:numel(dataFiles)

    %exlude bad channels from refInfo
    bad_list = refInfo.bad_channel{strcmp(refInfo.Recording,dataFiles(iSub).name),1};
    
    if ~isempty(bad_list)
        bad_chans = strsplit(bad_list,',');
        for ii = 1:numel(bad_chans)
            bad_chans{ii} = strcat('-',bad_chans{ii});
        end
    else 
        bad_chans = bad_list;
    end

    % --- read in useful channels ---
    cfg = [];
    cfg.dataset    = strcat(dirData,dataFiles(iSub).name);
    cfg.continuous = 'yes';
    cfg.channel    = {'all'};

    inData = ft_preprocessing(cfg);

    % --- filter the EEG data ---
    cfg = [];
    cfg.channel     = cat(2,{'all','-EMG*','-EOG*','-EKG*'},bad_chans);
    cfg.hpfilter    = 'yes';
    cfg.hpfreq      = 0.5;
    cfg.lpfilter    = 'yes';
    cfg.lpfreq      = 35;

    datEEG = ft_preprocessing(cfg,inData);


    % --- filter and re-reference EOG data ---
    cfg = [];
    cfg.channel    = {'EOG'};
    cfg.hpfilter   = 'yes';
    cfg.hpfreq     = 0.5;
    cfg.lpfilter   = 'yes';
    cfg.lpfreq     = 35;
    cfg.reref      = 'yes';
    EOG = inData.label(contains(inData.label,'EOG'));
    
    cfg.refchannel = EOG{1};
    datEOG = ft_preprocessing(cfg,inData);

    % keep only the re-referenced channel and rename it
    datEOG.label{2} = 'EOG';

    cfg = [];
    cfg.channel = 'EOG';
    datEOG = ft_selectdata(cfg,datEOG);


    % --- filter EMG data ---
    cfg = [];
    cfg.channel    = {'EMG'};
    cfg.hpfilter   = 'yes';
    cfg.hpfreq     = 10;
    cfg.lpfilter   = 'yes';
    cfg.lpfreq     = 100;
    datEMG = ft_preprocessing(cfg,inData);

    datComb = ft_appenddata([],datEOG,datEEG,datEMG);
    datComb.ID = extractBetween(dataFiles(iSub).name,"SchemAcS_","_B2"); %CHANGE depending on condition to be processed

    data = datComb;
    %save(strcat(dirSave,datComb.ID{1},'_data_preproc.mat'),'data');
    save(strcat(dirSave,datComb.ID{1},'data_preproc.mat'),'data','-v7.3');

end

% save
%save(strcat(dirSave,'data_preproc.mat'),'data','-v7.3');


