function SM_WilliamsT2(dirData,dirStats,dirSave,dirBehavior,behaviors,channels,refChannel,SPtype,condition,clusterDirection)
%SM_WilliamsT2 Compare correlations between SMI and avg cluster T-values
%across channels using Williams' T2 test for dependent correlations.
%
%   The cluster mask is reconstructed from the bootstrap p-value map of the
%   reference channel (refChannel, e.g. 'Fz') that was saved by
%   SM_TimeFreqCorr. For every subject and every channel, T-values are
%   averaged within that cluster. Then for each non-reference channel:
%       r_jk = corr(SMI, Tavg_ref)
%       r_jh = corr(SMI, Tavg_other)
%       r_kh = corr(Tavg_ref, Tavg_other)
%   are entered into Williams' T2 (Steiger, 1980; Williams, 1959) testing
%   H1: r_jk > r_jh (one-sided) and the standard two-sided alternative.
%
%   Inputs match the conventions of SM_TimeFreqCorr.
%   clusterDirection: 'positive' (default), 'negative', or 'both'.

if nargin < 10 || isempty(clusterDirection)
    clusterDirection = 'positive';
end

if strcmp(SPtype,'fast')
    times2save = 0.25:0.002:0.55;
    frex = 12.625:0.125:16;
    cols = 700:850;
    rows = 54:81;
elseif strcmp(SPtype,'slow')
    times2save = -0.2:0.002:0.15;
    frex = 9.0:0.125:12.5;
    rows = 26:53;
    cols = 500:675;
end

% dirData may be a single path (used for all channels) or a cell array of
% per-channel paths matching `channels`. The Fz T-maps live in a separate
% subfolder in this project, so per-channel dirs are useful.
if ischar(dirData) || isstring(dirData)
    dataDirs = repmat({char(dirData)},1,numel(channels));
elseif iscell(dirData) && numel(dirData) == numel(channels)
    dataDirs = dirData;
else
    error('dirData must be a path or a cell array of paths (one per channel).');
end

for iB = 1:numel(behaviors)
    behavior = behaviors{iB};

    % Reconstruct cluster mask from refChannel bootstrap p-values
    refFile = fullfile(dirStats,strcat('b_pv_',SPtype,'_',refChannel,'_',behavior,'.mat'));
    S = load(refFile);
    b_pv_ref = S.b_pv;

    switch clusterDirection
        case 'positive'
            psign = b_pv_ref > 0.95;
        case 'negative'
            psign = b_pv_ref < 0.025;
        case 'both'
            psign = (b_pv_ref > 0.975) | (b_pv_ref < 0.025);
    end

    clust = bwconncomp(psign);
    pclust = false(clust.ImageSize);
    for jj = 1:numel(clust.PixelIdxList)
        pclust(clust.PixelIdxList{jj}) = true;
    end

    nClusterPix = nnz(pclust);
    if nClusterPix == 0
        warning('No %s cluster pixels found for %s (%s). Skipping.', ...
            clusterDirection,refChannel,behavior);
        continue
    end

    % Per-subject, per-channel average T in cluster
    nChan = numel(channels);
    Tavg = cell(1,nChan);
    IDs  = cell(1,nChan);

    fprintf('\n[SM_WilliamsT2] cluster pixels = %d\n',nClusterPix);

    for chan = 1:nChan
        channel = channels{chan};
        Tvec = [];
        chIDs = {};
        dataFiles = loadFile(dataDirs{chan},'TF','start');
        fprintf('[SM_WilliamsT2] %s: scanning %s -> %d files\n', ...
            channel,dataDirs{chan},numel(dataFiles));
        for iSub = 1:numel(dataFiles)
            D = load(fullfile(dataDirs{chan},dataFiles(iSub).name));
            TF_params = D.TF_params;
            sub_channs = cellfun(@(x) x.label{1},TF_params.Tmaps,'UniformOutput',false);
            if ~ismember(channel,sub_channs)
                continue
            end
            Tmap = squeeze(TF_params.Tmaps{strcmp(sub_channs,channel)}.powspctrm);
            Tsub = Tmap(rows,cols);
            Tvec(end+1,1) = mean(Tsub(pclust),'all'); %#ok<AGROW>
            id = TF_params.ID;
            if iscell(id), id = id{1}; end
            if isstring(id), id = char(id); end
            chIDs{end+1,1} = id; %#ok<AGROW>
        end
        Tavg{chan} = Tvec;
        IDs{chan}  = chIDs;
        fprintf('[SM_WilliamsT2] %s: %d subjects with this channel\n', ...
            channel,numel(chIDs));
    end

    % Load and filter behavior
    behav_data = readtable(dirBehavior);
    if isstring(behav_data.ID),     behav_data.ID     = cellstr(behav_data.ID);     end
    if isstring(behav_data.extend), behav_data.extend = cellstr(behav_data.extend); end
    behav_data = behav_data(behav_data.Session == 1 & strcmp(behav_data.extend,'0_1'),:);

    if strcmp(condition,'wake')
        sleep = behav_data(endsWith(behav_data.ID,'W'),[1 2 7]);
        excl = {'22W','36W'};
        sleep(ismember(sleep.ID,excl),:) = [];
    else
        sleep = behav_data(endsWith(behav_data.ID,'S'),[1 2 7]);
    end

    if strcmp(SPtype,'slow') && strcmp(condition,'sleep')
        excl = {'14S','16S','19S','21S'};
        sleep(ismember(sleep.ID,excl),:) = [];
    end

    sleepIDs = cellstr(sleep.ID);
    fprintf('[SM_WilliamsT2] behavior table after filter: %d rows\n',height(sleep));

    refIdx = find(strcmp(channels,refChannel),1);
    if isempty(refIdx)
        error('refChannel %s not found in channels list.',refChannel);
    end

    % Three-way intersection across all channels and behavior; a single
    % subject set used for every channel-wise correlation, every Williams T2
    % pair, and the Fisher r-to-z sleep r.
    commonIDs = cellstr(IDs{1});
    fprintf('[SM_WilliamsT2] IDs{1} (%s): %d subjects\n',channels{1},numel(commonIDs));
    for chan = 2:nChan
        commonIDs = intersect(commonIDs,cellstr(IDs{chan}),'stable');
        fprintf('[SM_WilliamsT2]  after intersect with %s: %d\n', ...
            channels{chan},numel(commonIDs));
    end
    commonIDs = intersect(commonIDs,sleepIDs,'stable');
    fprintf('[SM_WilliamsT2]  after intersect with behavior: %d\n',numel(commonIDs));

    nSub = numel(commonIDs);
    if nSub < 4
        warning('Not enough subjects (n=%d) after alignment for %s. Skipping.', ...
            nSub,behavior);
        continue
    end

    % Align T-averages and SMI to commonIDs
    Tmat = zeros(nSub,nChan);
    for chan = 1:nChan
        [~,idx] = ismember(commonIDs,cellstr(IDs{chan}));
        Tmat(:,chan) = Tavg{chan}(idx);
    end
    [~,idx] = ismember(commonIDs,sleepIDs);
    perform = 1 - sleep.(behavior)(idx);

    rPerChan = zeros(1,nChan);
    pPerChan = zeros(1,nChan);
    for chan = 1:nChan
        [r,p] = corr(Tmat(:,chan),perform);
        rPerChan(chan) = r;
        pPerChan(chan) = p;
    end
    R = corr(Tmat);
    nPerChan = repmat(nSub,1,nChan);

    % Williams' T2 on the common n=nSub set
    williams = struct();
    n = nSub;
    for chan = 1:nChan
        if chan == refIdx, continue; end
        rjk = rPerChan(refIdx);
        rjh = rPerChan(chan);
        rkh = R(refIdx,chan);

        detR = 1 - rjk^2 - rjh^2 - rkh^2 + 2*rjk*rjh*rkh;
        rbar = (rjk + rjh)/2;
        denom = 2*((n-1)/(n-3))*detR + rbar^2 * (1-rkh)^3;
        t = (rjk - rjh) * sqrt( ((n-1)*(1+rkh)) / denom );
        df = n - 3;
        p_two = 2 * (1 - tcdf(abs(t),df));
        p_one_greater = 1 - tcdf(t,df);

        W = struct( ...
            't',t,'df',df,'n',n, ...
            'r_ref',rjk,'r_other',rjh,'r_predictors',rkh, ...
            'p_two_sided',p_two,'p_one_sided_ref_greater',p_one_greater);
        williams.(channels{chan}) = W;
    end

    % Bundle results
    results = struct();
    results.behavior         = behavior;
    results.SPtype           = SPtype;
    results.condition        = condition;
    results.channels         = channels;
    results.refChannel       = refChannel;
    results.clusterDirection = clusterDirection;
    results.cluster_mask     = pclust;
    results.cluster_nPixels  = nClusterPix;
    results.times2save       = times2save;
    results.frex             = frex;
    results.IDs              = commonIDs;
    results.Tmat             = Tmat;
    results.SMI              = perform;
    results.r_per_channel    = rPerChan;
    results.p_per_channel    = pPerChan;
    results.n                = nSub;
    results.predictor_corr   = R;
    results.williams         = williams;

    outFile = fullfile(dirSave,strcat('WilliamsT2_',SPtype,'_',refChannel, ...
        '_vs_others_',clusterDirection,'_',behavior,'.mat'));
    save(outFile,'results');

    % Console summary
    fprintf('\n=== Williams'' T2 (%s spindles, %s cluster, n=%d) ===\n', ...
        SPtype,clusterDirection,nSub);
    fprintf('Cluster pixels = %d  |  ref = %s  |  behavior = %s\n', ...
        nClusterPix,refChannel,behavior);
    for chan = 1:nChan
        fprintf('  r(%s, SMI) = % .4f   (p = %.4f)\n', ...
            channels{chan},rPerChan(chan),pPerChan(chan));
    end
    for chan = 1:nChan
        if chan == refIdx, continue; end
        W = williams.(channels{chan});
        fprintf(['Williams T2  %s vs %s :  t(%d) = % .3f  | ', ...
            ' p(2-sided) = %.4f  |  p(1-sided %s>%s) = %.4f\n'], ...
            refChannel,channels{chan},W.df,W.t,W.p_two_sided, ...
            refChannel,channels{chan},W.p_one_sided_ref_greater);
    end
end

end
