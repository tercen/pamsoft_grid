function [x,y] = getOutline(oS, varargin)
opdef.coordinates = {'global', 'local'};
op = setVarArginOptions(opdef, [], varargin{:});

if isequal(op.coordinates, 'local')
    mp = localMidpoint(oS);
else
    mp = oS.finalMidpoint;
end

x = [];
y = [];
r = oS.diameter/2;
if ~isempty(r)
    [x,y] = circle(mp(1), mp(2), r, round(2*pi*r));
end





        

