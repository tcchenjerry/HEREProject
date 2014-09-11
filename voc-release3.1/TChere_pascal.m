% 6/26, added input parameters:
% cls : class name
% n: Number of components
% partN: Number of parts
% sinter: Number of intervals (pyramid)
% soctaves: Number of octaves (pyramid)
% expand: Ratio of expanding the bbox 
% sbin: HOG size


% function [ap] = TChere_pascal(cls, n, partN, sinter, soctaves)
function [ap] = TChere_pascal(cls, n, partN, sinter, soctaves, expand, sbin)

dbstop if error 

ex_para.n = n; 
ex_para.partN = partN;
ex_para.sinter = sinter; 
ex_para.soctaves = soctaves; 
ex_para.expand = expand; 
ex_para.sbin = sbin; 

TChere_globals;
pascal_init;

% 1. Training 
elapsedtime = []; 
tic 
try
   load([cachedir cls '_final']);
catch
   model = TChere_pascal_train(cls, n, ex_para);
end
elapsedtime(end+1) = toc

% 2. Testing
tic 
model.thresh  = min(-2, model.thresh);
[boxes1, boxes2] = TChere_pascal_test(cls, model, 'test', [VOCyear,'test'],ex_para);
elapsedtime(end+1) = toc

% 3. Evaluation (Get detection scores)
tic 
experiment = ['comp_' int2str(n) '_part_' int2str(partN) '_structure_' int2str(sinter) '_' int2str(soctaves) ]; 
expdir = [VOCopts.resdir experiment '/']; 
if (~exist(expdir, 'dir'))
    mkdir(expdir); 
end
TChere_pascal_eval(cls, boxes1, 'test', [expdir 'box1_' experiment], ex_para);
TChere_pascal_eval(cls, boxes2, 'test', [expdir 'box2_' experiment], ex_para);
elapsedtime(end+1) = toc

% 4. Calculate ROC curves (For each test case)
tic
testset = {'HT053_1381122097', 'HT067_1380767737'}; 
for i = 1:length(testset)  % Different tests
    LFNAME = ['../VOCdevkit/VOC2008/Annotations_txt/' testset{i} '.txt'];   % For the labels
    testdir = [expdir testset{i} '/']; 
    if (~exist(testdir,'dir')) 
        mkdir(testdir); 
    end
    for j = 1:2  % For different boxes (Based on root filter/prediction)
        DATAD = [expdir 'box' int2str(j) '_' experiment '.txt'];   % For the detection scores 
        eval (['! python ../prepare_data/TChere_privacy_evaluation_roc_v3.py ' LFNAME ' ' DATAD ...
            ' plates ' '--min ' num2str(-3) ' --max ' num2str(1) ' --scaling ' num2str(1/expand)]);         
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
