function TChere_filterFP_printROC(testset, svm_ratio, expdir, experiment)

    fidout = fopen([expdir experiment '/filter_roc.txt'], 'w'); 

    fprintf(fidout, 'DATA: %s\n', [expdir experiment]); 
    fprintf(fidout, '\n'); 

    load ([expdir experiment '/summary/roc1.mat']);
    roctable(:,1:5) = roctable(:,1:5)/length(testset); 
    fprintf(fidout, 'Without Rescoring\n'); 
    fprintf(fidout, 'threshold\t#recall\t\t#FPR\t\t#pixel FPR\tprecision\t#TP\t\t#FN\t\t#FP\n'); 
    fprintf(fidout, '---------------------------------------------------------------------------------------------------\n'); 
    for j = 1:size(roctable, 1)
        fprintf(fidout, '%.2f\t\t%.2f\t\t%.2f\t\t%.2f\t\t%.2f\t\t%d\t\t%d\t\t%d\t\t\n', roctable(j,:))
    end
    fprintf(fidout, '\n');

    for i = 1:length(svm_ratio)
        load ([expdir experiment '/filter/summary/' 'box_sum_' num2str(svm_ratio(i)) '.mat'])
        tablesum(:,1:5) = tablesum(:,1:5)/length(testset); 
        fprintf(fidout, '#Rescore Ratio = %d\n', svm_ratio(i)); 
        fprintf(fidout, 'threshold\t#recall\t\t#FPR\t\t#pixel FPR\tprecision\t#TP\t\t#FN\t\t#FP\n'); 
        fprintf(fidout, '---------------------------------------------------------------------------------------------------\n'); 
        for j = 2:size(tablesum, 1)
            fprintf(fidout, '%.2f\t\t%.2f\t\t%.2f\t\t%.2f\t\t%.2f\t\t%d\t\t%d\t\t%d\t\t\n', tablesum(j,:))
        end
        fprintf(fidout, '\n'); 
    end

    fclose(fidout); 

end