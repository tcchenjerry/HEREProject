function feat_all = TChere_filter_extractFeature(detection, trainset)
    feat_all = zeros(length(trainset),4096); 
    for i = 1:length(trainset) 
        i
        im = imread([detection(trainset(i)).impath]);
        x1 = detection(trainset(i)).x1;
        x2 = detection(trainset(i)).x2;
        y1 = detection(trainset(i)).y1;
        y2 = detection(trainset(i)).y2;
        xwid = x2 - x1; 
        ywid = y2 - y1; 
        xc = round((x1+x2)/2); 
        yc = round((y1+y2)/2); 
        if (xwid < 128) 
            x1 = xc - 64; 
            x2 = xc + 64;
        end
        if (ywid < 128)
            y1 = yc - 80; 
            y2 = yc + 48;
        end
        im = im (max(1,y1):min(1320, y2), max(1,x1):min(8192,x2), :);
%         figure
%         imshow(im)
        tic
        feat_all(i,:) = matcaffe_demo(im);
        toc 
        % feat_all = [feat_all ; feat'];
    end
end