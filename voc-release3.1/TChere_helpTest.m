clear all

fidout = fopen('test.txt', 'w'); 
fid = fopen('boxes1_comp2_det_test_plate.txt', 'r');

tline = fgetl(fid);

while ischar(tline)
    % disp(tline);
    tempC = strsplit(tline);
    fprintf(fidout, '%s ', tempC{1}(1:16)); % Driver Id
    fprintf(fidout, '%s ', tempC{1}(18:end)); % Capture Id
    fprintf(fidout, '%s ', tempC{2}); 
    for k = 3:6
        temp = round(str2double(tempC{k})); 
        fprintf(fidout, '%s ', num2str(temp)); 
    end
    fprintf(fidout, '\n'); 

    tline = fgetl(fid);
end


