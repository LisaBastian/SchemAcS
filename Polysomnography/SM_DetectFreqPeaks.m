function TS_DetectFreqPeaks(dirData,dirSave,wrkDirs,nPeaks)


for ii = 1:length(wrkDirs)
    dataFiles = loadFile(strcat(dirData,wrkDirs{ii}),'SchemAcS','start');
    dataFiles = dataFiles(contains({dataFiles.name},'freqSpectrum'));
    
    IDs = cell(1,length(dataFiles));
    conds = cell(1,length(dataFiles));

    for iSub = 1:numel(dataFiles)
        load(strcat(strcat(dirData,'/',wrkDirs{ii},'/'),dataFiles(iSub).name));

        cfg                 = [];
        cfg.channel         = unique(res_power_bin.table.channel)';
        cfg.peaknum         = nPeaks; % either 1 or 2 (default)
        res_freqpeaks(iSub) = st_freqpeak(cfg,res_power_bin);

        IDs{iSub} = extractBefore(dataFiles(iSub).name,'_');
        conds{iSub} = wrkDirs{ii};

    end

    peak_table = vertcat(res_freqpeaks.table);
    peak_table.IDs = IDs(:);
    peak_table.condition = conds(:);
    writetable(peak_table,strcat(dirSave,'spindle_power_peak_freqs_',wrkDirs{ii},'.csv'))

end
