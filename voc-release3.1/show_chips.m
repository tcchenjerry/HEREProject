function [] = show_chips(load_dir, fname)
load_dir
fs = dir([load_dir '*.*g']);

num_im = length(fs)-2
pix_height = 512;
pix_width  = 3*512;

for ii = 1:length(fs)
    im{ii} = imread([load_dir, '/', fs(ii).name]);
    h(ii) = size(im{ii},1);
    w(ii) = size(im{ii},2);
end

[val, I ]= sort(h,'ascend');

 
ii = 1; fid = 1; 
while ii< num_im 
   rs =1; concatenated_image =[];
    while rs < 0.9*pix_height & ii< num_im 
        one_row = [];
        cs = 1; 
        while cs < 0.9*pix_width  &  ii< num_im    
            % concatenate next image in this line
            A = im{I(ii)};
            [h,w,ch] = size(A);
            one_row(1:h, cs:cs+w-1,:) = uint8(A);
            cs = size(one_row,2)+1; 
            ii = ii+1;
        end
        %figure, imshow(uint8(one_row));
        % add constructed row to the existing image
        [h,w,ch] = size(one_row);
        concatenated_image(rs:rs+h-1,1:w,:) = one_row;
        rs = size(concatenated_image,1) + 1;
    end
   figure(fid), clf, imshow(uint8(concatenated_image));
   %print(gcf,'-dpng',[fname,'_',num2str(fid)]); 
    [fname,'_',num2str(fid),'.jpg']
   imwrite(uint8(concatenated_image), [fname,'_',num2str(fid),'.jpg'])
   fid = fid+1;
   pause(1)

end
 
