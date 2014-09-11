%%
raw_image_dir = '/home/ivanas/here/lidar/objdet_training/code_dpm/VOCdevkit/VOC2008/JPEGImages';
xml_annotation_dir ='/home/ivanas/here/lidar/objdet_training/code_dpm/VOCdevkit/VOC2008/Annotations/';

dirlist = dir(xml_annotation_dir);
for k = 49 : length(dirlist)
    im_name = dirlist(k).name;
    im_name = im_name(1:length(im_name)-4);
    fprintf('%s\n', im_name);
    im = imread(sprintf('%s/%s.jpg', raw_image_dir, im_name));
    
    xml_path = sprintf('%s/%s.xml', xml_annotation_dir, im_name);
    td.xml=VOCreadxml(xml_path);

    for ok = 1 : length(td.xml.annotation.object)
        xmin = round(str2num(td.xml.annotation.object(ok).bndbox.xmin)+1);
        ymin = round(str2num(td.xml.annotation.object(ok).bndbox.ymin)+1);
        xmax = round(str2num(td.xml.annotation.object(ok).bndbox.xmax)+1);
        ymax = round(str2num(td.xml.annotation.object(ok).bndbox.ymax)+1);
        
        val = [255, 0, 0];
        for pidx = 1 : 3
            im(ymin, xmin:xmax, pidx) = val(pidx);
            im(ymax, xmin:xmax, pidx) = val(pidx);
            im(ymin:ymax, xmin, pidx) = val(pidx);
            im(ymin:ymax, xmax, pidx) = val(pidx);
        end;
       
    end;
    figure(1); imshow(im); title(sprintf('%d', k));
    pause;
end;
