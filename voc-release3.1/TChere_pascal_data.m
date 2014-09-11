function [pos, neg] = TChere_pascal_data(cls, n, ex_para)

% [pos, neg] = pascal_data(cls)
% Get training data from the PASCAL dataset.

TChere_globals; 
pascal_init;

% try
%      load([cachedir cls '_train']);
% catch
  % positive examples from train+val
  % if (ex_para.filter)
  %     ids = textread(sprintf(VOCopts.imgsetpath, 'train_filter'), '%s'); 
  % else     
       ids = textread(sprintf(VOCopts.imgsetpath, 'trainval'), '%s');
  % end
  pos = [];
  numpos = 0;
  for i = 1:length(ids);
    fprintf('%s: parsing positives: %d/%d\n', cls, i, length(ids));
    rec = PASreadrecord(sprintf(VOCopts.annopath, ids{i}));
    clsinds = strmatch(cls, {rec.objects(:).class}, 'exact');
    % skip difficult examples
    diff = [rec.objects(clsinds).difficult];
    clsinds(diff) = [];
    for j = clsinds(:)'
      numpos = numpos+1;
      pos(numpos).im = [VOCopts.datadir rec.imgname];
      bbox = rec.objects(j).bbox;
      pos(numpos).x1 = bbox(1);
      pos(numpos).y1 = bbox(2);
      pos(numpos).x2 = bbox(3);
      pos(numpos).y2 = bbox(4); 
      if (ex_para.expand == 1)
          pos(numpos).x1 = bbox(1);
          pos(numpos).y1 = bbox(2);
          pos(numpos).x2 = bbox(3);
          pos(numpos).y2 = bbox(4);
      else 
          xc = (bbox(1) + bbox(3))/2; 
          yc = (bbox(2) + bbox(4))/2; 
          xwid = xc - bbox(1);
          ywid = yc - bbox(2); 
          pos(numpos).x1 = round(max(xc - ex_para.expand*xwid,1)); 
          pos(numpos).y1 = round(max(yc - ex_para.expand*ywid,1));
          pos(numpos).x2 = round(min(xc + ex_para.expand*xwid,8192));
          pos(numpos).y2 = round(min(yc + ex_para.expand*ywid,1320));       
      end
    end
  end
     
  % negative examples from train (this seems enough!)
  % ids = textread(sprintf(VOCopts.imgsetpath, 'trainval'), '%s');
  
  neg = [];
  numneg = 0;
  for i = 1:length(ids);
    fprintf('%s: parsing negatives: %d/%d\n', cls, i, length(ids));
    rec = PASreadrecord(sprintf(VOCopts.annopath, ids{i}));
    clsinds = strmatch(cls, {rec.objects(:).class}, 'exact');
    if length(clsinds) == 0 
      numneg = numneg+1;
      neg(numneg).im = [VOCopts.datadir rec.imgname];
    end
  end
  
  save([cachedir cls '_train'], 'pos', 'neg');
% end   
% end  
