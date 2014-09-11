clear all

addpath('../');

dstpath = '/mnt/blip/work-area-tchen/data/'; 

valdir = [dstpath 'val/']; 
traindir = [dstpath 'train/'];

expdir = '../../VOCdevkit/results/VOC2008/'; 
experiment = 'comp_3_part_4_structure_5_3'; 

prepare_train = 1;
prepare_test = 0;

if (prepare_train)

    val_size = 500; 
    
    load ([expdir 'train/' experiment '/label' '.mat']); 

    det_score = [detection.score];
    det_label = [detection.label];

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
    % (b) Choose detection with greater heights
    negh = zeros(1,length(neg));
    for i = 1:length(neg)
        % im = imread([detection(neg(i)).impath ]); 
        negh(i)= detection(neg(i)).y2 - detection(neg(i)).y1; 
    end
    [sorth I] = sort(negh,'descend');
    neg = neg(I(1:min(round(length(pos)*TP_FP_ratio), length(neg))));

    
    trainind = [pos(val_size+1:end) neg(val_size+1:end)]; 
    valind = [pos(1:val_size) neg(1:val_size)];

    % Generate scripts and save images for Training

    fidout = fopen([traindir 'train.txt'], 'w');

    for i = 1:length(trainind)

        tmp = detection(trainind(i)); 

        im = imread(['../' tmp.impath]); 
        im = im(tmp.y1:tmp.y2,tmp.x1:tmp.x2, :); 
        im = imresize(im, [80 80]); 

        imwrite(im,[traindir num2str(i) '.jpg'], 'jpeg'); 

        fprintf(fidout, [traindir num2str(i) '.jpg' ' ' num2str(detection(trainind(i)).label-1) '\n']); 

    end

    fclose(fidout); 
    
    fidout = fopen([valdir 'val.txt'], 'w');
    
    for i = 1:length(valind)
        tmp = detection(valind(i)); 

        im = imread(['../' tmp.impath]); 
        im = im(tmp.y1:tmp.y2,tmp.x1:tmp.x2, :); 
        im = imresize(im, [80 80]); 

        imwrite(im,[valdir num2str(i) '.jpg'], 'jpeg'); 

        fprintf(fidout, [valdir num2str(i) '.jpg' ' ' num2str(detection(valind(i)).label-1) '\n']); 
    end
    
end
    
% % Generate scripts and save images for Testing
% if (prepare_test)
% 
%     fidout = fopen([traindir 'test.txt'], 'w');
%     load ([expdir experiment '/label' '.mat']); 
% 
%     testing_score_th = -1.1; 
%     det_score = [detection.score]; 
%     testind = find(det_score >= testing_score_th); 
% 
%     for i = 1:length(testind)
% 
%         tmp = detection(testind(i)); 
% 
%         im = imread(['../' tmp.impath]); 
%         im = im(tmp.y1:tmp.y2,tmp.x1:tmp.x2, :); 
% 
%         im = imresize(im, [32 32]); 
% 
%         imwrite(im,[testdir num2str(i) '.jpg'], 'jpeg'); 
% 
%         fprintf(fidout, [testdir num2str(i) '.jpg' ' ' num2str(detection(testind(i)).label) '\n']); 
% 
%     end
% 
%     fclose(fidout); 
% 
% end
%     