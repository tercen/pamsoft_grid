function [template, params] = pg_make_template(params, imageSize)
% function Template = makeTemplate(g, imageSize)

template = false(imageSize(1), imageSize(2), length(params.grdRotation));

% if no offsets defines, set all to zero:
if isempty(params.grdXOffset)
    params.grdXOffset = zeros(size(params.grdRow));
end
if isempty(params.grdYOffset)
    params.grdYOffset = zeros(size(params.grdRow));
end
% select the designated references
% note that row and col are reversed here

% useRow = g.col(g.isreference);
% useCol = g.row(g.isreference);
r = round(params.grdSpotSize/2);
mp      = round(0.5 * imageSize);



imSpot   = zeros(round(2.1*r));
sImSpot  = round(size(imSpot)/2);
[xCircle, yCircle] = pg_circle(round(size(imSpot)/2), r, round(2*pi*r));
[ix, iy] = find(~imSpot);
bIn      = inpolygon(ix, iy, xCircle, yCircle);

% get the disk coordinates, centered around [0,0];
xDisk = ix(bIn) - sImSpot(1);
yDisk = iy(bIn) - sImSpot(2);

% make a template for all required rotations:
for i =1:length(params.grdRotation)
    temp = false(size(template(:,:,1)));
    set1 = params.grdRow > 0 & params.grdCol > 0;
   
    if any(set1(logical(params.grdIsReference)))
        [x1,y1] = pg_grid_coordinates(params.grdRow(set1), params.grdCol(set1), ...
            params.grdXOffset(set1), params.grdYOffset(set1), mp, params.grdSpotPitch, ...
            params.grdRotation(i), params.grdIsReference(set1));        
        
        for j=1:length(x1)
            cSpot = [xDisk + x1(j), yDisk + y1(j)];
            temp(sub2ind(size(temp), round(cSpot(:,1)), round(cSpot(:,2))) ) = true;
        end
    end    
    set2 = params.grdRow < 0 & params.grdCol < 0;
    if any(set2(logical(params.grdIsReference)))
        [x2,y2] = pg_grid_coordinates(params.grdRow(set2), params.grdCol(set2), ...
            params.grdXOffset(set2), params.grdYOffset(set2), mp, params.grdSpotPitch, ...
            params.grdRotation(i), params.grdIsReference(set2)); 
        
        for j=1:length(x2)
            
            cSpot = [xDisk + x2(j), yDisk + y2(j)];
            
            temp(sub2ind(size(temp), round(cSpot(:,1)), round(cSpot(:,2))) ) = true;
        end
        
    end
    template(:,:,i) = temp;
end



