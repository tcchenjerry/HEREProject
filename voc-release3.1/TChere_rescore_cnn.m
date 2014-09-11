function scores = TChere_rescore_cnn(im, b, scale)
    
    xc = (b(1) + b(3))/2; 
    yc = (b(2) + b(4))/2; 
    xwid = xc - b(1); 
    ywid = yc - b(2); 
    b(1) = max(xc-scale*xwid, 1);
    b(2) = max(yc-scale*ywid, 1);
    b(3) = min(xc+scale*xwid, 8192);
    b(4) = min(yc+scale*ywid, 1320);    

    input_data = {prepare_image(im(round(b(2):b(4)),round(b(1):b(3)),:))};
    tempscores = caffe('forward', input_data);
    scores = squeeze(tempscores{1});
    scores = scores(1); 
    
%     figure
%     imshow(im(b(2):b(4),b(1):b(3),:))
%     title (num2str(scores))
%     pause; 
    
    close all; 
end

% ------------------------------------------------------------------------
function images = prepare_image(im)
% ------------------------------------------------------------------------
% d = load('ilsvrc_2012_mean');
d = load('licenseplate_mean'); 

IMAGE_MEAN = d.image_mean;
IMAGE_DIM = 80;
CROPPED_DIM = 64;

% resize to fixed input size
im = single(im);
im = imresize(im, [IMAGE_DIM IMAGE_DIM], 'bilinear');
% permute from RGB to BGR (IMAGE_MEAN is already BGR)
im = im(:,:,[3 2 1]) - IMAGE_MEAN(:,:,[3 2 1]);

% oversample (4 corners, center, and their x-axis flips)
images = zeros(CROPPED_DIM, CROPPED_DIM, 3, 10, 'single');
indices = [0 IMAGE_DIM-CROPPED_DIM] + 1;
curr = 1;
for i = indices
  for j = indices
    images(:, :, :, curr) = ...
        permute(im(i:i+CROPPED_DIM-1, j:j+CROPPED_DIM-1, :), [2 1 3]);
    images(:, :, :, curr+5) = images(end:-1:1, :, :, curr);
    curr = curr + 1;
  end
end
center = floor(indices(2) / 2)+1;
images(:,:,:,5) = ...
    permute(im(center:center+CROPPED_DIM-1,center:center+CROPPED_DIM-1,:), ...
        [2 1 3]);
images(:,:,:,10) = images(end:-1:1, :, :, curr);
end
