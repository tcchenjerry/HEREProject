function match = flut(feat, filters, center, index, parameters)
   
   
   % 'Pass reference'
   tic 
   % Map all features to Cluster ID
   [fs1 fs2 fs3] = size(feat); 
   
   % 'reshape'

   feat = reshape(feat, fs1 * fs2, fs3); 
   
   % [kmean_idx d] = vgg_nearest_neighbour((reshape(feat, fs1 * fs2, fs3))', center);
   
   % 0. Flann
   
%    build_params.target_precision = 0.99;
%    build_params.build_weight = 0.01;
%    build_params.memory_weight = 0;
   
   % [index, parameters] = flann_build_index(center, build_params);
   % tic
   % 'kmean'

   kmean_idx = int32(flann_search(index,single(feat'),1,parameters))';

   % toc 
   % flann_free_index(index);
   
   % 1. Vgg
%    tic
%    [kmean_idx d] = vgg_nearest_neighbour(feat', center);
%    toc
   
   % 2. 
%    tree = kdtree_build(center');
%    
%    idxs = zeros(179228,1); 
%    tic
%    for i = 1:179228
%        idxs(i) = kdtree_k_nearest_neighbors(tree, feat(i,:),1);
%    end 
%    toc
   
   % ns = createns(center', 'nsmethod', 'kdtree'); 
%    ns = createns(center','dist', 'euclidean','nsmethod', 'kdtree','bucketSize',50);   
%    tic 
%         [idx, dist]= knnsearchmex(X2, Y',numNN2,minExp, obj.cutDim, obj.cutVal, ...
%             obj.lowerBounds', obj.upperBounds',obj.leftChild, obj.rightChild, ...
%             obj.leafNode, obj.idx,obj.nx_nonan,wasNaNY, includeTies,[]);   
%    toc 
   
%    tic 
%    % [idx, dist] = knnsearch(ns, feat, 'k', 1);
%    idx = knnsearch(ns, feat, 'k',1); 
%    toc 
%    
%    tic
%    [idx, dist] = knnsearch(center',feat,'dist','cityblock','k',1); 
%    toc
%    

   % toc

   
   kmean_idx = reshape(kmean_idx, [fs1 fs2]);    
   % Convolution
   % 'Look up table'
   % 'Lut'

   match = lut(kmean_idx, filters, 1, length(filters)); 

   % 1
  
%    for i = 1:length(filters)
%        score = zeros(size(kmean_idx, 1) - size(filters{i},1) + 1, ...
%            size(kmean_idx, 2) - size(filters{i}, 2) + 1);
%        filterx = size(filters{i},1);
%        filtery = size(filters{i},2);
%        temp = filters{i}; 
%        for m = 1:size(score,1)
%            for n = 1:size(score,2)
%                for a = 1:filterx
%                    for b = 1:filtery
%                        score(m,n) = temp(a,b,kmean_idx(a+m-1,b+n-1)) + score(m,n); 
%                    end
%                end
%                % score(m, n) = sum(filters{i}(m:m+filterx-1, n:n+filtery-1, kmean_idx(m:m+filterx-1, n:n+filtery-1)) ); 
%            end
%        end
%        match{i} = score; 
%    end
    % 'Inner'
    % toc
end