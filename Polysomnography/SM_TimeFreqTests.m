function CS_TimeFreqTests(dirData,dirSave,channels,fsample)

data_structs = loadFile(dirData,'TF','start');

for chan = 1:numel(channels)
    close all
    clear Tval_power
    
    for iSub = 1:(numel(data_structs))
        load(strcat(dirData,data_structs(iSub).name))
        sub_channs = cellfun(@(x) x.label{1},TF_params.Tmaps,'UniformOutput',false);
        if any(ismember(sub_channs,channels{chan}))
            chan_idx = find(ismember(sub_channs,channels{chan}));
        else
            continue
        end

        Tval_power(iSub,:,:)  = TF_params.Tmaps{chan_idx}.powspctrm;
    end
    
    Tval_power(sum(Tval_power,[2 3]) == 0,:,:) = [];

    SOevents = permute(Tval_power,[2,3,1]);
    Match = zeros(size(SOevents));

    %perform cluster-based permutation test
    dependent_samples = 'false';
    p_threshold = 0.05;
    two_sided = 'true';
    num_permutations = 5000;

    [clusters, p_values, t_sums] = permutest(SOevents, Match, ...
        dependent_samples, p_threshold, num_permutations,two_sided);
    
    save(strcat(dirSave,'stats/clusters_',channels{chan}),'clusters')
    save(strcat(dirSave,'stats/pvalues_',channels{chan}),'p_values')
    save(strcat(dirSave,'stats/t_sums_',channels{chan}),'t_sums')

    %plot the significant clusters
    colV = nan(size(SOevents,1)*size(SOevents,2),1);
    for n = 1:numel(find(p_values(:) < 0.06))
        colV(clusters{n},:) = t_sums(n);
    end

    xlim = [-1.2 1.2];
    ylim = [4 20];
    times2save = -1.2:(1/fsample):1.2;
    frex = linspace(4,20,size(SOevents,1));

    figure(1)
    imageCluster = reshape(colV,[size(SOevents,1),size(SOevents,2)]);
    b = imagesc(times2save,frex,imageCluster);
    set(gca,'Box','off','Ydir','normal','YLim',ylim,'Xlim',xlim)
    set(gcf,'Color',[1 1 1])
    set(b,'AlphaData',~isnan(imageCluster))
    title('Significant Clusters of T-Values')
    xlabel('Time')
    ylabel('Frequency')

    %plot the group level TF map 
    Tvalue_map = mean(Tval_power,1);
    Tmap_power = permute(Tvalue_map,[2,3,1]);

    imageCluster(abs(imageCluster) < t_sums(numel(t_sums))) = 0;
    imageCluster(isnan(imageCluster)) = 0;

    figure(2)
    clf
    imagesc(times2save,frex,Tmap_power);
    colormap(brewermap([],'-RdBu'))
    colorbar('eastoutside')
    set(gca,'Ydir','normal','YLim',ylim,'Xlim',xlim)
    clim([-1 3.2])
    set(gcf,'Color',[1 1 1])
    xlabel('Time (s) from SO Trough')
    ylabel('Frequency (Hz)');
    hold on
    contour(times2save,frex,logical(imageCluster),1,'linecolor','k','LineWidth',1);
    h_ax = gca;
    h_ax_line = axes('position', get(h_ax, 'position'),'YLim', [-100 30]); % Create a new axes in the same position as the first one, overlaid on top
    %p = plot(times2save, data1(501:1701));
    %p.LineWidth = 2;
    %p.Color = [0.5 0.5 0.5];%[0.54 0 0];
    set(h_ax_line, 'YAxisLocation', 'right', 'xlim', get(h_ax, 'xlim'), 'color', 'none'); % Put the new axes' y labels on the right, set the x limits the same as the original axes', and make the background transparent
    ylabel(h_ax, 'Frequency (Hz)');
    %ylabel(h_ax_line, 'Amplitude (µV)');
    saveas(gcf,strcat(dirSave,'figures/Average_Tmap_',channels{chan},'.pdf'))
end