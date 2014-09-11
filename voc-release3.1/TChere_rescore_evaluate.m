function TChere_rescore_evaluate(rescore, detection, testind, fidout, expdir, experiment, svm_ratio)

    rescore_min = min(rescore); 
    rescore_max = max(rescore);

    % for i = 1:length(result)
    for i = 1:size(rescore,2)
        tmp = detection(testind(i)); 
        fprintf(fidout, '%s %s %f %d %d %d %d\n' , tmp.impath(end-26:end-11), ...
            tmp.impath(end-9:end-4), rescore(i), tmp.x1, tmp.y1, tmp.x2, tmp.y2);
    end
    fclose(fidout); 
    testset = {'HT053_1381122097', 'HT067_1380767737'}; 
    for i = 1:length(testset)  % Different tests
        LFNAME = ['../VOCdevkit/VOC2008/Annotations_txt/' testset{i} '.txt'];   % For the labels
        testdir = [expdir experiment '/filter/' testset{i} '/']; 
        if (~exist(testdir,'dir')) 
            mkdir(testdir); 
        end
        DATAD = [expdir experiment '/filter/' 'box1_' experiment '.txt'];   % For the detection scores 
        eval (['! python ../prepare_data/TChere_privacy_evaluation_roc_v3.py ' LFNAME ' ' DATAD ...
            ' plates ' '--min ' num2str(rescore_min) ' --max ' num2str(rescore_max) ' --scaling 0.5']); 
        % eval (['! python ../prepare_data/TChere_privacy_evaluation_roc_v3.py ' LFNAME ' ' DATAD ...
        %     ' plates ' '--min ' ' -5 ' ' --max ' ' 0.4 ']); 

        TChere_plotROC([testdir 'box1_plates_roc.txt'], testdir, 1); 
    end
    % Get summary of all test set
    sumdir = [expdir experiment '/filter/summary/'];
    if (~exist(sumdir, 'dir'))
       mkdir (sumdir); 
    end
    tablesum = zeros(17,8); 
    for i = 1:length(testset)
        testdir = [expdir experiment '/filter/' testset{i} '/']; 
        load ([testdir 'roc1.mat']); 
        tablesum = tablesum + roctable; 
    end
    sumfname = [expdir experiment '/filter/summary/' 'box_sum_' num2str(svm_ratio)  '.mat']; 
    save (sumfname, 'tablesum');        
    TChere_plotROC(sumfname, [expdir experiment '/filter/summary/'], 1);    

    close all    

end