function SM_SPSO_PETHs(dirCouple,dirSOs, dirSave,dirData,dirSaveERP,TOI,sp_type,channel_list)

%parameters
dur_interval = TOI; %in seconds
binsize = 0.1; %in seconds
no_of_bins = round(dur_interval*2/binsize);



%% create SWA ERPs
load(strcat(dirSOs,'SO_events.mat'))
dataFiles = loadFile(dirData,'.mat','end');
dataFiles = dataFiles(~startsWith({dataFiles.name},'.'));

if strcmp(sp_type,'Slow')
    res_slowwaves_events([7,9,12,14]) = [];
end 

%initialize SWA ERP Matrix
avg_timelock_SWA = zeros(numel(res_slowwaves_events),1201);

for chan = 1:numel(channel_list)
    for iSub = 1:numel(res_slowwaves_events)
        %load data
        load(strcat(dirData,dataFiles(iSub).name));
        chan_idx = find(strcmp(data.label,channel_list(chan)));

        if isempty(chan_idx)
            continue
        end 

        data.label = data.label(chan_idx);
        data.trial = {data.trial{1}(chan_idx,:)};
        data.dimord = 'chan_time';

        SO_troughs = res_slowwaves_events{iSub}.table.seconds_trough_max(strcmp(res_slowwaves_events{iSub}.table.channel,channel_list(chan)));
        
        if isempty(data.label) || isempty(SO_troughs)
            continue 
        end 

        %define a 1.2s (or 5s) window around the SO trough for channel of interest
        padding_buffer = dur_interval*data.fsample;
        SO_trough_sample = SO_troughs*data.fsample;%from sec to samples

        cfg         = [];
        cfg.trl     = [SO_trough_sample-padding_buffer,...
            SO_trough_sample+padding_buffer,...
            repmat(-(data.fsample+padding_buffer),numel(SO_trough_sample),1)];
        cfg.trl    = round(cfg.trl);
        data_events = ft_redefinetrial(cfg, data);

        cfg         = [];
        timelock    = ft_timelockanalysis(cfg, data_events);

        cfg = [];
        cfg.lpfilter = 'yes';
        cfg.lpfreq   = 3;
        timelock_SWA = ft_preprocessing(cfg, timelock); %time-locked event


        avg_timelock_SWA(iSub,:) = timelock.avg;

    end

    res_avg_timelock_SWA = mean(avg_timelock_SWA,1);
    save(strcat(dirSaveERP,'SWA_ERP/avg_timelock_SWA_',channel_list{chan}),'res_avg_timelock_SWA')

end



%% create PETHs
%initiate the results figure 
clf
figure(1)
set(gcf,'Color','w');

%get the data
load(strcat(dirCouple,'coupling_output.mat'))
res_matches = coupling_out.res_match_test_targets;

for chan = 1:numel(channel_list)
    %initialize output matrices 
    res_spin_histocount = zeros(numel(res_matches),no_of_bins);
    res_spin_histonorm = zeros(numel(res_matches),no_of_bins);

    for iSub = 1:numel(res_matches)
    
        %SP & SO max troughs
        SO_troughs = res_matches{iSub}.table.te_seconds_trough_max(strcmp(res_matches{iSub}.table.te_channel,channel_list(chan)));
        SP_troughs = res_matches{iSub}.table.ta_seconds_trough_max(strcmp(res_matches{iSub}.table.ta_channel,channel_list(chan)));
        
        %not all participants have all channels 
        if isempty(SO_troughs) || isempty(SP_troughs)
            continue
        end 

        begTrial = SO_troughs-dur_interval;
        endTrial = SO_troughs+dur_interval;

        %exclude the SO troughs with overlapping time intervals
        overlaps = begTrial(2:end) - endTrial(1:end-1);
        SO_troughs(overlaps < 0) = [];

        %create spindle distributions locked to SO troughs
        spin_distr = zeros(length(SO_troughs),no_of_bins);

        for iTrial = 1:length(SO_troughs)
            bin_ints = begTrial(iTrial) : binsize : endTrial(iTrial);
            spin_distr(iTrial,:) = histcounts(SP_troughs, bin_ints);
        end

        spin_histocount = sum(spin_distr);
        spin_histonorm = (spin_histocount/sum(spin_histocount)).*100; %normalize (%), divide by total number of spindles in timewindow

        res_spin_histocount(iSub,:) = spin_histocount;
        res_spin_histonorm(iSub,:) = spin_histonorm;
    end

    %save the results per channel
    save(strcat(dirSave,'res_spin_histocount_',channel_list{chan}),'res_spin_histocount')
    save(strcat(dirSave,'res_spin_histonorm_',channel_list{chan}),'res_spin_histonorm')
    
   
    %plot the results
    %load the SWA ERPs

    load(strcat(dirSaveERP,'SWA_ERP/avg_timelock_SWA_',channel_list{chan}));
    %time = (-dur_interval) : 0.002 : dur_interval;
    colors = {'#fc8d59','#fc8d59','#fc8d59','#ffffbf','#ffffbf','#ffffbf','#91bfdb','#91bfdb','#91bfdb'};

    subplot(2,numel(channel_list),chan)
    p = plot(res_avg_timelock_SWA);
    p.LineWidth = 2;
    p.Color = '#999999';
    axis tight; axis off
    %ax = gca;  ax.Position = [0.13 0.55 0.77 0.24];
    xline(0,'--k','Linewidth',1.0)

    subplot(2,numel(channel_list),chan+numel(channel_list))
    x= 1:size(res_spin_histonorm,2);
    data2 = mean(res_spin_histonorm);
    err = std(res_spin_histonorm)/sqrt(size(res_spin_histonorm,1));
    b = bar(data2); box off
    b.FaceColor =colors{chan}; %fSP: [0.85 0.33 0.10]
    b.FaceAlpha = 1;
    axis tight
    %xlabel('Time (s) relative to SO trough')
    %set(gca,'Clipping','Off','Color',[1 1 1],'XTick',[1 10 20],'XTickLabel',[-1 0 1],'YTickLabel',[])
    xline(10,'--k','Linewidth',1.0);
    h = line([0 0],[0 30]); ylim([0 12])
    set(h,'LineWidth',1,'color','k')

    hold on
    er = errorbar(x,data2,err,err);
    er.Color = [0.4 0.4 0.4];
    er.LineWidth = 1;
    er.LineStyle = 'none';
    hold off

end

%save the results figure
saveas(gcf,strcat(dirSave,'figures/PETHs.pdf'))



%% test against permuted reference distribution
clear histocount histonorm 

for chan = 1:numel(channel_list)
    load(strcat(dirSave,'res_spin_histonorm_',channel_list{chan}))
    res_avg_spinshuffle = zeros([size(res_spin_histonorm)]);
    
    for iSub = 1:size(res_spin_histonorm,1)

        hist_i = res_spin_histonorm(iSub,:);
        spin_shuffle = zeros(1000,length(hist_i));

        for ii = 1:1000 %shuffle the bin values 1000 times
            spin_ii = hist_i(randperm(length(hist_i)));
            spin_shuffle(ii,:) = spin_ii;

        end

        avg_spinshuffle = mean(spin_shuffle); %create average of surogates
        %[h,p] = ttest(spin_histonorm,avg_spinshuffle); %paired ttest: randomization vs real data

        res_avg_spinshuffle(iSub,:) = avg_spinshuffle;

    end

    figure(3) %plot the random and real distribution
    subplot(211)
    bar(mean(res_avg_spinshuffle))
    subplot(212)
    bar(mean(res_spin_histonorm))

    %cluster-based permutation (paired t-)test for each bin:
    %convert matrices such that subjects (source of test variance) are in the
    %columns
    res_avg_spinshuffle1 = res_avg_spinshuffle';
    res_spin_histonorm1  = res_spin_histonorm';

    %set test parameters
    dependent_samples = 'true';
    p_threshold = 0.05;
    two_sided = 'true';
    num_permutations = 5000;

    [clusters, p_values, t_sums, perm_distr] = permutest(res_spin_histonorm1, res_avg_spinshuffle1, dependent_samples, ...
        p_threshold, num_permutations, two_sided); % use function permutest

    save(strcat(dirSave,'stats/p_values_SPSO_PETH_',channel_list{chan}),'p_values')
    save(strcat(dirSave,'stats/clusters_SPSO_PETH_',channel_list{chan}),'clusters')
    save(strcat(dirSave,'stats/tsums_SPSO_PETH_',channel_list{chan}),'t_sums')
    save(strcat(dirSave,'stats/perm_distr_SPSO_PETH_',channel_list{chan}),'perm_distr')
end

end 
