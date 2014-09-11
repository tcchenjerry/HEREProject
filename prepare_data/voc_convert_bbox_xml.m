%
% This code converts bounding boxes stored in text files into boudning
% boxes in xml format that VOC can read
% 

% Modified by tchen on 6/25, change the output directory

targetdir = '/home/zeyuli/tchen/here/objdet_training/code_dpm_here/VOCdevkit/VOC2008/'; 

raw_image_dir      = [targetdir 'JPEGImages']; 
cropped_image_dir  = [targetdir 'JPEGImages']; 
annotation_dir     = [targetdir 'Annotations_txt'];
xml_annotation_dir = [targetdir 'Annotations'];

% raw_image_dir      = '/home/ivanas/here/objdet_training/code_dpm_here/VOCdevkit/VOC2008/JPEGImages'; 
% cropped_image_dir  = '/home/ivanas/here/objdet_training/code_dpm_here/VOCdevkit/VOC2008/JPEGImages'; 
% annotation_dir     = '/home/ivanas/here/objdet_training/code_dpm_here/VOCdevkit/VOC2008/Annotations_txt';
% xml_annotation_dir = '/home/ivanas/here/objdet_training/code_dpm_here/VOCdevkit/VOC2008/Annotations';

if ~exist(xml_annotation_dir,'dir')
    eval(['!sudo mkdir ',xml_annotation_dir])
    eval(['!sudo chmod 777 ',xml_annotation_dir])
end
    
dirlist = dir(cropped_image_dir);
for k = 3 : length(dirlist)
    cropped_filename = dirlist(k).name;
    fprintf('%s\n', cropped_filename);

    bbox_idx = str2num(cropped_filename(length(cropped_filename)));
    image_filename = cropped_filename(1:(length(cropped_filename)-4));

    xml_save_path = sprintf('%s/%s.xml', xml_annotation_dir, image_filename);
    if exist(xml_save_path,'file')
        fprintf(xml_save_path);
        continue; 
    end
    try
        td.xml=VOCreadxml(xml_save_path);
        o = length(td.xml.annotation.object)+1;
    catch
        % xml file didn't exist, initialize it
        td.xml=VOCreadxml('./blank_anno.xml');
        % set the size
        raw_im = imread(sprintf('%s/%s.jpg', raw_image_dir, image_filename));
        td.xml.annotation.size.width = size(raw_im, 1);
        td.xml.annotation.size.height = size(raw_im, 2);
        td.xml.annotation.filename = sprintf('%s.jpg', image_filename);
        
        o = 1;
    end

    td.xml.annotation.status.annotatedby = 'Ivana';
    td.xml.annotation.status.checkedby='-';

    try
        [x0, y0, x1, y1] = textread(sprintf('%s/%s_labels.txt', annotation_dir, image_filename));     
        for o = 1: length(x0)
            td.xml.annotation.object(o).name='plate';
            td.xml.annotation.object(o).pose='Unspecified';
            td.xml.annotation.object(o).truncated=num2str(0);
            td.xml.annotation.object(o).occluded=num2str(0);
            td.xml.annotation.object(o).bndbox.xmin=num2str(x0(o)+1);
            td.xml.annotation.object(o).bndbox.ymin=num2str(y0(o)+1);
            td.xml.annotation.object(o).bndbox.xmax=num2str(x1(o)+1);
            td.xml.annotation.object(o).bndbox.ymax=num2str(y1(o)+1);
            td.xml.annotation.object(o).bad='0';
            td.xml.annotation.object(o).checkedby='-';
        end
    catch 
        fprintf('Can not read %s_lables.txt file\n', image_filename);    
        % dummy way not to store any object
        for o = 1:1
            td.xml.annotation.object(o).name='dummy';
            td.xml.annotation.object(o).pose='Unspecified';
            td.xml.annotation.object(o).truncated=num2str(0);
            td.xml.annotation.object(o).occluded=num2str(0);
            td.xml.annotation.object(o).bndbox.xmin=num2str(x0(o)+1);
            td.xml.annotation.object(o).bndbox.ymin=num2str(y0(o)+1);
            td.xml.annotation.object(o).bndbox.xmax=num2str(x1(o)+1);
            td.xml.annotation.object(o).bndbox.ymax=num2str(y1(o)+1);
            td.xml.annotation.object(o).bad='0';
            td.xml.annotation.object(o).checkedby='-';
        end
    end

    VOCwritexml(td.xml, xml_save_path);
end;
