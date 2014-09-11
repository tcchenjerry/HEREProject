function model = TChere_pascal_train(cls, n, ex_para)

% model = pascal_train(cls)
% Train a model using the PASCAL dataset.

TChere_globals; 
if ~exist(tmpdir)
    mkdir(tmpdir); 
end
if ~exist(cachedir)
    mkdir(cachedir); 
end

maxsize = 2^28; % IVANA., orig 2^28
[pos, neg] = TChere_pascal_data(cls, n, ex_para);
spos = TChere_split(pos, n,ex_para);

% train root filters using warped positives & random negatives  (Phase 1)
fprintf('train root filters using warped positives & random negatives\n');
tic 
try
  load([cachedir cls '_random']);
catch
  for i=1:n
    models{i} = initmodel(spos{i}, ex_para.sbin);
    models{i} = TChere_train(ex_para, cls, models{i}, spos{i}, neg, 1, 1, 1, 1, maxsize);
  end
  save([cachedir cls '_random'], 'models');
end
toc

% merge models and train using latent detections & hard negatives  (Phase 2)
fprintf('merge models and train using latent detections & hard negatives\n');
tic 
try 
  load([cachedir cls '_hard']);
catch
  model = mergemodels(models);
  model = TChere_train(ex_para, cls, model, pos, neg(1:length(neg)/2), 0, 0, 2, 2, maxsize, true, 0.7);%model = train(cls, model, pos, neg(1:200), 0, 0, 2, 2, maxsize, true, 0.7);
  save([cachedir cls '_hard'], 'model');
end
toc

% add parts and update models using latent detections & hard negatives. (Phase 3)
fprintf('add parts and update models using latent detections & hard negatives.\n');
tic 
try 
  load([cachedir cls '_parts']);
catch
  for i=1:n
    % model = addparts(model, i, 6);
    model = addparts(model, i, ex_para.partN); 
  end 
  % use more data mining iterations in the beginning
  model = TChere_train(ex_para, cls, model, pos, neg, 0, 0, 1, 4, 4*maxsize, true, 0.7);
  model = TChere_train(ex_para, cls, model, pos, neg, 0, 0, 6, 2, 4*maxsize, true, 0.7, true);
  save([cachedir cls '_parts'], 'model');
end
toc

% update models using full set of negatives.
fprintf('update models using full set of negatives.\n');
tic
try 
  load([cachedir cls '_mine']);
catch
  model = TChere_train(ex_para, cls, model, pos, neg, 0, 0, 1, 3, 4*maxsize, true, 0.7, true, ...
                0.003*model.numcomponents, 2);
  save([cachedir cls '_mine'], 'model');
end
toc

% train bounding box prediction
fprintf('train bounding box prediction\n');
tic
try
  load([cachedir cls '_final']);
catch
  model = TChere_trainbox(cls, model, pos, 0.7,ex_para);
  save([cachedir cls '_final'], 'model');
end
toc