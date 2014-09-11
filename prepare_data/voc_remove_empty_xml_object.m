
dir_path = '/home/cmwang/Earthmine/Code/object_detector_training/VOCdevkit/VOC2008/Annotations';
dirlist = dir(dir_path);

for k = 3 : length(dirlist)
    xml_filepath = sprintf('%s/%s', dir_path, dirlist(k).name);
    td.xml=VOCreadxml(xml_filepath);
    
    try
        length(td.xml.annotation.object);
    catch
        xml_filepath
        delete(xml_filepath)
    end
end