function [hitfilter, FPRfilter, expname] = TChere_filterFP_plotROC(wo_rescore_file, rescore_max, rescore_min, svm_ratio, expdir, experiment, savename)

    if nargin < 7
        savename = 'filter_roc'; 
    end

    load ([expdir wo_rescore_file]);   % Original Data
    C = {'k','r','g','y',[.5 .6 .7],[.8 .2 .6], [.1 .3 .5], [.2 .4 .6], [.3 .5 .7], [.7 .5 .7], [.7 .8 .9]}; 

    hit = roctable(:,6)./(roctable(:,6) + roctable(:,7)); 
    FPR = roctable(:,8)./(roctable(:,6) + roctable(:,7)); 
    h = figure; 
    plot (FPR,hit, '-.','LineWidth', 2)
    expname{1} = 'Without Rescoring';  
    xlim ([0 5])
    ylim ([0.5 1])
    grid on 
    xlabel ('false detection-to-labeled plate ratio: [FP/(TP+FN)]', 'FontSize', 14)
    ylabel ('hit rate [TP/(TP+FN)]', 'FontSize', 14)
    set(gca, 'FontSize', 16)
    hold on 
    
    hitfilter = zeros(size(roctable,1),length(svm_ratio));
    FPRfilter = zeros(size(roctable,1),length(svm_ratio));
    for k = 1:length(svm_ratio)
    for k = 2
        expname{k+1} = ['\alpha = ' num2str(svm_ratio(k)) ', min = ' num2str(rescore_min(k), '%.2f') ...
            ', max = ' num2str(rescore_max(k), '%.2f')]; 
        % expname{k} = ['\alpha = ' num2str(svm_ratio(k)) ', min = ' num2str(rescore_min(k), '%.2f') ...
        %      ', max = ' num2str(rescore_max(k), '%.2f')];
        load([expdir experiment '/filter/summary/' 'box_sum_' num2str(svm_ratio(k)) '.mat']); 
        hitfilter(:,k) = tablesum(:,6)./(tablesum(:,6) + tablesum(:,7)); 
        FPRfilter(:,k) = tablesum(:,8)./(tablesum(:,6) + tablesum(:,7)); 
        plot (FPRfilter(:,k),hitfilter(:,k), 'LineWidth', 2, 'color', C{k})
        hold on
    end
    hleg = legend(expname, 'Location', 'SouthEast'); 
    set(hleg, 'FontSize', 10)
    % pause 

    % saveas(h, [expdir experiment '/' savename], 'jpg')
    % close all 
    
end