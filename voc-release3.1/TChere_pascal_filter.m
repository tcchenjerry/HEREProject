% 7/16 by tchen, added A.2 ~ A.4, B.2 
% Train SVM model on features (dimension:4096) calculated using CNN (Caffe)
% Rescoring by S_new = S_dpm + alpha*S_svm 
function [ap] = TChere_pascal_filter(cls, n, partN, sinter, soctaves, expand, sbin, filter)

dbstop if error 

ex_para.n = n; 
ex_para.partN = partN;
ex_para.sinter = sinter; 
ex_para.soctaves = soctaves; 
ex_para.expand = expand; 
ex_para.sbin = sbin; 
ex_para.filter = filter;

TChere_globals;
pascal_init;

% A.1. Training 
elapsedtime = []; 
tic 
model = TChere_pascal_train(cls, n, ex_para);
elapsedtime(end+1) = toc

% A.2 Testing (on the validation set)
model.thresh = min(-2, model.thresh);
% [boxes1, boxes2] = TChere_pascal_test(cls, model, 'test', [VOCyear,'test'],ex_para);
[boxes1, boxes2] = TChere_pascal_test(cls, model, 'val_filter', [VOCyear,'val'],ex_para); 

% A.3 Evaluation (on the validation set)
% TChere_pascal_eval(cls, boxes1, 'test', [expdir 'box1_' experiment], ex_para);
% TChere_pascal_eval(cls, boxes2, 'test', [expdir 'box2_' experiment], ex_para);
expdir = [VOCopts.resdir experiment '/']; 
TChere_pascal_eval(cls, boxes1, 'val_filter', [expdir 'val/box1_' experiment], ex_para);
TChere_pascal_eval(cls, boxes2, 'val_filter', [expdir 'val/box2_' experiment], ex_para);

% A.4 Train SVM-based filter (on the validation set)
% model = TChere_filterFP(ex_para, 1, -0.5);  
model = TChere_rescore_train(ex_para, -0.5); 

% B.1. Testing (on testing)
tic 
model.thresh = min(-2, model.thresh);
[boxes1, boxes2] = TChere_pascal_test(cls, model, 'test', [VOCyear,'test'],ex_para);
elapsedtime(end+1) = toc

% B.2 Rescoring with SVM model
svm_score = TChere_rescore_test(); 
% svm_score = (model_act.w(1,:) * feat_all(testset, :)' > 0) + ones(1,length(testset));

% B.3. Evaluation (on testing set)
tic 
experiment = ['comp_' int2str(n) '_part_' int2str(partN) '_structure_' int2str(sinter) '_' int2str(soctaves) ]; 
expdir = [VOCopts.resdir experiment '/']; 
if (~exist(expdir, 'dir'))
    mkdir(expdir); 
end
TChere_pascal_eval(cls, boxes1, 'test', [expdir 'box1_' experiment], ex_para);
TChere_pascal_eval(cls, boxes2, 'test', [expdir 'box2_' experiment], ex_para);
elapsedtime(end+1) = toc

% B.4. Calculate/Plot ROC curves (For each test case)
tic
% testset = {'HT068_1380264747', 'HT067_1381981716', 'HT053_1381122097', 'HT067_1380767737'}; 
testset = {'HT053_1381122097', 'HT067_1380767737'}; 
for i = 1:length(testset)
    LFNAME = ['../VOCdevkit/VOC2008/Annotations_txt/' testset{i} '.txt'];   % For the labels
    testdir = [expdir testset{i} '/']; 
    if (~exist(testdir,'dir')) 
        mkdir(testdir); 
    end
    for j = 1:2
        DATAD = [expdir 'box' int2str(j) '_' experiment '.txt'];   % For the detection scores 
        eval (['! python ../prepare_data/TChere_privacy_evaluation_roc.py ' LFNAME ' ' DATAD ' plates' ]); 
        % Plot ROC curves
        TChere_plotROC([testdir '/' 'box' int2str(j) '_plates_roc.txt'], testdir, j); 
    end
end
% Get summary of all test set
sumdir = [expdir '/' 'summary/'];
if (~exist(sumdir, 'dir'))
   mkdir (sumdir); 
end
for b = 1:2
    tablesum = zeros(17,8); 
    for i = 1:length(testset)
        testdir = [expdir testset{i} '/']; 
        load ([testdir 'roc' int2str(b) '.mat']); 
        tablesum = tablesum + roctable; 
    end
    save ([expdir  'summary/' 'box' int2str(b) '_sum' '.mat'], 'tablesum'); 
    TChere_plotROC([expdir 'summary/' 'box' int2str(b) '_sum' '.mat'], [expdir '/summary/'], b); 
end
elapsedtime(end+1) = toc

fid = fopen([expdir 'time.txt'],'w'); 
fprintf (fid, ' Units(sec)\n')
fprintf(fid,' training : %f \n testing : %f \n evaluation : %f \n plot : %f \n ', elapsedtime )
fclose (fid); 

