% Set up global variables used throughout the code

% directory for caching models, intermediate data, and results
% cachedir = '../model_X/voccache/';
experiment = ['comp_' int2str(ex_para.n) '_part_' int2str(ex_para.partN) '_structure_' int2str(ex_para.sinter) '_' int2str(ex_para.soctaves) '/']; 

cachedir = ['../model_X/' experiment]; 
if 0  % never change to 1
    eval(['!sudo rm -rf  ', cachedir])
    eval(['!sudo mkdir  ', cachedir])
    eval(['!sudo chmod 777 -R ', cachedir])
end

% directory for LARGE temporary files created during training
% tmpdir = '/var/tmp/voc_X/';
tmpdir = ['../voc_X/' experiment]; 
if 0 % never change to 1
    eval(['!sudo rm -rf  ',tmpdir] )
    eval(['!sudo mkdir  ', tmpdir])
    eval(['!sudo chmod 777  -R ', tmpdir])
end

% dataset to use
VOCyear = '2008';

% directory with PASCAL VOC development kit and dataset
VOCdevkit = [ '../VOCdevkit/'];

% which development kit is being used
% this does not need to be updated
VOCdevkit2006 = false;
VOCdevkit2007 = false;
VOCdevkit2008 = false;
switch VOCyear
  case '2006'
    VOCdevkit2006=true;
  case '2007'
    VOCdevkit2007=true;
  case '2008'
    VOCdevkit2008=true;
end
