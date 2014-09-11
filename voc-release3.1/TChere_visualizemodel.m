clear all

rootdir = '../VOCdevkit/results/VOC2008'; 
dirlist = dir([rootdir '/comp*']);

modeldir = '../model_X/test1/';   

for i = 1:length(dirlist)
    
    try 
        load ([modeldir dirlist(i).name '/plate_final.mat'])
        figure
        title (dirlist(i).name)
        visualizemodel(model); 
        dirlist(i).name
        pause; 
    catch
       continue;  
    end
        
end