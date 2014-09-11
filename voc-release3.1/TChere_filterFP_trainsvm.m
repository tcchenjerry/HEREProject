function model_act = TChere_filterFP_trainsvm(trainset, expdir, imgdir, experiment)
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