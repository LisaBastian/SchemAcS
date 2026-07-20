function SM_TimeFreqCorr(dirSave,dirFig,dirData,dirBehavior,behaviors,channels,SPtype,freq_step,condition)
%SPINDLE TF-WINDOW: +25-+55ms with x(371:448 = 78), 13:16 Hz with y(28:41 = 14)


if strcmp(SPtype,'fast')
times2save = 0.25:0.002:0.55;
frex = 12.625:freq_step:16;
cols = 700:850; %0.3-0.6s after SO trough (see PETHs);
rows = 54:81;%find(ismember(freq_vec,frex));
elseif strcmp(SPtype,'slow')
times2save = -0.2:0.002:0.15;
frex = 9.0:freq_step:12.5;
rows = 26:53;
cols = 500:675;
end 

szx = length(cols);
szy =length(rows);


dataFiles = loadFile(dirData,'TF','start');


for iB = 1:numel(behaviors)
    for chan = 1:numel(channels)
        clear Tmap sleep Tvalues b_pv channel
        Tmap = [];
        IDs  = {};
        channel = channels{chan};


        for iSub = 1:numel(dataFiles)
            load(strcat(dirData,dataFiles(iSub).name))
            sub_channs = cellfun(@(x) x.label{1},TF_params.Tmaps,'UniformOutput',false);

            if ~ismember(sub_channs,channel)
                continue
           else
                Tmap = cat(3,Tmap,squeeze(TF_params.Tmaps{strcmp(sub_channs,channel)}.powspctrm));
                IDs(iSub)  = TF_params.ID;
            end
        end

        Tvalues = Tmap(rows,cols,:);
        Tmeans = squeeze(mean(Tvalues,[1,2]));
        IDs = IDs(cellfun(@(x) ~isempty(x),IDs));

        % for jj = 1:size(Tvalues,3)
        %     figure
        % 
        %     imagesc(times2save,frex,squeeze(Tvalues(:,:,jj)))
        %     set(gca, 'YDir','normal')
        %     xlabel('Time')
        %     ylabel('Frequency')
        % end

        %spectral distances 
        behav_data = readtable(dirBehavior);
        behav_data = behav_data(behav_data.Session == 1 & strcmp(behav_data.extend,'0_1'),:);

        if strcmp(condition,'wake')
            sleep  = behav_data(endsWith(behav_data.ID,'W'),[1 2 7]);
            exclude = {'22W','36W'}; %EEG data were not usable for these participants
            sleep(ismember(sleep.ID,exclude),:) = []; 
            IDs(ismember(IDs,exclude)) = [];
            Tvalues(:,:,ismember(IDs,exclude)) = [];
        else 
            sleep  = behav_data(endsWith(behav_data.ID,'S'),[1 2 7]);
        end
        
        %exclude participants without slow spindles
        if strcmp(SPtype,'slow') && strcmp(condition,'sleep')
            exclude = {'14S','16S','19S','21S'};
            sleep(ismember(sleep.ID,exclude),:) = []; 
            IDs(ismember(IDs,exclude)) = [];
            Tvalues(:,:,ismember(IDs,exclude)) = [];
        end 
        

        %exclude the participants that don't have behavioral and sleep data
        sleep  = sleep(ismember(sleep.ID,IDs),:);
        perform = 1-(sleep.(behaviors{iB}));
        Tvalues = Tvalues(:,:,ismember(IDs,sleep.ID));

        %compute the correlations per pixel in TF map: negative
        %correlations are expected
        rohs = zeros(height(Tvalues),numel(Tvalues(1,:,1)));
        pvals = zeros(height(Tvalues),numel(Tvalues(1,:,1)));

        for ii = 1:height(rohs)
            for jj = 1:numel(rohs(1,:,1))
                [roh, pval] = corr(squeeze(Tvalues(ii,jj,:)),perform);
                rohs(ii,jj) = roh;
                pvals(ii,jj) = pval;
            end
        end

        %plot the roh values
        figure
        imagesc(times2save,frex,rohs);
        colormap(brewermap([],'PuOr'))
        colorbar
        set(gca,'Box','off','Ydir','normal')
        set(gcf,'Color',[1 1 1])
        ylabel('Frequency (Hz)')
        xlabel('Time (s)')
        title(sprintf('Correlation over %s for %s spindles',channel,SPtype))
        colorbar('eastoutside')
        

        %saveas(gcf,'Correlation_TmapEGO_behav_final_FS.png')

        %perform a bootstrapped correlation for each pixel in TF map
        nReps = 5000;
        CIrange = 95;  %alpha <.01 (two-tailed)
        b_pv = zeros([height(rohs) length(rohs)]);

        for xx = 1:height(rohs)
            for yy = 1:length(rohs)
                bootstats = bootstrp(5000, @(x,y) corr(x,y), squeeze(Tvalues(xx,yy,:)), perform);%bootstrp(5000,@corr,squeeze(Tvalues(xx,yy,:)),perform);
                b_pv(xx,yy) = (length(find(bootstats(:) > 0)) +1) / (length(bootstats)+1); % abs(rohs(xx,yy)

            end
        end
        
        save(strcat(dirSave,'rohs_',SPtype,'_',channel,'_',behaviors{iB}),'rohs')
        save(strcat(dirSave,'b_pv_',SPtype,'_',channel,'_',behaviors{iB}),'b_pv')


        psign1 = b_pv < 0.025;  %0 and 1 sign. cluster matrix
        psign2 = b_pv > 0.975;
        psign = psign1 + psign2;
        clust = bwconncomp(psign);
        pclust = zeros(clust.ImageSize);
        
        for jj = 1:numel(clust.PixelIdxList)
            pclust(clust.PixelIdxList{jj}) = 1;
        end 
        

        %compute average roh and p-value for sign. cluster 
        avg_roh = mean(rohs(find(pclust == 1)),'all');
        avg_p   = mean(b_pv(find(pclust == 1)),'all');
        avg_stats = [avg_roh,avg_p];
        save(strcat(dirSave,'avg_stats_',SPtype,'_',channel,'_',behaviors{iB}),'avg_stats')

        %plot the significant clusters in correlation map 
        figure
        imagesc(pclust)
        saveas(gcf,strcat(dirFig,'TF_CorrCluster_',SPtype,'_',channel,'.pdf'))

        figure
        clf
        imagesc(times2save,frex,rohs);
        colormap(brewermap([],'PuOr'))
        colorbar
        set(gca,'Box','off','Ydir','normal')
        set(gcf,'Color',[1 1 1])
        xlabel('Time (s)')
        ylabel('Frequency (Hz)')
        title(sprintf('Correlation with Cluster over %s for %s spindles',channel,SPtype))
        hold on
        contour(times2save,frex,pclust,1,'linecolor',[1 1 1],'LineWidth',1);
        hold off
        saveas(gcf,strcat(dirFig,'TF_Correlations_',SPtype,'_',channel,'.pdf'))


        %create a regression plot 
        max_pix = find(rohs == (max(rohs,[],'all'))); 

        for m = 1:size(Tvalues,3)
            max_page = Tvalues(:,:,m);
            max_pixel = max_page(max_pix);
            max_pixel_avg = mean(max_pixel);
            max_pixels(m,1) = max_pixel_avg;
        end


        x = max_pixels; %perform the regression for the most significant pixel in the ROI
        y = perform;
        [r,p] = corr(x,y);
        max_stats = [r,p];
        save(strcat(dirSave,'max_stats_',SPtype,'_',channel,'_',behaviors{iB}),'max_stats')
        

        figure
        set(gcf,'Color',[1 1 1])
        
        % Fit linear regression
        p = polyfit(x, y, 1);
        xf = linspace(min(x), max(x), 100);
        yf = polyval(p, xf);
        
        % Compute standard error
        n = length(x);
        yhat = polyval(p, x);
        residuals = y - yhat;
        s2 = sum(residuals.^2) / (n - 2);
        xmean = mean(x);
        SE = sqrt(s2 * (1/n + (xf - xmean).^2 / sum((x - xmean).^2)));
        
        % Draw shading
        hold on
        fill([xf, fliplr(xf)], [yf+SE, fliplr(yf-SE)], ...
            'b', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        
        % Then scatter on top
        scatter(x, y, 'filled', 'MarkerEdgeColor','black', 'MarkerFaceColor','black')
        
        % Then regression line on top
        plot(xf, yf, 'b', 'LineWidth', 1.5);
        hold off
        
        title(sprintf('Max. Correlation over %s for %s spindles', channel, SPtype), 'FontSize', 14);
        ylim([0.995 0.999])
        xlabel('T-Values');
        ylabel('SMI');
        saveas(gcf,strcat(dirFig,'TF_MaxCorrCluster_',SPtype,'_',channel,'.pdf'))

    end
end