function TChere_vis_detections()


testset = 'HT053_1381122097'; 
% expname = ['comp_3_part_4_structure_5_3/' testset '/']; 
expname = ['test2/comp_3_part_4_structure_5_3/' testset '/']; 
% expname = ['train/' testset '/']; 
expdir = '../VOCdevkit/results/VOC2008/'; 
imgdir = '../VOCdevkit/VOC2008/JPEGImages/';  

% Generate TP/FP Detections
if ~exist(['../VOCdevkit/results/VOC2008/comp_3_part_5_structure_5_3/' testset '/box1_plates_TP.txt']) 
   LFNAME = ['../VOCdevkit/VOC2008/Annotations_txt/' testset '.txt'];
   DATAD = [expdir 'train/' 'box1_comp_3_part_4_structure_5_3.txt'];
   eval (['! python ../prepare_data/TChere_privacy_evaluation_roc_v2.py ' LFNAME ' ' DATAD ' plates' ]); 
end
% Load detections
try 
    load ([expdir expname 'label' '.mat']); 
catch
    index = 1; 
    class = {'TP', 'FP'};
    for i = 1:2
        fid = fopen([expdir expname 'box1_plates_' class{i} '.txt'], 'r');
        tline = fgetl(fid);
        tempC = strsplit(tline);    
        while ischar(tline)
            detection(index).impath = [imgdir testset '_' tempC{1} '.jpg']; 
            detection(index).label = i; 
            % detection(index).score = str2double(tempC{3}); 
            detection(index).x1 = str2double(tempC{2});
            detection(index).y1 = str2double(tempC{3});
            detection(index).x2 = str2double(tempC{4});
            detection(index).y2 = str2double(tempC{5});
            detection(index).score = str2double(tempC{6});     
            index = index + 1
            tline = fgetl(fid); 
            if ischar(tline)
                tempC = strsplit(tline);
            end
        end
        fclose (fid);
    end
    save ([expdir expname 'label' '.mat'], 'detection'); 
end

score_th = -1; 
det_score = [detection.score]; 
detected = detection(find(det_score >= score_th)); 

% Visualize the results
label = [detected.label]; 
imset{1} = find(label == 1); 
imset{2} = find(label == 2);
num_im = 600; 
pix_height = 6*512;
pix_width = 2*512; 

class = {'TP', 'FP'}; 

% scale = 0.25; 
scale = 0.4; 
for i = 1:2   
    ii = 1; 
    while ii < num_im
        ii
        rs =1; concatenated_image =[];
        while rs < 0.9*pix_height && ii< num_im 
            one_row = [];
            cs = 1;
            while cs < 0.9*pix_width  &&  ii< num_im    

                im = imread(detected(imset{i}(ii)).impath);
                
                x1 = detected(imset{i}(ii)).x1; 
                x2 = detected(imset{i}(ii)).x2; 
                y1 = detected(imset{i}(ii)).y1;
                y2 = detected(imset{i}(ii)).y2;
                xwid = x2 - x1; 
                ywid = y2 - y1; 
                xc = round((x1+x2)/2); 
                yc = round((y1+y2)/2); 
                
                x1 = max(xc-scale*xwid, 1);
                y1 = max(yc-scale*ywid, 1);
                x2 = min(xc+scale*xwid, 8192);
                y2 = min(yc+scale*ywid, 1320);                
                
                if xwid > 200
                   ii = ii + 10; 
                   continue; 
                end
%                 if (xwid < 128) 
%                     x1 = xc - 64; 
%                     x2 = xc + 64;
%                 end
%                 if (ywid < 128)
%                     y1 = yc - 80; 
%                     y2 = yc + 48;
%                 end
                im = im (max(1,y1):min(1320, y2), max(1,x1):min(8192,x2), :);
                
                % im = im(detected(imset{i}(ii)).y1:detected(imset{i}(ii)).y2,detected(imset{i}(ii)).x1:detected(imset{i}(ii)).x2, :);
                im(:,1:2,1) = 255; im(:,(end-2):end,1) = 255; im(1:2,:, 1) = 255; im((end-2):end,:,1) = 255; 
                % im = imresize(im, [100 100]); 
                [h,w,ch] = size(im);
                one_row(1:h, cs:cs+w-1,:) = uint8(im);
                cs = size(one_row,2)+1; 
                ii = ii+10
            end
            [h,w,ch] = size(one_row);
            concatenated_image(rs:rs+h-1,1:w,:) = one_row;
            rs = size(concatenated_image,1) + 1;
        end
    end
    chip = figure; 
    imshow(uint8(concatenated_image)); 
    set(gca, 'Position', [0 0 1 1]);
    title ([class{i} ])    
    saveas(chip, [expdir expname class{i} '_detection' ], 'jpg'); 
    pause 
    clear chip
end

end
