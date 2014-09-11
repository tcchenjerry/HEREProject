% Usage: 
% scripts for training SVM model
function TChere_filterFP_v2(experiment, scale)

% (val = 1 : Train SVM model)
% (val = 0 : Test SVM model)
dbstop if error

addpath(genpath('../utils/'))  % For calling the CAFFE program

testset = {'HT053_1381122097', 'HT067_1380767737'}; 
trainset = {'HT068_1380264747', 'HT067_1381981716', 'HT053_1381122097', 'HT067_1381913307'}; 
expdir = '../VOCdevkit/results/VOC2008/'; 
imgdir = '../VOCdevkit/VOC2008/JPEGImages/';  
filterdir = [expdir experiment '/filter/']; 
if ~exist(filterdir)
    mkdir(filterdir)
end

use_gpu = 1; 
cnnmodeltxt = '/home/zeyuli/tchen/caffe-master/examples/licenseplates/cifar10_quick.prototxt';
% cnnmodel = '/home/zeyuli/tchen/caffe-master/examples/licenseplates/models/cifar10_quick_iter_8000_TPFP';
cnnmodel = '/home/zeyuli/tchen/caffe-master/examples/licenseplates/cifar10_quick_iter_8000'; 

if use_gpu
    % matcaffe_init(1); 
    matcaffe_init(1, cnnmodeltxt,cnnmodel);
else
    % matcaffe_init(0); 
    matcaffe_init(0, cnnmodeltxt,cnnmodel); 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Rescoring %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
testing_score_th = -1.1; 

cnn_rescore_ian = 0; 
cnn_rescore_tchen = 0; 
svm_rescore = 0; 

wo_rescore_file = '/test2/comp_3_part_4_structure_5_3_context_2_resize/summary/roc1.mat'; 

% --------------- Load detections -------------- % 
try 
    load ([expdir experiment '/label' '.mat']); 
catch
    % detection = TChere_filter_loadDetections(testset, experiment, expdir, imgdir);
    detection = TChere_filter_loadDetections_test(experiment, expdir, imgdir); 
    save ([expdir experiment '/label' '.mat'], 'detection'); 
end
det_score = [detection.score]; 
testind = find(det_score >= testing_score_th); 
test_score = det_score(testind);

% ------------- Rescoring and evaluation ------------- % 
% svm_ratio = 0:0.2:1; 
svm_ratio = [0.3 0.6 0.9 0.93 0.96 1];
rescore_min = zeros(1,length(svm_ratio));
rescore_max = zeros(1,length(svm_ratio));

if (cnn_rescore_ian || cnn_rescore_tchen)
    % ---- Testing with Overall_score = alpha*cnn_score + (1-alpha)*DPM_score -----% 
    svm_ratio = [0.3 0.6 0.9 0.93 0.96 1];

    boxes = [[detection(testind).x1] ; [detection(testind).y1] ; [detection(testind).x2] ; [detection(testind).y2]]';  
    
    if (cnn_rescore_ian)
        load('data/ConvNet__2014-05-20_11.17.48_53.6216_fulldata.mat', 'model');
           
        %regRatio = (0.1:0.1:0.4);         
        regRatio = 0.8; 
        try 
            load([expdir experiment '/result_ian.mat']); 
        catch
            result = zeros (length(testind),length(regRatio));
            for i = 1:length(testind)
                i
                im = imread(detection(testind(i)).impath); 
                tic
                result(i,:) = TChere_ian_rescore_det_cnn(im2double(im), boxes(i,:), model, 0.5, regRatio);
                toc
            end
            save([expdir experiment '/result_ian.mat'], 'result'); 
        end
        
        for k = 1:length(regRatio)
            for ss = 1:length(svm_ratio)
                fidout = fopen([filterdir 'box1_' experiment '.txt'], 'w'); 
                
                rescore = test_score*(1-svm_ratio(ss)) + svm_ratio(ss)*result(:,k)'; 
                rescore_min(ss) = min(rescore); 
                rescore_max(ss) = max(rescore);

                TChere_rescore_evaluate(rescore, detection, testind, fidout, expdir, experiment, svm_ratio(ss)); 
            end
        end
        
        [hitfilter FPRfilter expname] = TChere_filterFP_plotROC(wo_rescore_file, rescore_max, rescore_min, svm_ratio, expdir, experiment, 'roc_result_ian');  
        % TChere_filterFP_printROC(testset, svm_ratio, expdir, experiment)
        save([expdir experiment '/roc_result_ian.mat'], 'hitfilter', 'FPRfilter', 'expname'); 
    end
    if (cnn_rescore_tchen)
        
        try 
            load([expdir experiment '/result_tchen_' num2str(scale) '.mat']); 
        catch
            result = zeros (1,length(testind));
            for i = 1:length(testind)
                im = imread(detection(testind(i)).impath); 
                tic 
                result(i) = TChere_rescore_cnn(im, boxes(i,:), scale);
                toc
            end
            
            save([expdir experiment '/result_tchen_' num2str(scale) '.mat'], 'result'); 
        end        
        
        for ss = 1:length(svm_ratio)
            
            fidout = fopen([filterdir 'box1_' experiment '.txt'], 'w'); 
            
            rescore = test_score*(1-svm_ratio(ss)) + svm_ratio(ss)*result;  % Different from Ian's model
            rescore_min(ss) = min(rescore); 
            rescore_max(ss) = max(rescore);
            
            TChere_rescore_evaluate(rescore, detection, testind, fidout, expdir, experiment, svm_ratio(ss)); 
            
        end        
        
        [hitfilter FPRfilter expname] = TChere_filterFP_plotROC(wo_rescore_file, rescore_max, rescore_min, svm_ratio, expdir, experiment, 'roc_result_tchen');  
        % TChere_filterFP_printROC(testset, svm_ratio, expdir, experiment)
        save([expdir experiment '/roc_result_tchen.mat'], 'hitfilter', 'FPRfilter', 'expname'); 
    end
end    
if (svm_rescore)
    svm_ratio = (0:0.2:1); 
    % --------------- Train SVM model --------------- % 
    model_act = TChere_filterFP_trainsvm(trainset, expdir, imgdir, experiment); 
    
    % --------------- Extract features -------------- % 
    try 
        load([expdir experiment '/feature.mat']); 
    catch
        feat_all = TChere_filter_extractFeature(detection, testind); 
        save([expdir experiment '/feature.mat'], 'feat_all'); 
    end
    % Whitening Features (Note: Need to re-calculate m_train and p_train if training SVM on new data)
    load([expdir 'train/' experiment '/whitening' '.mat'], 'm_train', 'p_train'); 
    feat_all_tmp = feat_all - repmat(m_train, [size(feat_all, 1), 1]); 
    feat_all_tmp = feat_all_tmp * p_train;
    feat_all = feat_all_tmp;     

    % ---- Testing with Overall_score = alpha*svm_score + (1-alpha)*DPM_score -----% 
    result = model_act.w(1,:) * feat_all';

    for ss = 1:length(svm_ratio)

        fidout = fopen([filterdir 'box1_' experiment '.txt'], 'w');         
        
        rescore = test_score*(1-svm_ratio(ss)) + svm_ratio(ss)*result; 
        rescore_min(ss) = min(rescore); 
        rescore_max(ss) = max(rescore);
        
        TChere_rescore_evaluate(rescore, detection, testind, fidout, expdir, experiment, svm_ratio(ss)); 

    end
    
    [hitfilter FPRfilter expname] = TChere_filterFP_plotROC(wo_rescore_file, rescore_max, rescore_min, svm_ratio, expdir, experiment, 'roc_result_svm');  
    % TChere_filterFP_printROC(testset, svm_ratio, expdir, experiment); 
    
    save([expdir experiment '/roc_result_svm.mat'], 'hitfilter', 'FPRfilter', 'expname'); 
    
end

summary = 1; 

if (summary)
   sumdir = [expdir experiment '/']; 
   sumfiles = {'roc_result_ian.mat', 'roc_result_tchen.mat', 'roc_result_svm.mat'};
   compareset = [2, 2, 2]; 
   comparename = {'ian', 'tchen', 'svm'}; 
   load ([expdir wo_rescore_file]);   % Original Data
   hit = roctable(:,6)./(roctable(:,6) + roctable(:,7)); 
   FPR = roctable(:,8)./(roctable(:,6) + roctable(:,7)); 
   h = figure; 
   plot (FPR,hit, '-.','LineWidth', 2)
   xlim ([0 5])
   ylim ([0.5 1])
   xlabel ('false detection-to-labeled plate ratio: [FP/(TP+FN)]', 'FontSize', 14)
   ylabel ('hit rate [TP/(TP+FN)]', 'FontSize', 14)   
   grid on
   hold on
   sumname{1} = 'Without Rescoring'; 
   
   C = {'k','r','g','y',[.5 .6 .7],[.8 .2 .6], [.1 .3 .5], [.2 .4 .6], [.3 .5 .7], [.7 .5 .7], [.7 .8 .9]}; 
   for k = 1:length(compareset)
       load([sumdir sumfiles{k}])
       plot (FPRfilter(:,compareset(k)),hitfilter(:,compareset(k)), 'LineWidth', 2, 'color', C{k})
       % sumname{1+k} = [comparename{k} ', ' expname{compareset(k)+1}]; 
       sumname{k+1} = [comparename{k} ', ' expname{compareset(k)}];
       hold on
   end
   legend(sumname, 'Location', 'SouthEast')
   pause 
   saveas(h, [expdir experiment '/summary_roc' ], 'jpg')   
   
end
