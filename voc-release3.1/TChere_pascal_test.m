function [boxes1, boxes2] = TChere_pascal_test(cls, model, testset, suffix,ex_para)

% [boxes1, boxes2] = pascal_test(cls, model, testset, suffix)
% Compute bounding boxes in a test set.
% boxes1 are bounding boxes from root placements
% boxes2 are bounding boxes using predictor function

TChere_globals;
pascal_init;
addpath(genpath('../utils/')) 
ids = textread(sprintf(VOCopts.imgsetpath, testset), '%s');

conv = 0;

kmean = 1; 
centername = 'kmeans_center_256';

hier_kmean = 0; 
% centername = 'hierarchical_center_16';
% centername = 'hierarchical_center_32'; 

if kmean
    model = TChere_model_add_lut(model, centername);
    load(centername)        

    build_params.target_precision = 1;
    build_params.checks = 4; 
    build_params.trees = 4; 
    build_params.branching = 16;
    build_params.algorithm = 'autotuned'; 
    [index, parameters] = flann_build_index(single(center), build_params);     

    model.index = index; 
    model.parameters = parameters;         
    model.center = center; 
    model.method = 'kmean';     
elseif hier_kmean
    model = TChere_model_add_lut(model, centername);
    load(centername)        

    model.center = center;
    model.root_center = root_center; 
    model.leaf_center = leaf_center;
    model.method = 'hier_kmean'; 
end

% run detector in each image  (comment try and catch if need to calculate new results)
% try
%   load([cachedir cls '_boxes_' testset '_' suffix]);
% catch
  
  for i = 1:length(ids);

    fprintf('%s: testing: %s %s, %s, %d/%d\n', cls, testset, VOCyear, ...
            ids{i},i, length(ids));
    im = imread(sprintf(VOCopts.imgpath, ids{i}));  
    
    if (conv)
        boxes = detect(im, model, model.thresh);
    else
        boxes = TChere_detect(im, model, model.thresh); 
    end
    
    if ~isempty(boxes)
      b1 = boxes(:,[1 2 3 4 end]);
      b1 = clipboxes(im, b1);
      boxes1{i} = nms(b1, 0.5);
      if length(model.partfilters) > 0
        b2 = getboxes(model, boxes);
        b2 = clipboxes(im, b2);
        boxes2{i} = nms(b2, 0.5);
      else
        boxes2{i} = boxes1{i};
      end
    else
      boxes1{i} = [];
      boxes2{i} = [];
    end
    showboxes(im, boxes1{i}, -0.8);

  end    
  flann_free_index(index);
  save([cachedir cls '_boxes_' testset '_' suffix], 'boxes1', 'boxes2');
% end
