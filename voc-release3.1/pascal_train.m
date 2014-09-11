function model = pascal_train(cls, n)

% model = pascal_train(cls)
% Train a model using the PASCAL dataset.

globals; 
maxsize = 2^28; % IVANA., orig 2^28
[pos, neg] = pascal_data(cls);
spos = split(pos, n);

% train root filters using warped positives & random negatives
fprintf('train root filters using warped positives & random negatives\n');
tic 
try
  load([cachedir cls '_random']);
catch
  for i=1:n
    models{i} = initmodel(spos{i});
    models{i} = train(cls, models{i}, spos{i}, neg, 1, 1, 1, 1, maxsize);
  end
  save([cachedir cls '_random'], 'models');
end
toc

% merge models and train using latent detections & hard negatives
fprintf('merge models and train using latent detections & hard negatives\n');
tic 
try 
  load([cachedir cls '_hard']);
catch
  model = mergemodels(models);
  model = train(cls, model, pos, neg(1:length(neg)/2), 0, 0, 2, 2, maxsize, true, 0.7);%model = train(cls, model, pos, neg(1:200), 0, 0, 2, 2, maxsize, true, 0.7);
  save([cachedir cls '_hard'], 'model');
end
toc

% add parts and update models using latent detections & hard negatives.
fprintf('add parts and update models using latent detections & hard negatives.\n');
tic 
try 
  load([cachedir cls '_parts']);
catch
  for i=1:n
    model = addparts(model, i, 6);
  end 
  % use more data mining iterations in the beginning
  model = train(cls, model, pos, neg, 0, 0, 1, 4, 4*maxsize, true, 0.7);
  model = train(cls, model, pos, neg, 0, 0, 6, 2, 4*maxsize, true, 0.7, true);
  save([cachedir cls '_parts'], 'model');
end
toc

% update models using full set of negatives.
fprintf('update models using full set of negatives.\n');
tic
try 
  load([cachedir cls '_mine']);
catch
  model = train(cls, model, pos, neg, 0, 0, 1, 3, 4*maxsize, true, 0.7, true, ...
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
  model = trainbox(cls, model, pos, 0.7);
  save([cachedir cls '_final'], 'model');
end
toc