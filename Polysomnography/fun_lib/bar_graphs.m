function bar_graphs(dirSave,figName,params,out,yLabel)

close all
figure(1)
set(gcf,'position',[10,10,450,800])
box off
set(gcf,'Color','w');
tiledlayout(numel(params),3)


%plot the spindle parameters
for param = 1:numel(params)

    for subi = 1:3
        if subi == 1
            chans = {'F3','Fz','F4'};
        elseif subi == 2
            chans = {'C3','Cz','C4'};
        else
            chans = {'P3','Pz','P4'};
        end

        output = out.(params{param});
        output_ch1 = output(strcmp(out.channels,chans{1}));
        output_ch2 = output(strcmp(out.channels,chans{2}));
        output_ch3 = output(strcmp(out.channels,chans{3}));

        nexttile
        hold on
        h1=bar(1,mean(output_ch1));
        h2=bar(2,mean(output_ch2));
        h3=bar(3,mean(output_ch3));
        h1.FaceColor='#fc8d59';
        h2.FaceColor='#ffffbf';
        h3.FaceColor='#91bfdb';
        h1.EdgeColor='#fc8d59';
        h2.EdgeColor='#ffffbf';
        h3.EdgeColor='#91bfdb';

        % Scatter plots with horizontal jitter
        jitterAmount = 0.3;  % Adjust this value to control the amount of jitter

        % Jittered X positions
        x1_jittered = 1 + (rand(size(output_ch1)) - 0.5) * jitterAmount;
        x2_jittered = 2 + (rand(size(output_ch2)) - 0.5) * jitterAmount;
        x3_jittered = 3 + (rand(size(output_ch3)) - 0.5) * jitterAmount;

        scatter(x1_jittered, output_ch1, 30, 'MarkerFaceColor', '#999999', 'MarkerEdgeColor', '#999999', 'LineWidth', 1,'MarkerFaceAlpha',0.7,'MarkerEdgeAlpha',0.7)
        scatter(x2_jittered, output_ch2, 30, 'MarkerFaceColor', '#999999', 'MarkerEdgeColor', '#999999', 'LineWidth', 1,'MarkerFaceAlpha',0.7,'MarkerEdgeAlpha',0.7)
        scatter(x3_jittered, output_ch3, 30, 'MarkerFaceColor', '#999999', 'MarkerEdgeColor', '#999999', 'LineWidth', 1,'MarkerFaceAlpha',0.7,'MarkerEdgeAlpha',0.7)

        errorbar(h1.XEndPoints,mean(output_ch1),std(output_ch1)/sqrt(length(output_ch1)),'LineStyle','none','Color','k','LineWidth',2.5)
        errorbar(h2.XEndPoints,mean(output_ch2),std(output_ch2)/sqrt(length(output_ch2)),'LineStyle','none','Color','k','LineWidth',2.5)
        errorbar(h3.XEndPoints,mean(output_ch3),std(output_ch3)/sqrt(length(output_ch3)),'LineStyle','none','Color','k','LineWidth',2.5)
        hold off

        ymin = min([output_ch1;output_ch2;output_ch3])*0.9;
        ymax = max([output_ch1;output_ch2;output_ch3])*1.1;
        xlim([0.5 3.5])
        ylim([ymin ymax])
        xticks([1 2 3])
        xticklabels(chans)
        ylabel(strcat({yLabel},{' '},{params{param}}),'Fontsize',14,"FontWeight","bold")
        xlabel("Channel","FontSize",14,"FontWeight","bold")

        saveas(gcf,strcat(dirSave,'figures/',figName,'.pdf'))
    end
end