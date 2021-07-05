function [bBadPosition, bRunaway] = checkSpotPosition(q, maxPositionDelta)
% [bBadPosition, bRunaway] = checkSpotPosition(q, maxPositionDelta)
% Checks the position of spots in array of spotQuantification object q
% against maxPositionDelta, plus checks if analysis resulted in a runaway
% to a neighbouring spot
% [bBadPostion, logical of size(q), true if the absolute positions offset is larger
% than maxPositionDelta.
% [bRunaway, logical of size(q), true if a spot is a runaway (converged on
% neighbour)
% first get the position delta from the spotProperties

op = [q(:).oProperties];
sop = struct(op); 
posDelta = [sop.positionDelta]'; % vector of posDelta


% then find overlapping (runaway spots)
[x,y] = getPosition(q); % get the actual spot positions

D = distanceMap(x,y); % create a distance map between the positions
eps = 2; % max epsilon (pix)for calling positions equal

% a spot is a runaway when its positon delta is large and its positon
% overlaps with that of a neighbouring spot
bRunaway = repmat(posDelta,1, size(D,2)) > maxPositionDelta & D < eps; 
[i,j] = find(triu(bRunaway,1));
bRunaway = false(size(q));
bRunaway(j) = true;
bBadPosition = posDelta > maxPositionDelta;

