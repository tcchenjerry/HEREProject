function spos = pos_stats()

figure(1), hold on,

%%
load_dir ='/home/ivanas/here/drives/singapore/HT067_1380767737/result_dpm_4comp/'
fs = dir([load_dir]);
th = -0.6; 
x1D=[]; x2D = []; y1D=[]; y2D =[]; 
for ii = 3:length(fs)
    fname  = [load_dir,'/',fs(ii).name, '/detected_plates.txt'];
    if exist(fname,'file')
        [x1, x2, y1, y2, score]=textread(fname,'%d %d %d %d %f');
        idx = find(score>th);
        x1D  = [x1D; x1(idx)];
        x2D  = [x2D; x2(idx)];
        y1D  = [y1D; y1(idx)];
        y2D  = [y2D; y2(idx)];
        
    end
end

load_dir ='/home/ivanas/here/drives/amsterdam/HT024_1377677817_2/result_dpm_4comp/'
fs = dir([load_dir]);
for ii = 3:length(fs)
    fname  = [load_dir,'/',fs(ii).name, '/detected_plates.txt'];
    if exist(fname,'file')
        [x1, x2, y1, y2, score]=textread(fname,'%d %d %d %d %f');
        idx = find(score>th);
        x1D  = [x1D; x1(idx)];
        x2D  = [x2D; x2(idx)];
        y1D  = [y1D; y1(idx)];
        y2D  = [y2D; y2(idx)];
        
    end
end

load_dir ='/home/ivanas/here/drives/us/HT052set3/result_dpm_4comp/'
fs = dir([load_dir]);
for ii = 3:length(fs)
    fname  = [load_dir,'/',fs(ii).name, '/detected_plates.txt'];
    if exist(fname,'file')
        [x1, x2, y1, y2, score]=textread(fname,'%d %d %d %d %f');
        idx = find(score>th);
        x1D  = [x1D; x1(idx)];
        x2D  = [x2D; x2(idx)];
        y1D  = [y1D; y1(idx)];
        y2D  = [y2D; y2(idx)];
        
    end
end


hD = y2D - y1D + 1;
wD = x2D - x1D + 1;
aD = wD.*hD;

plot( y1D, hD, 'go'); 

% %% spos = split(pos, n)
% % Split examples based on aspect ratio.
% % Used for initializing mixture models.
% 
globals; y1 = []; h =[];
[pos, neg] = pascal_data('plate');
h = [pos(:).y2]' - [pos(:).y1]' + 1;
w = [pos(:).x2]' - [pos(:).x1]' + 1;

y1 = [pos(:).y1]'+1980 ;
x1 = [pos(:).x1]';
a  = w.*h;

plot(y1, h, 'rx'); 


h= 16:111; 
plot(4.33*(h-111)+2481,h,'b')
h= 16:55; 
plot(13.2*(h-55)+3094,h,'b')

h = 111:256;
plot(2481*ones(size(h)), h, 'b')

h = 55:256;
plot(3094*ones(size(h)), h,'b')


for h = 1:256
   if h>111
        ymin(h) = 2481; 
        ymax(h) = 3000;
   else if h>55
        ymin(h) = floor(4.33*(h-111)+2481); 
        ymax(h) = 3000;
       else 
          ymin(h) = floor(4.33*(h-111)+2481); 
          ymax(h) = ceil(13.2*(h-55)+3000);
       end
   end
end
    
hold on, plot(ymin, 1:256,'r')
hold on, plot(ymax, 1:256,'r')

 
fp = fopen('hy_prior.dat', 'wb');
fprintf(fp, 'num_h = %d\n', 256);
yrange = [ymin(:); ymax(:)];
fwrite(fp, yrange, 'int');
fclose(fp);


%%
if 0
    j = 1;
    data_xm =[]; data_xM =[]; data_y =[];
    data_xS =[];
    for i = 16:256
        idx = find(h < i+3 & h>i-3);
        if ~isempty(idx)
            data_xm(j) = min(y1(idx));
            data_xx(j) = max(y1(idx));
            data_xS(j) = std(y1(idx));
            data_xM(j) = mean(y1(idx));
            data_y(j) = i;
            j = j+1;
        end
    end
    
    plot(data_xM-3*data_xS, data_y, 'bo')
    plot(data_xM+3*data_xS, data_y, 'bo')
    
    y = data_y(:);
    x = data_xm(:);
    
    
    A  = [ones(size(x)), x  x.^2];
    beta = A\x;
    
    xfit = (2000:3200)';
    yfit = [ones(size(xfit)), xfit xfit.^2]*beta;
    plot(xfit, yfit, 'b-')
    plot(x, y, 'bo')
    
end


