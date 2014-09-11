function model = TChere_model_add_lut(model, centername)
    
disp('Filling look up table...');
% load kmeans_center_256.mat
% load hierarchical_center_32
load(centername)
for i=1:length(model.partfilters)
    model.partfilters{i}.wlut=TChere_filter2lut(model.partfilters{i}.w,center);
end

model.rootlut=cell(model.numcomponents,1);
for i=1:length(model.rootfilters)
    model.rootlut{i}=TChere_filter2lut(model.rootfilters{i}.w,center);
end
disp('Done.');

end