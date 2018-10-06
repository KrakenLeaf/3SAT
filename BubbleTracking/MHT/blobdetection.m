function [] = blobdetection(foreground)
fg = foreground; % do foreground extraction
cmap = colormap(gray);

for i=1:length(fg)
    fg{i} = rgb2gray(fg{i});
end

for i = 1:length(fg)
    temp0{i} = edge(fg{i}, 'canny', 0.99) + fg{i};
    temp2 = temp0{i};
    temp2 = cat(3,temp2,temp2,temp2);
    
    fgs = rgb2gray(temp2);
    sedisk = strel('square',10);
    fgs = imclose(fgs, sedisk);
    fgs = imfill(fgs,'holes');
    RLL = bwlabel(fgs);
    
    stats = regionprops(RLL,'basic','Centroid');
    fig = figure(1),imshow(RLL)
    hold on
    
    for n = 1:length(stats)
        if(stats(n).Area > 100)
            plot(stats(n).Centroid(1), stats(n).Centroid(2),'r*')
        end
    end
    hold off
end;

return
