% Added visulization 

function spos = split(pos, n)

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
    % Plot all the 
    for k = 1:length(spos)

        col_n = 15; 
        row_n = ceil(length(spos{k}) / col_n); 
        im_all = uint8(255*ones(100*row_n, 100*col_n, 3));   

        for i = 1:length(spos{k}) 
            i 
            im = imread(spos{k}(i).im);

            im = im(spos{k}(i).y1:spos{k}(i).y2, spos{k}(i).x1:spos{k}(i).x2-1,:); 
            im = imresize(im, [100 100]); 
            r_i = ceil(i/col_n); 
            c_i = i - (r_i - 1)*col_n;

            im_all((r_i-1)*100+1:r_i*100, (c_i-1)*100+1:c_i*100,:) = im;

        end

        figure
        im = imshow(im_all); 
        set(gca, 'Position', [0 0 1 1]);
        % pause; 

    end

    % Check the histogram, by tchen
    h = figure; 
    hist(aspects,0:0.02:max(aspects))
    hold on 
    for i = 1:n
       line([b(i), b(i)], ylim)
       hold on 
    end
    xlabel 'width/height ratio'
    ylabel 'histogram'
    title 'histogram of '
    saveas(h,,'jpg')
    
end