% Print all the results
close all
clear all
rootdir = '../VOCdevkit/results/VOC2008/test2'; 
% dirlist = dir([rootdir '/comp*']);
dirlist = dir([rootdir '/']); 

% Line colors
C = {'b','k','r','g','y',[.5 .6 .7],[.8 .2 .6], [.1 .3 .5], [.2 .4 .6], [.3 .5 .7], [.7 .5 .7], [.3 .7 .3], [.8 .8 .8], [.4 .4 .4], [.6 .4 .2 ]}; 

% imset = [4 13 14]; % Different number of components
% imset = (1:4); % Different number of parts (2 components)
% imset = [5 8 13]; % Different number of parts (3 components)
% imset = [8 10 12]; % Include car context
% imset = (3:17); % all
% imset = (5:12); 
imset = [3 10 17]; 
for j =  1:1
    h = figure;     
    for i = 1:length(imset)
        expname{i} = strrep(dirlist(imset(i)).name, '_', '-'); 
        
        sumdir = [rootdir '/' dirlist(imset(i)).name '/summary/']; 

        load ([sumdir 'roc' int2str(j) '.mat']); 
        recall = ( roctable(:,6)./(roctable(:,6) + roctable(:,7))); 
        FPR = roctable(:,8) ./ (roctable(:,6) + roctable(:,7));
        plot (FPR,recall, 'LineWidth', 2, 'color', C{i})
        xlim ([0 30])
        xlabel ('false detection-to-labeled plate ratio: [FP/(TP+FN)]')
        ylabel ('hit rate [TP/(TP+FN)]')
        set(gca, 'FontSize', 16)
        hold on
    end
    legend(expname, 'Location', 'SouthEast')
    saveas(h, [rootdir '/roc' int2str(j)], 'jpg')
    % close all; 
end
% clear; 