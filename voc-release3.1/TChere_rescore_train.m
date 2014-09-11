function model = TChere_rescore_train(ex_para, score_th)

addpath(genpath('../utils/'))
experiment = ['comp_' int2str(ex_para.n) '_part_' int2str(ex_para.partN) '_structure_' int2str(ex_para.sinter) '_' int2str(ex_para.soctaves)]; 

testset = {'HT068_1380264747', 'HT067_1381981716', 'HT053_1381122097', 'HT067_1380767737'};   % Validation set 

expdir = '../VOCdevkit/results/VOC2008/'; 
imgdir = '../VOCdevkit/VOC2008/JPEGImages/';  

use_gpu = 1; 
try 
    load ([expdir '/val/' 'label' '.mat']); 
catch
    index = 1; 
    class = {'TP', 'FP'};
    for k = 1:length(testset)
        expname = [experiment '/' testset{k} '/']; 
        for i = 1:2
            fid = fopen([expdir expname '/val/' 'box1_plates_' class{i} '.txt'], 'r');
            if (fid == -1)
                LFNAME = ['../VOCdevkit/VOC2008/Annotations_txt/' testset{k} '.txt']; 
                DATAD = [expdir '/val/' experiment '/box2_' experiment '.txt'];
                eval(command(['! python ' LFNAME ' ' DATAD ' plates']))
                fid = fopen([expdir expname '/val/' 'box1_plates_' class{i} '.txt'], 'r');
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
    save ([expdir '/val/' label' '.mat'], 'detection'); 
end

det_score = [detection.score]; 
detected = detection(find(det_score >= score_th)); 

if use_gpu
    matcaffe_init(1);
else
    matcaffe_init(); 
end

try 
    load ([expdir '/val/' 'feature_' int2str(score_th) '.mat']); 
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
    save ([expdir '/val/' 'feature_' int2str(score_th) '.mat']); 
end
label = [detected.label]';

trainTP = trainset(find(label == 1))'; 
trainFP = trainset(find(label == 2)); 
trainFP = trainFP(1:length(trainTP))'; 
trainset_BAL = [trainTP ; trainFP]; 

model = train(label(trainset_BAL), sparse(double(feat_all(trainset_BAL, :))),'-s 4 -c 1'); 

end