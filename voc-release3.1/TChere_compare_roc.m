clear all
close all

load('/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/results/VOC2008/comp_3_part_4_structure_5_3/summary/roc1_conv.mat');

recall = ( roctable(:,6)./(roctable(:,6) + roctable(:,7))); 
FPR = roctable(:,8) ./ (roctable(:,6) + roctable(:,7)); 
h = figure; 
plot (FPR,recall, 'LineWidth', 2)
xlim ([0 20])
xlabel ('false detection-to-labeled plate ratio: [FP/(TP+FN)]')
ylabel ('hit rate [TP/(TP+FN)]')
set(gca, 'FontSize', 16)

hold on 


load('/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/results/VOC2008/comp_3_part_4_structure_5_3/summary/roc1_kmean_256.mat');

recall = ( roctable(:,6)./(roctable(:,6) + roctable(:,7))); 
FPR = roctable(:,8) ./ (roctable(:,6) + roctable(:,7)); 

plot (FPR,recall, 'k','LineWidth', 2)

hold on

load('/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/results/VOC2008/comp_3_part_4_structure_5_3/summary/roc1_hier_16.mat');

recall = ( roctable(:,6)./(roctable(:,6) + roctable(:,7))); 
FPR = roctable(:,8) ./ (roctable(:,6) + roctable(:,7)); 

plot (FPR,recall, 'r','LineWidth', 2)

hold on 

load('/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/results/VOC2008/comp_3_part_4_structure_5_3/summary/roc1_hier_32.mat');

recall = ( roctable(:,6)./(roctable(:,6) + roctable(:,7))); 
FPR = roctable(:,8) ./ (roctable(:,6) + roctable(:,7)); 

plot (FPR,recall, 'g','LineWidth', 2)



ylim([0.7 1])
xlim([0 30])
legend({'Convolution', 'Look up table (Dic size = 256)', 'Look up table (hierarchical - 16)' 'Look up table (hierarchical - 32)'})
grid on 

% load('/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/results/VOC2008/comp_3_part_4_structure_5_3/summary/roc1_lut_hier.mat');
% 
% recall = ( roctable(:,6)./(roctable(:,6) + roctable(:,7))); 
% FPR = roctable(:,8) ./ (roctable(:,6) + roctable(:,7)); 
% 
% plot (FPR,recall, 'g','LineWidth', 2)
% 
% hold on
% 
% load('/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/results/VOC2008/comp_3_part_4_structure_5_3/summary/roc1_lut_hier_32.mat');
% 
% recall = ( roctable(:,6)./(roctable(:,6) + roctable(:,7))); 
% FPR = roctable(:,8) ./ (roctable(:,6) + roctable(:,7)); 
% 
% plot (FPR,recall, 'y','LineWidth', 2)
% 
% ylim([0.7 1])
% xlim([0 30])
% legend({'Look up Table (Dic size = 256)', 'Convolution', 'Look up table (Dic size = 1024)', 'Look up table (hierarchical - 16)' 'Look up table (hierarchical - 32)'})
% grid on 

% load('/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/results/VOC2008/test2/Full Model/HT067_1380767737/roc1.mat');
% 
% recall = ( roctable(:,6)./(roctable(:,6) + roctable(:,7))); 
% FPR = roctable(:,8) ./ (roctable(:,6) + roctable(:,7)); 
% h = figure; 
% plot (FPR,recall, 'LineWidth', 2)
% xlim ([0 20])
% xlabel ('false detection-to-labeled plate ratio: [FP/(TP+FN)]')
% ylabel ('hit rate [TP/(TP+FN)]')
% set(gca, 'FontSize', 16)
% 
% hold on 
% 
% load('/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/results/VOC2008/test2/comp_4_part_6_structure_5_3/HT067_1380767737/roc1.mat');
% 
% recall = ( roctable(:,6)./(roctable(:,6) + roctable(:,7))); 
% FPR = roctable(:,8) ./ (roctable(:,6) + roctable(:,7)); 
% 
% plot (FPR,recall, 'r','LineWidth', 2)
% xlim ([0 20])
% xlabel ('false detection-to-labeled plate ratio: [FP/(TP+FN)]')
% ylabel ('hit rate [TP/(TP+FN)]')
% set(gca, 'FontSize', 16)
% ylim([0.6 1])
% xlim([0 30])
% grid on 
% 
% legend({'Generic Model(Singapore, SF, Amsterdan)', 'Region Specific Model (Singapore, Taiwan)'})

% load('/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/results/VOC2008/test2/Full Model/summary/roc1.mat');
% 
% recall = ( roctable(:,6)./(roctable(:,6) + roctable(:,7))); 
% FPR = roctable(:,8) ./ (roctable(:,6) + roctable(:,7)); 
% h = figure; 
% plot (FPR,recall, 'LineWidth', 2)
% xlim ([0 20])
% xlabel ('false detection-to-labeled plate ratio: [FP/(TP+FN)]')
% ylabel ('hit rate [TP/(TP+FN)]')
% set(gca, 'FontSize', 16)
% 
% hold on 
% 
% load('/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/results/VOC2008/test4/comp_3_part_4_structure_5_3/roc_result_svm.mat');
% 
% % recall = ( roctable(:,6)./(roctable(:,6) + roctable(:,7))); 
% % FPR = roctable(:,8) ./ (roctable(:,6) + roctable(:,7)); 
% 
% plot (FPRfilter(:,2),hitfilter(:,2), 'r','LineWidth', 2)
% xlabel ('false detection-to-labeled plate ratio: [FP/(TP+FN)]')
% ylabel ('hit rate [TP/(TP+FN)]')
% 
% hold on
% 
% load('/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/results/VOC2008/comp_3_part_4_structure_5_3/summary/roc1_hier_16.mat');
% 
% recall = ( roctable(:,6)./(roctable(:,6) + roctable(:,7))); 
% FPR = roctable(:,8) ./ (roctable(:,6) + roctable(:,7)); 
% 
% plot (FPR,recall, 'k','LineWidth', 2)
% xlim ([0 20])
% xlabel ('false detection-to-labeled plate ratio: [FP/(TP+FN)]')
% ylabel ('hit rate [TP/(TP+FN)]')
% set(gca, 'FontSize', 16)
% ylim([0.5 1])
% xlim([0 20])
% grid on 
% 
% legend({'1 (Baseline)', '2 (Accurate)', '3 (Efficient)'})

