function detection = TChere_filter_loadDetections_test(experiment, expdir, imgdir)

    fid = fopen([expdir experiment '/box1_' experiment '.txt'], 'r');
    tline = fgetl(fid);
    tempC = strsplit(tline);
    index=1; 
    while ischar(tline)
        if (str2double(tempC{3}) >= -1.2)
            detection(index).impath = [imgdir tempC{1} '_' tempC{2} '.jpg']; 
            % detection(index).label = i; 
            detection(index).x1 = str2double(tempC{4});
            detection(index).y1 = str2double(tempC{5});
            detection(index).x2 = str2double(tempC{6});
            detection(index).y2 = str2double(tempC{7});
            detection(index).score = str2double(tempC{3});     
            index = index + 1
        end
        tline = fgetl(fid); 
        if ischar(tline)
            tempC = strsplit(tline);
        end
    end
    fclose (fid);      

end