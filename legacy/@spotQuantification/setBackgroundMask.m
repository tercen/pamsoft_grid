function oq = setBackgroundMask(oq)
if isempty(oq.oSegmentation)
    error('Segmentation object has not been set');
end


switch oq.backgroundMethod
    case 'localCorner'
        oq.iBackground = localCornerMask(oq);
end
