% Added visulization 

function spos = TChere_split(pos, n, ex_para)

vis = 1; 

% spos = split(pos, n)
% Split examples based on aspect ratio.
% Used for initializing mixture models.

h = [pos(:).y2]' - [pos(:).y1]' + 1;
w = [pos(:).x2]' - [pos(:).x1]' + 1;
aspects = h ./ w;
aspects = sort(aspects);

th = 1./1.3;
aspects_gTh = aspects(find(aspects>th));
aspects_lTh= aspects(find(aspects<th));

if (length(aspects_gTh)>0)
   m = n-1; 
else 
   m = n;
end
for i=1:m+1
  j = ceil((i-1)*length(aspects_lTh)/m)+1;
  if j > length(aspects_lTh)
    b(i) = inf;
  else
    b(i) = aspects(j);
  end
end

if (m < n)
    b(m+1) = aspects_gTh(1);
    b(m+2) = inf; 
end

aspects = h ./ w;
for i=1:n
  I = find((aspects >= b(i)) .* (aspects < b(i+1)));
  spos{i} = pos(I);
end

% ---------- Visulization of the split data ----------- % 
if (vis)
    TChere_globals; 
    TChere_vis(spos, aspects, n, ex_para); %     h = figure; 
    h = figure; 
    hist(aspects,0:0.02:max(aspects))
    hold on 
    for i = 1:n
       line([b(i), b(i)], ylim, 'Color', 'r')
       hold on 
    end
    xlabel 'width/height ratio'
    ylabel 'histogram'
    title 'histogram of data'
    saveas(h, [cachedir 'histtogram'], 'jpg');    
    pause; 
    close all
end

