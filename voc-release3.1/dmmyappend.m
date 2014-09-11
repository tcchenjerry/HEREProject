
pano_start_y = 0;
pano_start_x = 0;

%src_dir = '/home/ivanas/here/drives/singapore/HT067_1381981716/resultABonly/';
%src_dir = '/home/ivanas/here/lidar/objdet_training/plates/adaboost/haar/output_model/train_rasters_eval/'

%dst_dir = '/home/ivanas/here/drives/singapore/HT067_1381981716/result_dpmTH1pAB/';


list = dir(src_dir)
for j = 3:length(list)
   
    fname = [src_dir, list(j).name,'/detected_plates.txt']
    if exist(fname,'file')
        [x0, x1, y0, y1] = textread(fname, '%d %d %d %d');
        
        if ~exist([dst_dir, list(j).name], 'dir')
            eval(['!sudo cp  ',[src_dir, list(j).name], ' ', [dst_dir, list(j).name] ] );
        else
            fid = fopen([dst_dir, list(j).name,'/detected_plates.txt'],'a');
            for i = 1:length(x0)
                
                fprintf(fid, [num2str(ceil(x0(i))+pano_start_x), ' ', num2str(floor(x1(i))+pano_start_x),  ' ', num2str(ceil(y0(i))+pano_start_y), ' ',num2str(floor(y1(i))+pano_start_y),'\n']);
                
            end
            fclose(fid);
        end
    end
end