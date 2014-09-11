function detection = TChere_filter_loadDetections(set, experiment, expdir, imgdir)

    index = 1; 
    class = {'TP', 'FP'};
    for k = 1:length(set)
        expname = [experiment '/' set{k} '/']; 
        for i = 1:2
            fid = fopen([expdir expname 'box1_plates_' class{i} '.txt'], 'r');
            % if (fid == -1)   
                LFNAME = ['../VOCdevkit/VOC2008/Annotations_txt/' set{k} '.txt'];
                % DATAD = [expdir 'test2/comp_3_part_4_structure_5_3_context_2/' 'box1_comp_3_part_4_structure_5_3.txt'];
                % DATAD = [expdir experiment '/box1_comp_3_part_4_structure_5_3.txt']; 
                DATAD = [expdir 'train/' experiment '/box1_' experiment '.txt']; 
                % eval (['! python ../prepare_data/TChere_privacy_evaluation_roc_v2.py ' LFNAME ' ' DATAD ' plates' ]); 
                eval (['! python ../prepare_data/TChere_privacy_evaluation_roc_v3.py ' LFNAME ' ' DATAD ...
                    ' plates ' '--threshold 0.5 ' '--threshold-lower 0.001 ' '--train 1']);
                fid = fopen([expdir 'train/' expname 'box1_plates_' class{i} '.txt'], 'r');
            % end
            tline = fgetl(fid);
            tempC = strsplit(tline);    
            while ischar(tline)
                detection(index).impath = [imgdir set{k} '_' tempC{1} '.jpg']; 
                detection(index).label = i; 
                detection(index).x1 = str2double(tempC{2});
                detection(index).y1 = str2double(tempC{3});
                detection(index).x2 = str2double(tempC{4});
                detection(index).y2 = str2double(tempC{5});
                detection(index).score = str2double(tempC{6});     
                
                if (i == 2)
                    im = imread(detection(index).impath); 
                    im = im(detection(index).y1:detection(index).y2, detection(index).x1:detection(index).x2, :);
                    figure 
                    imshow(im)
                    pause; 
                    close all
                end
                
                index = index + 1
                tline = fgetl(fid); 
                if ischar(tline)
                    tempC = strsplit(tline);
                end
            end
            fclose (fid);
        end
    end
    save ([expdir experiment '/label' '.mat'], 'detection'); 

end
