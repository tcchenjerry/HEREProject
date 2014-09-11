function spos = pos_stats()



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

figure(1), hold on,plot( y1D, hD, 'go'); 
figure(2), hold on,plot( aD, hD, 'go'); 

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

figure(1), plot(y1, h, 'rx'); 
figure(1), hold on; plot(y1D, hD, 'gx'); 
figure(2), plot(y1, a, 'rx'); 
figure(2), hold on;  plot(y1D, aD, 'gx');
figure(3), plot(a, h, 'rx'); 
figure(3), hold on;  plot(aD, hD, 'gx');
figure(4), hold on; plot(y1D, wD, 'gx'); 
figure(4), plot(y1, w, 'rx'); 

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

wDD =[], y1DD =[];
for ii = 1:length(y1D)
    if y1D(ii)> ymin(hD(ii)) & y1D(ii)<ymax(hD(ii))
        wDD = [wDD, wD(ii)];
        y1DD = [y1DD, y1D(ii)];
    end
end

figure(5), hold on; plot(y1DD, wDD, 'gx'); 
figure(5), plot(y1, w, 'rx');

s1 = 4.9;
s2 = 2.1

hold on; 
lw = 16:130; 
uw = 130:410;
plot(4.9*(lw-130)+2390, lw,'b') 
plot(2.1*(uw-130)+2390, uw,'b') 

cnt = cnt +1;
for ii = 1: length(y1DD)
    if w1DD(ii)<130 & y1DD(ii)>4.9*(lw-130)+2390
        cnt = cnt+1; 
    else
        if w1DD(ii)>130 & y1DD(ii)>2.1*(lw-130)+2390
            cnt    = cnt+1;
        end
    end
end








