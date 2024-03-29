function spos = split(pos, n)

% spos = split(pos, n)
% Split examples based on aspect ratio.
% Used for initializing mixture models.

h = [pos(:).y2]' - [pos(:).y1]' + 1;
w = [pos(:).x2]' - [pos(:).x1]' + 1;
aspects = h ./ w;
aspects = sort(aspects);

for i=1:n+2  
  j = ceil((i-1)*length(aspects)/(n+1))+1;
  if j > length(pos)
    b(i) = inf;
  else
    b(i) = aspects(j);
  end
end

aspects = h ./ w;
for i=1:n
  I = find((aspects >= b(i)) .* (aspects < b(i+2)));
  spos{i} = pos(I);
end
