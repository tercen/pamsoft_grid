function oq = quantify(oq, I)
% function oq = quantify(oq, I)
% IN: 
% oq: array of spotQuantification objects (one for each spot) with relevant
% properties set 
% I: image to quantify
% OUT:
% oq: array of spotQuantification objects (corresponding to IN) contatining
% the quantification
for i=1:length(oq(:))
        if isempty(oq(i).oOutlier)
            bOut = false;
        else
            bOut = true;
        end
        idxSignal = get(oq(i).oSegmentation, 'bsTrue'); % foreground pixel index
        idxBackground = get(oq(i).oSegmentation, 'bbTrue');
        if ~isempty(idxSignal);
            sigPix = I(idxSignal); % vector of pixels making up the spot
            if bOut
                [iOutSignal, sigLimits] = detect(oq(i).oOutlier, double(sigPix));
            else
                iOutSignal = false(size(sigPix));
            end
            oq(i).medianSignal = median(sigPix(~iOutSignal));
            oq(i).meanSignal = mean(sigPix(~iOutSignal));
            oq(i).sumSignal  = sum(sigPix(~iOutSignal));
            % As of R2007A std does not support integer data
            oq(i).stdSignal = std(single(sigPix(~iOutSignal))); 
            nsg = length(sigPix(~iOutSignal));
            oq(i).rseSignal = (oq(i).stdSignal/sqrt(nsg))/oq(i).meanSignal;
            oq(i).minSignal = min(sigPix(~iOutSignal));
            oq(i).maxSignal = max(sigPix(~iOutSignal));
            % quantify background
        
            bgPix = I(idxBackground);
          
            if bOut    
                [iOutBackground, bgLimits] = detect(oq(i).oOutlier, double(bgPix));
            else
                iOutBackground = false(size(bgPix));
            end
            oq(i).medianBackground    = median(bgPix(~iOutBackground));
            oq(i).meanBackground      = mean(bgPix(~iOutBackground));
            oq(i).sumBackground       = sum(bgPix(~iOutBackground));
            oq(i).stdBackground       = std(single(bgPix(~iOutBackground)));
            oq(i).minBackground       = min(bgPix(~iOutBackground));
            oq(i).maxBackground       = max(bgPix(~iOutBackground));
            nbg = length(bgPix(~iOutBackground));
            oq(i).rseBackground = (oq(i).stdBackground/sqrt(nbg))/oq(i).meanBackground;            
            % set ignored pixels
            oq(i).iIgnored = [];
            if bOut
                idxSigIgnored = idxSignal(iOutSignal);
                idxBgIgnored =  idxBackground(iOutBackground);
                oq(i).iIgnored = union(idxSigIgnored, idxBgIgnored);
                oq(i).fractionIgnored = length(oq(i).iIgnored)/(length(sigPix ) + length(bgPix));
            end
            nPix = length(sigPix(~iOutSignal));
            oq(i).signalSaturation = length(find(sigPix(~iOutSignal) >= oq(i).saturationLimit))/nPix;     
        else
            % no spot found
            oq(i).medianSignal      = NaN;
            oq(i).meanSignal        = NaN;
            oq(i).sumSignal         = NaN;
            oq(i).stdSignal         = NaN; 
            oq(i).rseSignal         = NaN;
            oq(i).minSignal         = NaN;
            oq(i).maxSignal         = NaN;
            oq(i).medianBackground  = NaN;
            oq(i).meanBackground    = NaN;
            oq(i).sumBackground     = NaN;
            oq(i).stdBackground     = NaN;
            oq(i).minBackground     = NaN;
            oq(i).maxBackground     = NaN;
            oq(i).rseBackground     = NaN;
            oq(i).iIgnored          = NaN;
            oq(i).fractionIgnored   = NaN;
            oq(i).signalSaturation  = NaN;
        end
end

    







