% ---------- Visulization of the split data ----------- % 
function TChere_vis(spos, aspects, n, ex_para)

    TChere_globals; 
    % Plot all the 
    for k = 1:length(spos)
        
        % num_im = length(spos{k});
        num_im = 30; 
        pix_height = 1*512;
        pix_width = 3*512; 
        
        for ii = 1:num_im
            ii
            imtemp = imread(spos{k}(ii).im);
            im{ii} = imtemp(spos{k}(ii).y1:spos{k}(ii).y2, spos{k}(ii).x1:spos{k}(ii).x2-1,:); 
            hb(ii) = size(im{ii},1);
            % wb(ii) = size(im{ii},2);    
            [h w ch] = size (im{ii}); 
            h_w(ii) = h/w; 
        end

        
        [val, I] = sort(hb, 'ascend'); 
        ii = 1; fid = 1; 
        
        while ii < num_im
            rs =1; concatenated_image =[];
            while rs < 0.9*pix_height && ii< num_im 
                one_row = [];
                cs = 1; 
                while cs < 0.9*pix_width  &&  ii< num_im    
                    % concatenate next image in this line
                    A = im{I(ii)};
                    [h,w,ch] = size(A);
                    h/w
                    A(:,1:2,1) = 255; A(:,(end-2):end,1) = 255; A(1:2,:, 1) = 255; A((end-2):end,:,1) = 255;    
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
        
        end
        chip = figure; 
        imshow(uint8(concatenated_image)); 
        set(gca, 'Position', [0 0 1 1]);
        title (['set ' int2str(k) ])
        saveas(chip, [cachedir 'spos_' int2str(k) ], 'jpg'); 
        % pause; 
        clear im; clear hb; 
    end

end