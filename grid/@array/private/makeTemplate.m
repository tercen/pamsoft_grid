function template = makeTemplate(g, imageSize)
% function Template = makeTemplate(g, imageSize)

template = false(imageSize(1), imageSize(2), length(g.rotation));

% if no offsets defines, set all to zero:
if isempty(g.xOffset)
    g.xOffset = zeros(size(g.row));
end
if isempty(g.yOffset)
    g.yOffset = zeros(size(g.row));
end
% select the designated references
% note that row and col are reversed here

% useRow = g.col(g.isreference);
% useCol = g.row(g.isreference);
r = round(g.spotSize/2);
mp      = round(0.5 * imageSize);



imSpot = zeros(round(2.1*r));
sImSpot = round(size(imSpot)/2);
[xCircle, yCircle] = circle(round(size(imSpot)/2), r, round(2*pi*r));
[ix, iy] = find(~imSpot);
bIn = inpolygon(ix, iy, xCircle, yCircle);
% get the disk coordinates, centered around [0,0];
xDisk = ix(bIn) - sImSpot(1);
yDisk = iy(bIn) - sImSpot(2);

% make a template for all required rotations:
for i =1:length(g.rotation)
    temp = false(size(template(:,:,1)));
    set1 = g.row > 0 & g.col > 0;
   
    if any(set1(logical(g.isreference)));
        [x1,y1] = gridCoordinates(g.row(set1), g.col(set1),g.xOffset(set1), g.yOffset(set1), mp, g.spotPitch, g.rotation(i), g.isreference(set1));        
        for j=1:length(x1)
            cSpot = [xDisk + x1(j), yDisk + y1(j)];
            temp(sub2ind(size(temp), round(cSpot(:,1)), round(cSpot(:,2))) ) = true;
        end
    end    
    set2 = g.row < 0 & g.col < 0;
    if any(set2(logical(g.isreference)));
        [x2,y2] = gridCoordinates(g.row(set2), g.col(set2),g.xOffset(set2), g.yOffset(set2), mp, g.spotPitch, g.rotation(i), g.isreference(set2)); 
        for j=1:length(x2)
            cSpot = [xDisk + x2(j), yDisk + y2(j)];
            temp(sub2ind(size(temp), round(cSpot(:,1)), round(cSpot(:,2))) ) = true;
        end
        
    end
    template(:,:,i) = temp;
end



