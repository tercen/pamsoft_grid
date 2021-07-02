function varargout = vSetGlobalStats(g, v, strID, qType, bOutput);
% function vSetGlobalStats(v, clID, qType, <bOutput>)

if nargin < 4
    bOutput = false;
end
uID = vGetUniqueID(v, 'ID');
iMatch = strmatch(strID, uID);
clID = uID(iMatch);
 if isempty(clID)
     error('GlobalStats:IDNotFound', '%s', ['ID not found: ', strID]);
 end
 
[refMaps, msg] = vArrange(v, 'ID', clID, qType, 'Maps');
bw = repmat(g.badWells,[1,1,size(refMaps,3)]);
refMaps(bw) = -0.01;

if msg ~= 0
    error('GlobalStats:vArrange', '%s', msg);
end

    
mRefMaps = mean(refMaps,3);
[s1, s2, s3] = size(refMaps);
mIndex1 = vArrange(v, 'ID', clID(1), 'Index1');
mIndex2 = vArrange(v, 'ID', clID(1), 'Index2');

vIndex1 = reshape(mIndex1, s1*s2,1);
vIndex2 = reshape(mIndex2, s1*s2,1);
vRefs   = reshape(refMaps, s1*s2,s3);

% get rid of any possible NaN

j = 0;
for i=1:(s1*s2)
    if isempty(find(isnan(vRefs(i,:))))
        j = j+1;
        vIn(j,:) = vRefs(i,:);
        rIn(j) = i;
    end
end
[localT, localCV, globalCVAll, globalCVFiltered, nFiltered, hFig] = getGlobalStats(g, vIn,bOutput, strID);
% remap
for i=1:length(localT)
    vLocalT(rIn(i)) = localT(i);
    vLocalCV(rIn(i)) = localCV(i);
end

% remap results to the v-file
for i=1:length(v)
    ind1 = v(i).Index1;
    ind2 = v(i).Index2;
    iMatch1 = find(vIndex1 == ind1);
    iMatch2  = find(vIndex2(iMatch1) == ind2);
    iMatch = iMatch1(iMatch2);
    
    
    if (g.bLocalT)
        v(i).localT = vLocalT(iMatch);
    end
    if (g.bLocalCV)
        v(i).localCV = vLocalCV(iMatch);
    end
end
varargout{1} = v;
if (g.bGlobalMetrics)
    vGen.globalCVAll = globalCVAll;
    vGen.globalCVFiltered = globalCVFiltered;
    vGen.nFiltered = nFiltered;
    varargout{2} = vGen;
end

% add plate overview to output graph
if (hFig)
    figure(hFig);
    subplot(2,2,4);
    imagesc(mRefMaps);
end



        


    
