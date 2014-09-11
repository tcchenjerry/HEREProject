function TChere_plotROC(fname, savedir, Nbox)

nLB = 9; % Number of lines before the data

% readDir = './'; 
% fname = 'plates_roc_validation_th_0.0.txt'; 
% fname = [readDir fname]; 
if (strcmp(fname(end-3:end),'.txt'))
    fid = fopen (fname, 'r'); 

    for i = 1:nLB
       fgetl(fid); 
    end

    roctable = zeros (17, 8); 

    for i = 1:17
        tline = fgetl(fid); 
        C = strsplit(tline, ' ');
        for j = 2:9
            roctable (i,j-1) = str2double(C{j}); 
        end
    end
else 
    load (fname); 
    roctable = tablesum; 
end

recall = ( roctable(:,6)./(roctable(:,6) + roctable(:,7))); 
FPR = roctable(:,8) ./ (roctable(:,6) + roctable(:,7)); 
h = figure; 
plot (FPR,recall, 'LineWidth', 2)
xlim ([0 20])
xlabel ('false detection-to-labeled plate ratio: [FP/(TP+FN)]')
ylabel ('hit rate [TP/(TP+FN)]')
set(gca, 'FontSize', 16)

saveas(h, [savedir 'roc' int2str(Nbox)], 'jpg')
save([savedir 'roc' int2str(Nbox) '.mat'], 'roctable')

end