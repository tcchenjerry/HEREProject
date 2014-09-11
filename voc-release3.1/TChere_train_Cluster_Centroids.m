function TChere_train_Cluster_Centroids()
    
    dbstop if error
    
    addpath(genpath('../utils/'))     
    
    cal_kmean_center = 0; 
    % K = 256; 
    % K = 1024;
    K = 16; 
    if cal_kmean_center

        opts = struct('maxiters', 1000, 'mindelta', eps, 'verbose', 1);    

        interval = 5;
        sc = 2 ^(1/interval);
        sbin = 8;         

        % Load Detections on validation data
        expdir = '../VOCdevkit/results/VOC2008/'; 
        experiment = 'comp_3_part_4_structure_5_3';     
        load ([expdir 'train/' experiment '/label' '.mat']); 

        jj = 1;
        feat_all = []; 
        for i = 1:20:length(detection)
            % Calculate the features
            tmp = detection(i); 
            im = imread(tmp.impath); 
            im = im(tmp.y1:tmp.y2,tmp.x1:tmp.x2, :); 

            % for k = 1:interval
                k = randi(interval, 1); 
                scaled = resize(double(im), 1/sc^(k-1));
                m = randi(2,1); 
                % for m = 1:2
                    feat = features(scaled, sbin/m);
                    feat = reshape(feat, size(feat,1) * size(feat,2), size(feat,3)); 
                    feat_all = [feat_all, feat(1:5:end,:)']; 
                % end
            % end
        end

        [center, sse] = vgg_kmeans(feat_all, K, opts);
        save(['kmeans_center_' int2str(K) '.mat'],'center');    
    end
    
    cal_hierarchical_kmean = 1; 
    
    K = 32; 
    if cal_hierarchical_kmean
        opts = struct('maxiters', 1000, 'mindelta', eps, 'verbose', 1);    

        interval = 5;
        sc = 2 ^(1/interval);
        sbin = 8;         
        % Load Detections on validation data
        expdir = '../VOCdevkit/results/VOC2008/'; 
        experiment = 'comp_3_part_4_structure_5_3';     
        load ([expdir 'train/' experiment '/label' '.mat']); 
        
        jj = 1;
        feat_all = []; 
        for i = 1:20:length(detection)
            % Calculate the features
            tmp = detection(i); 
            im = imread(tmp.impath); 
            im = im(tmp.y1:tmp.y2,tmp.x1:tmp.x2, :); 

            % for k = 1:interval
                k = randi(interval, 1); 
                scaled = resize(double(im), 1/sc^(k-1));
                m = randi(2,1); 
                % for m = 1:2
                    feat = features(scaled, sbin/m);
                    feat = reshape(feat, size(feat,1) * size(feat,2), size(feat,3)); 
                    feat_all = [feat_all, feat(1:5:end,:)']; 
                % end
            % end
        end
        
        [root_center, sse] = vgg_kmeans(feat_all, K, opts);
        
        [kmean_idx d] = vgg_nearest_neighbour(feat_all, root_center);
        
        center = [];
        for i = 1:K
            
            [leaf_center{i} sse] = vgg_kmeans(feat_all(:,kmean_idx == i), K,opts);
            center = [center leaf_center{i}]; 
        end
        
        save(['hierarchical_center_' int2str(K) '.mat'],'root_center', 'leaf_center', 'center');
        
    end
    
    
end