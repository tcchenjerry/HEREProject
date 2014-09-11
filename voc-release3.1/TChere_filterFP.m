% scripts for training SVM model
function model_act = TChere_filterFP(ex_para, val, score_th)

% (val = 1 : Train SVM model)
% (val = 0 : Test SVM model)
dbstop if error

addpath(genpath('../utils/'))  % For calling the CAFFE program
% experiment = ['comp_' int2str(ex_para.n) '_part_' int2str(ex_para.partN) '_structure_' int2str(ex_para.sinter) '_' int2str(ex_para.soctaves) '/']; 
experiment = ex_para; 

testset = {'HT053_1381122097', 'HT067_1380767737'}; 
trainset = {'HT068_1380264747', 'HT067_1381981716', 'HT053_1381122097', 'HT067_1381913307'}; 
expdir = '../VOCdevkit/results/VOC2008/'; 
imgdir = '../VOCdevkit/VOC2008/JPEGImages/';  

use_gpu = 1; 

% if use_gpu
%     matcaffe_init(1);
% else
%     matcaffe_init(); 
% end

cnnmodeltxt = '/home/zeyuli/tchen/caffe-master/examples/licenseplates/cifar10_quick.prototxt'; 
cnnmodel = '/home/zeyuli/tchen/caffe-master/examples/licenseplates/cifar10_quick_iter_4000'; 

if use_gpu
    matcaffe_init(1, cnnmodeltxt,cnnmodel);
else
    matcaffe_init(0, cnnmodeltxt,cnnmodel); 
end

training = 0; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Training %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
if (training)
% --------------- Load detections -------------- % 
try 
    load ([expdir 'train/' experiment '/label' '.mat']); 
catch
    detection = TChere_filter_loadDetections(trainset, experiment, expdir, imgdir); 
    save ([expdir 'train/' experiment '/label' '.mat'], 'detection'); 
end

det_score = [detection.score];
det_label = [detection.label];
% --------------- Collect positive/negative training samples ------------- %
pos = find((det_label == 1) .* (det_score > -0.6));  % TP

% Subsampling FP
TP_FP_ratio = 2; 
% (a) Choose detections with higher scores
sample_score = 0.3; % The highest score threshold
neg = find((det_label == 0).*(det_score> sample_score)); 
while (length(neg) < length(pos)*TP_FP_ratio*1.5)
    sample_score = sample_score - 0.1; 
    neg = find((det_label == 2).*(det_score > sample_score)); 
end
% (b) Choose detection with larger heights
negh = zeros(1,length(neg));
for i = 1:length(neg)
    % im = imread([detection(neg(i)).impath ]); 
    negh(i)= detection(neg(i)).y2 - detection(neg(i)).y1; 
end
[sorth I] = sort(negh,'descend');
neg = neg(I(1:min(round(length(pos)*TP_FP_ratio), length(neg))));

trainind = [pos neg]; 
trainlabel = det_label(trainind); 
% --------------- Feature Extraction -------------- % 

try 
    load([expdir 'train/' experiment '/feature_train' '.mat']); 
catch
    feat_all = TChere_filter_extractFeature(detection, trainind); 
    save ([expdir 'train/' experiment '/feature_train' '.mat'], 'feat_all'); 
end

% --------------- Train SVM model -------------- % 
try 
    load([expdir 'train/' experiment '/model_train.mat']); 
catch
    % Whitening
    [m_train p_train] = whiten_trans(feat_all, 0.005);
    save([expdir 'train/' experiment '/whitening' '.mat'], 'm_train', 'p_train'); 
    
    feat_all_tmp = feat_all - repmat(m_train, [size(feat_all, 1), 1]); 
    feat_all_tmp = feat_all_tmp * p_train;
    feat_all = feat_all_tmp; 
    
    model_act = train(trainlabel', sparse(feat_all),'-s 4 -c 1'); 
    save([expdir 'train/' experiment '/model_train.mat'], 'model_act', 'sample_score'); 
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Testing %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
testing_score_th = -1.1; 
% --------------- Load detections -------------- % 
try 
    load ([expdir experiment '/label' '.mat']); 
catch
    % detection = TChere_filter_loadDetections(testset, experiment, expdir, imgdir);
    detection = TChere_filter_loadDetections_test(experiment, expdir, imgdir); 
    save ([expdir experiment '/label' '.mat'], 'detection'); 
end
det_score = [detection.score]; 
% det_label = [detection.label]; 
testind = find(det_score >= testing_score_th); 
test_score = det_score(testind);
% --------------- Extract features -------------- % 

% try 
%     load([expdir experiment '/feature.mat']); 
% catch
%     feat_all = TChere_filter_extractFeature(detection, testind); 
%     save([expdir experiment '/feature.mat'], 'feat_all'); 
% end
% 
% % Whitening Feature
% 
% load([expdir 'train/' experiment '/whitening' '.mat'], 'm_train', 'p_train'); 
% 
% feat_all_tmp = feat_all - repmat(m_train, [size(feat_all, 1), 1]); 
% feat_all_tmp = feat_all_tmp * p_train;
% feat_all = feat_all_tmp; 

ratio = 1; 

if (ratio)
    % ---- Testing with Overall_score = alpha*svm_score + DPM_score -----% 
    % svm_ratio = 0:0.4:2;
    svm_ratio = 0:0.2:1; 
    rescore_min = zeros(1,length(svm_ratio));
    rescore_max = zeros(1,length(svm_ratio));
    % result = model_act.w(1,:) * feat_all';
    
%      try 
%          load([expdir experiment '/result.mat'], 'result'); 
%      catch
        load('data/ConvNet__2014-05-20_11.17.48_53.6216_fulldata.mat', 'model');
        boxes = [[detection(testind).x1] ; [detection(testind).y1] ; [detection(testind).x2] ; [detection(testind).y2]]'; 
        
        try 
            load([expdir experiment '/result_ian.mat']); 
        catch
            result = zeros (length(testind),4);
            for i = 1:length(testind)
            % for i = 1:100
                i
                im = imread(detection(testind(i)).impath); 
                result(i,:) = TChere_ian_rescore_det_cnn(im2double(im), boxes(i,:), model);
                % imsave{i} = im(boxes(i,2):boxes(i,4),boxes(i,1):boxes(i,3),1:3); 
                % result(i) = TChere_rescore_cnn(im, boxes(i,:));
            end
            save([expdir experiment '/result_ian.mat'], 'result'); 
        end
%         [temp ind] = sort(result(1:100), 'descend'); 
%         num_im = length(ind)
%         pix_height = 5*512;
%         pix_width = 8*512;             
%         ii = 1; 
%         while ii < num_im
%             rs =1; concatenated_image =[];
%             while rs < 0.9*pix_height && ii< num_im 
%                 one_row = [];
%                 cs = 1; 
%                 while cs < 0.9*pix_width  &&  ii< num_im    
%                     % concatenate next image in this line
%                     A = imsave{ind(ii)};
%                     [h,w,ch] = size(A);
%                     A(:,1:2,1) = 255; A(:,(end-2):end,1) = 255; A(1:2,:, 1) = 255; A((end-2):end,:,1) = 255;    
%                     one_row(1:h, cs:cs+w-1,:) = uint8(A);
%                     cs = size(one_row,2)+1; 
%                     ii = ii+1;
%                 end
%                 %figure, imshow(uint8(one_row));
%                 % add constructed row to the existing image
%                 [h,w,ch] = size(one_row);
%                 concatenated_image(rs:rs+h-1,1:w,:) = one_row;
%                 rs = size(concatenated_image,1) + 1;
%             end
% 
%         end
%         chip = figure; 
%         imshow(uint8(concatenated_image)); 
%         set(gca, 'Position', [0 0 1 1]);
        % title (['set ' int2str(k) ])
   
        % save([expdir experiment '/result.mat'], 'result'); 
%      end

    % TChere_rescore_rcnn(detection, testind);
    for k = 4:4
        for ss = 1:length(svm_ratio)

            filterdir = [expdir experiment '/filter/']
            if ~exist(filterdir)
                mkdir(filterdir)
            end
            fidout = fopen([filterdir 'box1_' experiment '.txt'], 'w'); 

            rescore = test_score*(1-svm_ratio(ss)) + svm_ratio(ss)*result(:,k)'; 
            rescore_min(ss) = min(rescore); 
            rescore_max(ss) = max(rescore);
            
            TChere_rescore_evaluate(rescore, detection, testind, fidout, expdir, experiment, svm_ratio(ss)); 
        end

    end
%     for ss = 1:length(svm_ratio)
%         
%         filterdir = [expdir experiment '/filter/']
%         if ~exist(filterdir)
%             mkdir(filterdir)
%         end
%         fidout = fopen([filterdir 'box1_' experiment '.txt'], 'w'); 
%         
%         rescore = test_score*(1-svm_ratio(ss)) + svm_ratio(ss)*result; 
%         rescore_min(ss) = min(rescore); 
%         rescore_max(ss) = max(rescore);
%         for i = 1:length(result)
%             tmp = detection(testind(i)); 
%             fprintf(fidout, '%s %s %f %d %d %d %d\n' , tmp.impath(end-26:end-11), ...
%                 tmp.impath(end-9:end-4), rescore(i), tmp.x1, tmp.y1, tmp.x2, tmp.y2);
%         end
%         fclose(fidout); 
%         testset = {'HT053_1381122097', 'HT067_1380767737'}; 
%         for i = 1:length(testset)  % Different tests
%             LFNAME = ['../VOCdevkit/VOC2008/Annotations_txt/' testset{i} '.txt'];   % For the labels
%             testdir = [expdir experiment '/filter/' testset{i} '/']; 
%             if (~exist(testdir,'dir')) 
%                 mkdir(testdir); 
%             end
%             DATAD = [expdir experiment '/filter/' 'box1_' experiment '.txt'];   % For the detection scores 
%             eval (['! python ../prepare_data/TChere_privacy_evaluation_roc_v3.py ' LFNAME ' ' DATAD ...
%                 ' plates ' '--min ' num2str(rescore_min(ss)) ' --max ' num2str(rescore_max(ss)) ' --scaling 0.5']); 
%             % eval (['! python ../prepare_data/TChere_privacy_evaluation_roc_v3.py ' LFNAME ' ' DATAD ...
%             %     ' plates ' '--min ' ' -5 ' ' --max ' ' 0.4 ']); 
%             
%             TChere_plotROC([testdir 'box1_plates_roc.txt'], testdir, 1); 
%         end
%         % Get summary of all test set
%         sumdir = [expdir experiment '/filter/summary/'];
%         if (~exist(sumdir, 'dir'))
%            mkdir (sumdir); 
%         end
%         tablesum = zeros(17,8); 
%         for i = 1:length(testset)
%             testdir = [expdir experiment '/filter/' testset{i} '/']; 
%             load ([testdir 'roc1.mat']); 
%             tablesum = tablesum + roctable; 
%         end
%         sumfname = [expdir experiment '/filter/summary/' 'box_sum_' num2str(svm_ratio(ss))  '.mat']; 
%         save (sumfname, 'tablesum');        
%         TChere_plotROC(sumfname, [expdir experiment '/filter/summary/'], 1);    
% 
%         close all    
%     end
else 
    % ---- Testing with different detection score threshold ---- %
    svm_th = (-4:2:4);
    % svm_th = 0; 

    for ss = 1:length(svm_th); 
        % subtestind = det_score(testind) >= score_th(s); 
        % label = [detection(testset).label]; 
        % result = (model_act.w(1,:) * feat_all(subtestind,:)' > svm_th(ss));
        result = (model_act.w(1,:) * feat_all' > svm_th(ss));
        % svm_score = model_act.w(2,:) * feat_all(subtestind,:)'; 

        % ---------  Re-evaluate TP bboxes --------- % 
        % subtestind = testind(subtestind); 
        % filterD_ind = subtestind(find(result == 1));   % Get filtered detections 
        filterD_ind = testind(result == 1); 
        % Print detections
        filterdir = [expdir experiment '/filter/']
        if ~exist(filterdir)
            mkdir(filterdir)
        end
        fidout = fopen([filterdir 'box1_' experiment '.txt'], 'w'); 
        for i = 1:length(filterD_ind)
            tmp = detection(filterD_ind(i)); 
            fprintf(fidout, '%s %s %f %d %d %d %d\n' , tmp.impath(end-26:end-11), tmp.impath(end-9:end-4), tmp.score, tmp.x1, tmp.y1, tmp.x2, tmp.y2);
        end
        fclose(fidout); 
        % Calculate ROC curve 
        testset = {'HT053_1381122097', 'HT067_1380767737'}; 
        for i = 1:length(testset)  % Different tests
            LFNAME = ['../VOCdevkit/VOC2008/Annotations_txt/' testset{i} '.txt'];   % For the labels
            testdir = [expdir experiment '/filter/' testset{i} '/']; 
            if (~exist(testdir,'dir')) 
                mkdir(testdir); 
            end
            DATAD = [expdir experiment '/filter/' 'box1_' experiment '.txt'];   % For the detection scores 
            eval (['! python ../prepare_data/TChere_privacy_evaluation_roc_v3.py ' LFNAME ' ' DATAD ' plates' ]); 
            TChere_plotROC([testdir 'box1_plates_roc.txt'], testdir, 1); 
        end
        % Get summary of all test set
        sumdir = [expdir experiment '/filter/summary/'];
        if (~exist(sumdir, 'dir'))
           mkdir (sumdir); 
        end
        tablesum = zeros(17,8); 
        for i = 1:length(testset)
            testdir = [expdir experiment '/filter/' testset{i} '/']; 
            load ([testdir 'roc1.mat']); 
            tablesum = tablesum + roctable; 
        end
        sumfname = [expdir experiment '/filter/summary/' 'box_sum_' num2str(svm_th(ss))  '.mat']; 
        save (sumfname, 'tablesum');        
        TChere_plotROC(sumfname, [expdir experiment '/filter/summary/'], 1);    

        close all
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Output Results %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
load ([expdir '/test2/comp_3_part_4_structure_5_3_context_2_resize/summary/roc1.mat']);   % Original Data

% ------------ Plot ROC --------------- % 

C = {'k','r','g','y',[.5 .6 .7],[.8 .2 .6], [.1 .3 .5], [.2 .4 .6], [.3 .5 .7], [.7 .5 .7], [.7 .8 .9]}; 

hit = roctable(:,6)./(roctable(:,6) + roctable(:,7)); 
FPR = roctable(:,8)./(roctable(:,6) + roctable(:,7)); 
h = figure; 
plot (FPR,hit, '-.','LineWidth', 2)
expname{1} = 'Without Rescoring'; 
xlim ([0 10])
ylim ([0 1])
xlabel ('false detection-to-labeled plate ratio: [FP/(TP+FN)]')
ylabel ('hit rate [TP/(TP+FN)]')
set(gca, 'FontSize', 16)
hold on 

if (ratio)
    for k = 1:length(svm_ratio)
        expname{k+1} = ['Rescore Ratio = ' num2str(svm_ratio(k)) ', min = ' num2str(rescore_min(k)) ...
            ', max = ' num2str(rescore_max(k))]; 
        load([expdir experiment '/filter/summary/' 'box_sum_' num2str(svm_ratio(k)) '.mat']); 
        hitfilter = tablesum(:,6)./(tablesum(:,6) + tablesum(:,7)); 
        FPRfilter = tablesum(:,8)./(tablesum(:,6) + tablesum(:,7)); 
        plot (FPRfilter,hitfilter, 'LineWidth', 2, 'color', C{k})
        hold on
        % pause
    end
    legend(expname, 'Location', 'SouthEast')        
else 
    for k = 1:length(svm_th)
        expname{k+1} = ['SVM Score Threshold = ' int2str(svm_th(k))]; 
        load([expdir experiment '/filter/summary/' 'box_sum_' num2str(svm_th(k)) '.mat']); 
        hitfilter = tablesum(:,6)./(tablesum(:,6) + tablesum(:,7)); 
        FPRfilter = tablesum(:,8)./(tablesum(:,6) + tablesum(:,7)); 
        plot (FPRfilter,hitfilter, 'LineWidth', 2, 'color', C{k})
        hold on
        % pause
    end
    legend(expname, 'Location', 'SouthEast')     
end
pause 
saveas(h, [expdir experiment '/filter_roc' ], 'jpg')
close all

% ---------- Print ------------ % 
% TChere_filter_printROC(); 

fidout = fopen([expdir experiment '/filter_roc.txt'], 'w'); 

fprintf(fidout, 'DATA: %s\n', [expdir experiment]); 
fprintf(fidout, '\n')

load ([expdir experiment '/summary/roc1.mat']);
roctable(:,1:5) = roctable(:,1:5)/length(testset); 
fprintf(fidout, 'Without Rescoring\n'); 
fprintf(fidout, 'threshold\t#recall\t\t#FPR\t\t#pixel FPR\tprecision\t#TP\t\t#FN\t\t#FP\n'); 
fprintf(fidout, '---------------------------------------------------------------------------------------------------\n'); 
for j = 1:size(tablesum, 1)
    fprintf(fidout, '%.2f\t\t%.2f\t\t%.2f\t\t%.2f\t\t%.2f\t\t%d\t\t%d\t\t%d\t\t\n', roctable(j,:))
end
fprintf(fidout, '\n');

if (ratio)
    for i = 1:length(svm_ratio)
        load ([expdir experiment '/filter/summary/' 'box_sum_' num2str(svm_ratio(i)) '.mat'])
        tablesum(:,1:5) = tablesum(:,1:5)/length(testset); 
        fprintf(fidout, '#SVM Score Ratio = %d\n', svm_ratio(i)); 
        % fprintf(fidout, '\t\t\t\tWithou Filtering\n'); 
        fprintf(fidout, 'threshold\t#recall\t\t#FPR\t\t#pixel FPR\tprecision\t#TP\t\t#FN\t\t#FP\n'); 
        fprintf(fidout, '---------------------------------------------------------------------------------------------------\n'); 
        for j = 2:size(tablesum, 1)
            fprintf(fidout, '%.2f\t\t%.2f\t\t%.2f\t\t%.2f\t\t%.2f\t\t%d\t\t%d\t\t%d\t\t\n', tablesum(j,:))
        end
        fprintf(fidout, '\n'); 
    end
else 
    for i = 1:length(svm_th)
        load ([expdir experiment '/filter/summary/' 'box_sum_' num2str(svm_th(i)) '.mat'])
        tablesum(:,1:5) = tablesum(:,1:5)/length(testset); 
        fprintf(fidout, '#SVM Threshold = %d\n', svm_th(i)); 
        % fprintf(fidout, '\t\t\t\tWithou Filtering\n'); 
        fprintf(fidout, 'threshold\t#recall\t\t#FPR\t\t#pixel FPR\tprecision\t#TP\t\t#FN\t\t#FP\n'); 
        fprintf(fidout, '---------------------------------------------------------------------------------------------------\n'); 
        for j = 2:size(tablesum, 1)
            fprintf(fidout, '%.2f\t\t%.2f\t\t%.2f\t\t%.2f\t\t%.2f\t\t%d\t\t%d\t\t%d\t\t\n', tablesum(j,:))
        end
        fprintf(fidout, '\n'); 
    end
end

fclose(fidout); 
