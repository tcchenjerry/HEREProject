% The printed file format [driveid captureid score x0 y0 x1 y1]
function ap = TChere_pascal_eval(cls, boxes, testset, suffix,ex_para)

% ap = pascal_eval(cls, boxes, testset, suffix)
% Score bounding boxes using the PASCAL development kit.

TChere_globals;
pascal_init;
ids = textread(sprintf(VOCopts.imgsetpath, testset), '%s');

% write out detections in PASCAL format and score
% fid = fopen(sprintf(VOCopts.detrespath, suffix, cls), 'w');
% fid = fopen([VOCopts.resdir 'Main/' suffix '.txt'],'w'); 
fid = fopen([suffix '.txt'],'w'); 
for i = 1:length(ids);
  bbox = boxes{i};
  for j = 1:size(bbox,1)
      fprintf(fid, '%s %s %f %d %d %d %d\n', ids{i}(1:16) , ids{i}(18:end), bbox(j,end), round(bbox(j,1:4))); 
  end
end
fclose(fid);

end