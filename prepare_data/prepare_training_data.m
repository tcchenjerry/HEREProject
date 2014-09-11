% Modified on 6/25 by tchen, change the drives to only Singapore and Taiwan
% (1,2,3,8,10)

subset = [1 2 3 8 10]; 

% Master script to prepare new training data

drive_id{1} = 'HT067_1381913307';
drive_id{2} = 'HT067_1381981716';
drive_id{3} = 'HT068_1380264747';

drive_id{4} = 'HT024_1377677817';

drive_id{5} = 'HT086';


% test sets
drive_id{6} = 'HT039';
drive_id{7} = 'HT052set3';
drive_id{8} = 'HT067_1380767737';
drive_id{9} = 'HT024_1377677817_2';

% new sets 
drive_id{10}= 'HT053_1381122097'; %taiwan
drive_id{11}= 'HT022_1383161169'; %baltimore
drive_id{12}= 'HT110_1386191490'; %hawaii
drive_id{13}= 'HT052_1376505975'; %san francisco



country{1}  = 'singapore';
country{2}  = 'singapore';
country{3}  = 'singapore';
country{4}  = 'amsterdam';
country{5}  = 'us';
country{6}  = 'us';
country{7}  = 'us';
country{8}  = 'singapore';
country{9}  = 'amsterdam';
country{10}  = 'taiwan';
country{11}  = 'us';
country{12}  = 'us';
country{13}  = 'us';

% 

label_type{1} = 'clear_plates';
label_type{2} = 'clear_plates';
label_type{3} = 'clear_plates';
label_type{4} = 'clear_plates';
label_type{5} = 'clear_plates';
label_type{6} = 'plates';
label_type{7} = 'plates';
label_type{8} = 'clear_plates';
label_type{9} = 'clear_plates';
label_type{10} = 'clear_plates';
label_type{11} = 'clear_plates';
label_type{10} = 'clear_plates';
label_type{12} = 'clear_plates';
label_type{13} = 'clear_plates';

% save training/testing images into VOC2008/...
if (1)
    % for i = 1:length(drive_id)
    for i = 1:length(subset)
        rasters_dir = ['/media/pacific/drives/',country{subset(i)},'/', drive_id{subset(i)},'/rasters/'];
        sqlite_path = [rasters_dir, 'rastersLabeledObjects.sqlite'];
        cmd = ['!python prepare_training_data_dpm.py', ' ', sqlite_path, ...
                ' ', rasters_dir, ' ', drive_id{subset(i)}, ' ', 'plates',...
                ' ', '--label-type1 ', label_type{subset(i)} ]
        eval(cmd);
    end
end

% convert all labled boxes to xml
voc_convert_bbox_xml

% create training sets 
% may need to create dir:  
% eval('! sudo mkdir /home/ivanas/here/objdet_training/code_dpm/VOCdevkit/VOC2008/ImageSets/Main')
% eval('!sudo chmod 777 -R /home/ivanas/here/objdet_training/code_dpm/VOCdevkit/VOC2008/ImageSets/')
cmd = ['!python  voc_create_training_txt.py'];
eval(cmd)



