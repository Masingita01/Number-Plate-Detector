function algo6v3(num)
    %Perform dilation, erosion and dilation again to create a mask of the
    %license plate
    close all
    path = strcat('images/Cars',string(num), '.png');
    f = imread(path);
    %Crops images
    cr = 20;
    %f = f(cr:end-cr,cr:end-cr,:);
    g = rgb2gray(f);
    g = imgaussfilt(g);
    [h,w] = size(g);
    %Pre processing
    g = histeq(g);
    gthresh = graythresh(g);
    image_preprocessed = im2bw(g, gthresh);
    image_preprocessed = medfilt2(image_preprocessed);
    %Edge detection
    image_edge = edge(image_preprocessed, 'canny');
    % Border restoration and filling holes
    % Here, we attempt to dilate the image with line structuring elements
    % to restore the border of the license plate for hole filling
    struc_temp = strel('line', 10,0);
    image_filled = imdilate(image_edge, struc_temp);
    struc_temp = strel('line', 3,90);
    image_filled = imdilate(image_filled, struc_temp);
    image_filled = imfill(image_filled, 'holes');
    %Eroding image to obtain major regions
    s2a = 40;
    s2a = round(h * 0.096);
    s2b = 65;
    s2b = round(w * 0.096);
    struc2 = strel('rectangle', [s2a,s2b]);
    image_erosion = imerode(image_filled, struc2);
    %Retrieving a list of the bounding boxes of major regions
    stats = regionprops(image_erosion, 'basic');
    [stats_len,~] = size(stats);
    image_license_identification = image_erosion;
    %Here, we decide on what the license plate region is. If we have only 1
    %major white region, we skip this step since there is only 1 path. If
    %there is 2 or mor major white regions, then the license plate is
    %usually the 2nd largest one since the largest is usually the vehicle
    %grill. We then colour every other white region
    %to black.
    pH = round(h * 0.95);
    pW = round(w * 0.5);
    if stats_len > 1
       ind = 1;
       %[~,dis] = pdist([stats(1).Centroid(1), stats(1).Centroid(2),pH,pW], 'euclidean');
       dis = sqrt(power(stats(1).Centroid(1)-pW,2) + power(stats(1).Centroid(2) - pH,2));
       for i = 2:stats_len
           curDis = sqrt(power(stats(i).Centroid(1)-pW,2) + power(stats(i).Centroid(2) - pH,2));
           if curDis < dis
              dis = curDis;
              ind = i;
           end
       end
       for i = 1:h
           for j = 1:w
               i_lower = stats(ind).BoundingBox(2);
               i_upper = stats(ind).BoundingBox(2)+ stats(ind).BoundingBox(4);
               j_lower = stats(ind).BoundingBox(1);
               j_upper = stats(ind).BoundingBox(1)+ stats(ind).BoundingBox(3);
               if i > i_lower && i < i_upper && j > j_lower && j < j_upper
                %image_erosion(i,j) = 1;
                  continue 
               end
               image_license_identification(i,j) = 0;
           end
       end
    end
    %This dilates the 1 white region to the size of the license plate
    s3a = 30;
    s3a = round(s2a*1.2);
    s3b = 60;
    s3b = round(s2b*1.7);
    struc3 = strel('rectangle', [s3a,s3b]);
    image_dilation = imdilate(image_license_identification, struc3);
    result = f;
    %This is the masking step
    for i = 1:h
       for j = 1:w
           if image_dilation(i,j) == 0
              result(i,j,:) = 0; 
           end
       end
    end
    %Graph display
    f = figure;
    f.Position = [0 0 1600 900];
    subplot(2,4,1), imshow(g), title('image grayscale');
    subplot(2,4,2), imshow(image_preprocessed), title('Pre-processing and binarization');
    subplot(2,4,3), imshow(image_edge), title('Edge detected image');
    subplot(2,4,4), imshow(image_filled), title('Slight dilation to enclose regions then filling holes');
    subplot(2,4,5), imshow(image_erosion), title('Erosion to filter license plate median reigon');
    subplot(2,4,6), imshow(image_license_identification), title('Attempt to identify license plate region');
    subplot(2,4,7), imshow(image_dilation), title('Dilation 2 to get back the entire license plate region');
    subplot(2,4,8), imshow(result), title('Mask application to original image');
end

