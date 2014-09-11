clear all

prepare_TPFP_list = 0; 
prepare_train = 1; 

ii = 1;
rootdir = '/media/pacific/drives/'; 
if (prepare_TPFP_list)

    resdir = 'result_dpm_4comp_nms01_nohyfilter'; 
    country = {'us', 'amsterdam', 'mexico', 'singapore', 'south_africa', 'taiwan'};
    fn = 'detected_plates_labeled.txt'; 

    % fidoutTP = fopen('../cnn/TP.txt', 'w');
    % fidoutFP = fopen('../cnn/FP.txt', 'w'); 

    for i = 1:length(country)
        dirlist = dir([rootdir country{i} '/' 'HT*']); 
        for k = 1:length(dirlist)
            caplist = dir([rootdir country{i} '/' dirlist(k).name '/' resdir '/0*']); 
            for m = 1:length(caplist)
                fid = fopen([rootdir country{i} '/' dirlist(k).name '/' resdir '/' caplist(m).name '/' fn], 'r');
                if (fid == -1)
                    continue; 
                end
                tline = fgetl(fid); 
                while(ischar(tline))
                   tempC = strsplit(tline); 
                   % bbox = [str2double(tempC{2}) str2double(tempC{3}) str2double(tempC{4}) str2double(tempC{5})]; 
                   detection(ii).country = country{i};
                   detection(ii).drive = dirlist(k).name; 
                   detection(ii).capture = caplist(m).name; 
                   % detection(ii).bbox = bbox; 
                   detection(ii).x1 = str2double(tempC{2});
                   detection(ii).y1 = str2double(tempC{3});
                   detection(ii).x2 = str2double(tempC{4});
                   detection(ii).y2 = str2double(tempC{5});
                   detection(ii).score = str2double(tempC{6}); 
                   if (tempC{1} == '1')  % TP
                       detection(ii).label = 0; 
                   else  % FP
                       detection(ii).label = 1; 
                   end
                   % if (tempC{1} == '1')
                   %     detection()
                       % fprintf(fidoutTP, '%s %s %s %s %s \n', country{i}, dirlist(k).name, caplist(m).name, tempC{6}, bbox); 
                   % else 
                       % fprintf(fidoutFP, '%s %s %s %s %s \n', country{i}, dirlist(k).name, caplist(m).name, tempC{6}, bbox); 
                   % end
                   tline = fgetl(fid); 
                   ii = ii + 1;
                end
                fclose(fid); 
            end
        end
    end
    save('../cnn/detection.mat', 'detection');
    % fclose(fidoutTP); 
    % fclose(fidoutFP); 

end

dstpath = '/mnt/blip/work-area-tchen/data/'; 

valdir = [dstpath 'val/']; 
traindir = [dstpath 'train/'];

if (prepare_train)

    val_size = 500;
    
    load('../cnn/detection.mat'); 
    
    det_score = [detection.score];
    det_label = [detection.label];

    pos = find((det_label == 0) .* (det_score > -0.6));  % TP

    % Subsampling FP
    TP_FP_ratio = 2; 
    % (a) Choose detections with higher scores
    sample_score = 0.3; % The highest score threshold
    neg = find((det_label == 1).*(det_score> sample_score)); 
    while (length(neg) < length(pos)*TP_FP_ratio*1.5)
        sample_score = sample_score - 0.1; 
        neg = find((det_label == 1).*(det_score > sample_score)); 
    end
    % (b) Choose detection with greater heights
    negh = zeros(1,length(neg));
    for i = 1:length(neg)
        % im = imread([detection(neg(i)).impath ]); 
        negh(i)= detection(neg(i)).y2 - detection(neg(i)).y1; 
    end
    [sorth I] = sort(negh,'descend');
    neg = neg(I(1:min(round(length(pos)*TP_FP_ratio), length(neg))));

    trainind = [pos(val_size+1:end) neg(val_size+1:end)]; 
    valind = [pos(1:val_size) neg(1:val_size)];

    % Generate scripts and save images for Training

    fidout = fopen([traindir 'train.txt'], 'w');
 
    scale_all = (0.8:0.1:1.2);
    angle_all = [-3, 0, 3 ];
    x_shift_all = [-2,0,2];
    y_shift_all = [-2,0,2];    
    
    trainposN = 50000;
    iter1 = round(trainposN/length(trainind));
    
    ratio = zeros (1,length(trainind)); 
    ii = 1; 
    for i = 1:length(trainind)
        
        tmp = detection(trainind(i)); 
        im = imread([rootdir tmp.country '/' tmp.drive '/rasters/' tmp.capture '/raster.jpg']); 
        [size_y, size_x, size_z] = size(im); 
        
        bbox = [tmp.x1, tmp.y1, tmp.x2, tmp.y2]; 
%         ratio(i) = (tmp.x2 - tmp.x1)/(tmp.y2 - tmp.y1); 
%         x(i) = tmp.x2 - tmp.x1; 
%         y(i) = tmp.y2 - tmp.y1; 
        for j = 1:iter1
            
            x_shift = x_shift_all(randi(length(x_shift_all))); 
            y_shift = y_shift_all(randi(length(y_shift_all)));
            bbox = bbox + [x_shift, y_shift, x_shift, y_shift]; 
            imtemp = im(max(bbox(2), 1):min(bbox(4), size_y),max(bbox(1), 1):min(bbox(3), size_x), :); 
            
            angle = angle_all(randi(length(angle_all)));
            
            imtemp = imrotate(imtemp, angle, 'bilinear', 'crop'); 
            
            imtemp = imresize(imtemp, [32 64]); 
            imwrite(imtemp,[traindir num2str(ii) '.jpg'], 'jpeg'); 
            fprintf(fidout, [traindir num2str(ii) '.jpg' ' ' num2str(detection(trainind(i)).label) '\n']); 
            ii = ii + 1; 
        
        end
        for j = 1:iter1
            
            x_shift = x_shift_all(randi(length(x_shift_all))); 
            y_shift = y_shift_all(randi(length(y_shift_all)));
            bbox = bbox + [x_shift, y_shift, x_shift, y_shift]; 
            imtemp = im(max(bbox(2), 1):min(bbox(4), size_y),max(bbox(1), 1):min(bbox(3), size_x), :); 
            
            angle = angle_all(randi(length(angle_all)));
            
            imtemp = imrotate(imtemp, angle, 'bilinear', 'crop'); 
            
            imtemp = imresize(imtemp, [32 64]); 
            imtemp = flipdim(imtemp, 2); 
            
            imwrite(imtemp,[traindir num2str(ii) '.jpg'], 'jpeg'); 
            fprintf(fidout, [traindir num2str(ii) '.jpg' ' ' num2str(detection(trainind(i)).label) '\n']); 
            ii = ii + 1; 
        
        end        
        
        
    end
%     figure
%     hist (ratio, 30)
%     xlabel ('Aspect Ratio')
%     ylabel ('Number of instances')
%     figure
%     hist (x, 30)
%     xlabel ('Width (pixel)')
%     ylabel ('Number of instances')
%     figure
%     hist (y, 30)
%     xlabel ('Height (pixel)')
%     ylabel ('Number of instances')
    
    fclose(fidout); 
    
    fidout = fopen([valdir 'val.txt'], 'w');
    
    for i = 1:length(valind)
        tmp = detection(valind(i)); 
        i
        im = imread([rootdir tmp.country '/' tmp.drive '/rasters/' tmp.capture '/raster.jpg']); 
        im = im(max(tmp.y1,1):min(tmp.y2,size(im,1)),max(tmp.x1,1):min(tmp.x2,size(im,2)), :); 
        im = imresize(im, [32 64]); 

        imwrite(im,[valdir num2str(i) '.jpg'], 'jpeg'); 

        fprintf(fidout, [valdir num2str(i) '.jpg' ' ' num2str(detection(valind(i)).label) '\n']); 
    end
    
end

