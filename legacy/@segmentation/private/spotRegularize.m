function s = spotRegularize(s, bReplace)
% Checks the found segmentation for properties
% Replaces by dft spot if necessary.
%1 Check if there;s an object at the center of the spotArea

if nargin == 1
    bReplace = 1;
end


[nRows, nCols] = size(s.spots);
classifier = s.classifier;

 se = strel('disk', round(s.dftSpotDiameter/2) );
 dftSpot = getnhood(se);
 sDftSpot = size(dftSpot);

 for i=1:nRows
    for j=1:nCols
        

        L = bwlabel(s.spots(i,j).binSpot);
        sHok = size(s.spots(i,j).binSpot);
        mp = round(sHok/2);   
        
        
        % check whether the object found is within pixFlexibility from
        % ideal position
        if s.pixFlexibility <= 1
            nObject = L(mp(1), mp(2));
        else
            se = strel('disk' , s.pixFlexibility-1);
            disk = getnhood(se);
            mpDisk = size(disk)/2;
            [xDisk, yDisk] = find(disk);
            c  =round( [xDisk, yDisk] - repmat(mpDisk,length(xDisk),1) + repmat(mp,length(xDisk),1) );
            lc = sub2ind(size(L), c(:,1), c(:,2));
            nObject = any(L(lc));
            
            
            
        end
        
        
        
        s.spots(i,j).isSpot = 1;

        if nObject
            s.spots(i,j).binSpot = false(sHok);
            s.spots(i,j).binSpot(L == nObject) = 1;
        else
            s.spots(i,j).isSpot = 0;
            s.spots(i,j).Diameter = 0;
            s.spots(i,j).AspectRatio = 0;
            s.spots(i,j).Centroid = 0;
            s.spots(i,j).FormFactor = 0;
        end

        % 2. get metrics
        if s.spots(i,j).isSpot
            metrics             = regionprops(double(s.spots(i,j).binSpot), 'MajorAxisLength', 'MinorAxisLength', 'Perimeter', 'Area', 'Centroid');
            s.spots(i,j).Diameter       = metrics.MajorAxisLength;
            s.spots(i,j).AspectRatio    = metrics.MajorAxisLength/metrics.MinorAxisLength;
            s.spots(i,j).Centroid       = metrics.Centroid;
            if metrics.Perimeter
                s.spots(i,j).FormFactor     = (metrics.Area * 4*pi )/(metrics.Perimeter)^2;
            else
                s.spots(i,j).FormFactor    = 0;
            end
            
            % 3. check against classifier
           
            fNames = fieldnames(classifier);
            for n=1:length(fNames)
                strName = fNames{n};

                if isequal(strName(1:3), 'min')
                    p = -1;
                elseif isequal(strName(1:3), 'max');
                    p = 1;
                else
                    p = 0;
                end

                if isfield(s.spots(i,j), strName(4:end))
                    propVal = s.spots(i,j).(strName(4:end));
                    if p*propVal > p*classifier.(strName)
                        s.spots(i,j).isSpot = 0;
                    end
                end
            end
        end

        % 4. if necessary, replace by dft spot
        
        if ~s.spots(i,j).isSpot && bReplace
           
            s.spots(i,j).binSpot = false(sHok);
            mp = sHok/2;
            lu = 1 + round(mp - sDftSpot/2);
            s.spots(i,j).binSpot(lu(1):-1 + lu(1)+sDftSpot(1), lu(2):-1 + lu(2)+sDftSpot(2)) = dftSpot;
        end


    end
end

        