function [Map, Message] = vArrange(v, strIDField, fID, strValField, optOut)
% function [Map, Message] = vArrange(v, strIDField, fID, strValField, <optOut>)
% retrieve measurement defined by strValField from vecs (spots)  identified
% by fID in strIDField (see vMap96)
% vArrange96 can retrieve values for multiple IDs if fID is cell array of string or a char matrix
% Arrangement of output for N multiple IDs can be controlled by setting
% the string optOut:
% 'Maps' (default): Map is a 8x12xN array containing a map for each
%  ID
% 'Average': Map is a 8x12 array containing the average of the requested IDs for each [MWRow, MWCol]
% 'Std': see Average, but standard deviation
% 'Columns': Map is a 8 x 12N array with the cols of the multiple IDs
%  next to each other: Map =  [ [rep1(:,1), rep2(:,1), ... repN(:,1)], ...., [rep1(:,12),rep2(:,12), repN(:,12)] ]
%  
% EXAMPLE:
% clList = vPick(v, 'ID');
% out = vArrange96(v, 'ID', clList, 'Vini', 'Columns');
% if in clList two IDs are selected out will be a 8x24 array with the Vini for the two arrays organized in columns
% SEE: vMap96, vPick


fldNames = fieldnames(v);
Map = [];
Message = 0;
% check if the rquested fields exists
if isempty(strmatch(strIDField, fldNames, 'exact') )
    Message = ['input structure v does not have the requested field: ',strIDField];
    return;
end
if isempty(strmatch(strValField, fldNames, 'exact') )
    Message = ['input structure v does not have the requested field: ',strValField];
    return;
end
if (iscell(fID))
    fID = char(fID);
end
sID = size(fID);
%Map = ones(8,12,sID(1));

for n=1:sID(1)
    [mout, Message] = vMap(v, strIDField, fID(n,:), strValField);
    if isempty(mout)
        Map = [];
        return;
    end
    Map(:,:,n) = mout;    
end
if (nargin < 5)
    optOut = 'Maps';
end

[s1,s2,s3] = size(Map);
switch optOut
    case('Average')
        Map = mean(Map,3);
    case('Std')
        Map = std(Map,0,3);    
    case('Columns')
        ColMap = [];
        for i =1:s2
            ColMap = [ColMap, squeeze(Map(:,i,:))];
        end
        Map = ColMap;
    case('V')
        Map = reshape(Map, s1*s2, s3);
    case('AV')
        Map = mean(Map, 3);
        Map = reshape(Map, s1*s2, 1);
   case('AVT')
        Map = mean(Map, 3)';
        Map = reshape(Map, s1*s2, 1);
    case('Maps')
        % do nothing
    otherwise
        error('Unknown option for optOut');
end

        
            
        
        
    