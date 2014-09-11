function test_ian()

cal = 1; 
if (cal)
    % Load bbox
    drive = 'HT067_1380767737'; 
    fid = fopen(['/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/VOC2008/Annotations_txt/' drive '.txt'], 'r'); 
    tline = fgetl(fid);

    load('data/ConvNet__2014-05-20_11.17.48_53.6216_fulldata.mat', 'model');
    i = 1; 
    prob_map = {};
    while ischar(tline)
        tempC = strsplit(tline);  
        im = imread(['/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/VOC2008/JPEGImages/' drive '_' tempC{1} '.jpg']); 
        b = [str2num(tempC{2}) str2num(tempC{3}) str2num(tempC{4}) str2num(tempC{5})];

        im(b(2):b(4),b(1),2) = 255; 
        im(b(2):b(4),b(3),2) = 255; 
        im(b(2),b(1):b(3),2) = 255; 
        im(b(4),b(1):b(3),2) = 255;     

        height = b(4) - b(2); % Change in Y
        cent = 1/2*(b(4)+b(2));
        line = [b(1) cent b(3) cent];
        theta = 0;

        [cropped_im cropped_lab] = crop_lines(im2double(im), line, height, theta, [], 32, 3.5);
        cropped_im = cropped_im{1};

        cropped_lab = cropped_lab{1}; % This will show give what pixels to grab from
        res = TChere_apply_cnn_model_direct(cropped_im, model);
        probs = interleave_maps(res.probs.res);
        probs = probs(:,:,2);

        % cropped_im(1:4:end, 1:4:end, :) = 0;
        p = repmat(probs(1:3:end, 1:3:end), [1 1 3]); 

        % cropped_im
        cropped_im(1:3:end, 1:3:end, :) = cropped_im(1:3:end, 1:3:end, :) - cropped_im(1:3:end, 1:3:end, :).*(p > 0.1); 
        cropped_im(1:3:end, 1:3:end, 1) = cropped_im(1:3:end, 1:3:end, 1) + (probs(1:3:end, 1:3:end) > 0.1).*probs(1:3:end, 1:3:end); 


        h = figure; 
        imshow (cropped_im)
        % pause    

        % saveas(h, ['../figures/' num2str(i) '.jpg'], 'jpg')    
        % my_save_figure_tight(h, ['../figures/' num2str(i) '.png'])
    %     figure
    %     imshow (probs)
    %     pause
        % close all
        stats = regionprops(cropped_lab, 'BoundingBox'); 
        bboxstat = round(stats.BoundingBox); 
        bcrop = [bboxstat(1), bboxstat(2), bboxstat(1)+bboxstat(3)-2, bboxstat(2) + bboxstat(4)-2];  

        prob_map{i} = probs(bcrop(2):bcrop(4), bcrop(1):bcrop(3)); 

        i = i + 1
        tline = fgetl(fid);
        close all

        if (i == 500)
            break; 
        end
    end
    save('../figures/probmap.mat', 'prob_map');     

    fclose(fid);      
end

load ('../figures/probmap.mat')

sum_prob = zeros(32, 64); 
for i = 1:length(prob_map)
    sum_prob = sum_prob + imresize(prob_map{i}, [32 64]); 
end

figure
imagesc(sum_prob/length(prob_map))


end