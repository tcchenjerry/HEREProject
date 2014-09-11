function [] = pascal_to_pipeline_results2(boxes)
pano_start_y = 1980;
pano_start_x = 0;

root_dir = '/home/ivanas/here/drives/us/';
%[name, score,x0, y0, x1, y1]=textread(fname,'%s %f %f %f %f %f');
name = textread('../VOCdevkit/VOC2008/ImageSets/Main/test.txt', '%s');

for i = 1:length(boxes)
   if strcmp(name{i}(1:5),'HT052')
   %if strcmp(name{i}(1:16),'HT067_1380767737')
        drive_id =name{i}(1:end-7);
        raster_id =name{i}(end-5:end);
        dir    = [root_dir,drive_id,'/rasters/'];
        dirres = [root_dir,drive_id,'/result_dpm_3comp/', raster_id,'/'];
        if ~exist(dirres, 'dir')
            eval(['!mkdir -m 774 -p ', dirres]);
        end
        if ~exist([dirres,'raster.jpg'], 'file')
            eval(['!sudo cp ', dir,raster_id,'/raster.jpg ', dirres]);
        end
        
        
        fid1 = fopen([dirres,'detected_plates.txt'],'a');
        fid2 = fopen([dirres,'detected_cars.txt'],'a');
        x0 = boxes{i}(:,1);
        x1 = boxes{i}(:,3);
        y0 = boxes{i}(:,2);
        y1 = boxes{i}(:,4);
        score = boxes{i}(:,5);
        for j = 1: length(x0)
            area = (x1(j)-x0(j)+1).*(y1(j)-y0(j)+1);
            if area<80000 && area>500 &&  score(j) > -20
                 
                fprintf(fid1, [num2str(ceil(x0(j))+pano_start_x), ' ', ...
                    num2str(floor(x1(j))+pano_start_x),  ' ', ...
                    num2str(ceil(y0(j))+pano_start_y), ' ', ...
                    num2str(floor(y1(j))+pano_start_y),' ', ...
                    num2str(score(j)),  '\n']);
                
                
                fprintf(fid2, [num2str(ceil(x0(j))+pano_start_x),  ' ', ...
                    num2str(floor(x1(j))+pano_start_x), ' ',...
                    num2str(ceil(y0(j))+pano_start_y), ' ',...
                    num2str(floor(y1(j))+pano_start_y),'\n']);
                
            end
            
        end
        
        fclose(fid1);
        fclose(fid2);
    end
end
