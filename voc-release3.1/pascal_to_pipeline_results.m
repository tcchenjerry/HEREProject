function [] = pascal_to_pipeline_result(boxes)
pano_start_y = 1980;
pano_start_x = 0;

root_dir = '/home/ivanas/here/drives/singapore/';
[name, score,x0, y0, x1, y1]=textread(fname,'%s %f %f %f %f %f');


for i = 1:length(x1)
    drive_id = name{i}(1:16); 
    raster_id = name{i}(18:end);
    dir    = [root_dir,drive_id,'/rasters/'];
    dirres = [root_dir,drive_id,'/result_dpmTH1pAB/', raster_id,'/'];
    if ~exist(dirres, 'dir')
      eval(['!mkdir -m 774 -p ', dirres]);
    end
    if ~exist([dirres,'raster.jpg'], 'file')
        eval(['!sudo cp ', dir,raster_id,'/raster.jpg ', dirres]);
    end
    fid = fopen([dirres,'detected_plates.txt'],'a');
    fprintf(fid, [num2str(ceil(x0(i))+pano_start_x), ' ', num2str(floor(x1(i))+pano_start_x),  ' ', num2str(ceil(y0(i))+pano_start_y), ' ',num2str(floor(y1(i))+pano_start_y),'\n']);
    fclose(fid);
    fid = fopen([dirres,'detected_cars.txt'],'a');
    fprintf(fid, [num2str(ceil(x0(i))+pano_start_x),  ' ', num2str(floor(x1(i))+pano_start_x), ' ', num2str(ceil(y0(i))+pano_start_y),' ',num2str(floor(y1(i))+pano_start_y),'\n']);
    fclose(fid);
    
end

