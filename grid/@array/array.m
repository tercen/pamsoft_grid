function g = array(varargin)
% array.array
% function oArray = array(varargin)
% This is the constructor for class array.
% See matlab documentation on object oriented programming
%
% oArray = array() returns an array object
% oArray = array(oArray), where oArray is an array object, returns a copy of oArray
% oArray = array('prop1', 'val1', 'prop2', 'val2', ...) returns an array object
% with prop1 set to val1 etc.  
%
% To retrieve a property use the array.get method:
% val = get(oArray, 'prop');
% get(oArray) will return all oArray properties as the corresponding
% structure.
%
% To set properties use the array.set method:
% oArray = set(oArray, 'prop1', val1, 'prop2', 'val2, ...
% 
% array properties:
% row: n-element vector with row indices of spots in the array
% col: n-element vector with column indices of spots in an array
% A second grid around the same midpoint as the first grid may be defined
% using negative indices.(see also http://psp.pamgene.com:8080/PamWorld/870)
%
% isreference: n-element logical vector with true for those spots that are
% to be used as position references (corresponding to row and col)
%
% spotPitch: 2 element vector, set to xPitch and yPitch of the spots in the array in pixels
%           If xPitch == yPitch spotPitch may be set a a scalar.
%
% spotSize: scalar, set to approximate diameter of the spots in the array in pixels
%
% xOffset, yOffset n-element vector containing y,x (respectively) offsets from ideal
% in units spotPitch (for spots corresponding to row and col)
%   xOffset(i,j) = -0.5 means x coordinate of point X 0.5 a pitch to the
%   left. 
%   When xOffset, or yOffset are left empty the grid will dft to
%   zeros(nRows, nCols);
% 
% ID: n-element cell array of strings containing ID's for the spots
% corresponding to row and col
% rotation: vector, (dft: 0) , use to set the possible rotations in degrees of the array to be probed.
%
%
%(note, the more rotations, the slower the grid finding)
% method: string, one method currently supported (dft: 'correlation2D')
% EXAMPLE:
% To define an 4 x 4 array with grid references on the corner, a spotSize
% of 10 pixels, a spotPitch of 15 pixels.
% oArray = array();
% row = [1,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4]';
% col = [1,2,3,4,1,2,3,4,1,2,3,4,1,2,3,4]';
% isreference = false(size(col)); 
% isreference(1,1) = true; isreference(1,4) = true;
% isrefrence(4,1) = true; isrefrence(4,4) =true;
% % probe rotations between -2 and 2 degreesl, step 0.25;
% rot = [-2:0.2:2];
% oArray = set(oArray, 'col', col, ...
%                      'row', row, ...
%                      'isreference', isrefence, ...     
%                      'rotation', rot, ...
%                      'spotPitch', 15, ...
%                      'spotSize, 10); 
%
% array public member functions (ex get and set)
% See also array/gridFind, array/fromFile,
% http://psp.pamgene.com:8080/PamWorld/870

if length(varargin) == 1
    % copy input object to output object
    bIn = varargin{1};
    if isa(bIn, 'array');
        g = bIn;
        return;
    else
        error(['Cannot create array object from object of class ',class(bIn)]);
    end
end

g.row           = [];
g.col           = [];
g.isreference   = [];
g.xOffset       = [];
g.yOffset       = [];
g.xFixedPosition  = [];
g.yFixedPosition  = [];
g.ID            = [];
g.spotPitch      = [];
g.spotSize       = [];
g.rotation       =  0;
g.roiSearch      = [];
g.method         = 'correlation2D';
g.private        = struct([]);



g = class(g, 'array');
if length(varargin) > 1
    g = set(g, varargin{:});
end


