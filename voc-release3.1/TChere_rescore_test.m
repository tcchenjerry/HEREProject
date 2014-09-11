function score = TChere_rescore_test(ex_para, score_th, model)

addpath(genpath('../utils/'))  % For calling the CAFFE program
experiment = ['comp_' int2str(ex_para.n) '_part_' int2str(ex_para.partN) '_structure_' int2str(ex_para.sinter) '_' int2str(ex_para.soctaves) '/']; 

testset = {'HT053_1381122097', 'HT067_1380767737'}; 

expdir = '../VOCdevkit/results/VOC2008/'; 
imgdir = '../VOCdevkit/VOC2008/JPEGImages/';  

use_gpu = 1; 

try 
    load ([expdir 'label' '.mat']); 
catch
    index = 1; 
    class = {'TP', 'FP'};
    for k = 1:length(testset)
        expname = [experiment '/' testset{k} '/']; 
        for i = 1:2
            fid = fopen([expdir expname 'box1_plates_' class{i} '.txt'], 'r');
            if (fid == -1)
                
                fid = fopen([expdir expname 'box1_plates_' class{i} '.txt'], 'r');
            end
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
    end
    save ([expdir 'label' '.mat'], 'detection'); 
end

det_score = [detection.score]; 
detected = detection(find(det_score >= score_th)); 

if use_gpu
    matcaffe_init(1);
else
    matcaffe_init(); 
end

try 
    load ([expdir expname 'feature_' int2str(score_th) '.mat']); 
catch
    feat_all = [];
    for i = 1:length(detected)  
        i
        % tic 
        im = imread(detected(i).impath);
        im = im(detected(i).y1:detected(i).y2,detected(i).x1:detected(i).x2, :);
        feat = matcaffe_demo(im);
        % toc 
        feat_all = [feat_all ; feat']; 
    end
    save ([expdir expname 'feature_' int2str(score_th) '.mat']); 
end

score = model.w(1,:) * feat_all'; 


end