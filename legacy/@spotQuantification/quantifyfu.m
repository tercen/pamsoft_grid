function oq = quantify(oq, I)
% function oq = quantify(oq, I)
% IN: 
% oq: array of spotQuantification objects (one for each spot) with relevant
% properties set 
% I: image to quantify
% OUT:
% oq: array of spotQuantification objects (corresponding to IN) contatining
% the quantification


%[nRows, nCols] = size(oq); % this is obsolete, the double loop over nRow and nCols can (will) be replaced by a single loop over length(oq(:))

for i=1:length(oq(:))
   
        % this sets the mask for the background pixels
        % (spotQuantification.setBackgroundMask method)
        if isempty(oq(i).iBackground)
            oq(i) = setBackgroundMask(oq(i));
        end
        
        if isempty(oq(i).oOutlier)
            bOut = false;
        else
            bOut = true;
        end

        % get the foreground pixel mask from the segmentation    
        bwSignal= getBinSpot(oq(i).oSegmentation);
        if any(bwSignal(:))
         
           
            % imLocal is the image "zoomed" around the spot
            imLocal = localImage(oq(i).oSegmentation, I);
            
            % quantify signal
            sigPix = imLocal(bwSignal); % array of pixles making up the spot
            if bOut
                [iOutSignal, sigLimits] = detect(oq(i).oOutlier, double(sigPix));
            else
                iOutSignal = false(size(sigPix));
            end
            oq(i).medianSignal = median(sigPix(~iOutSignal));
            oq(i).meanSignal = mean(sigPix(~iOutSignal));
            % As of R2007A std does not support integer data
            oq(i).stdSignal = std(single(sigPix(~iOutSignal))); 
            
            oq(i).minSignal = min(sigPix(~iOutSignal));
            oq(i).maxSignal = max(sigPix(~iOutSignal));
            % quantify background
            bgPix = imLocal(oq(i).iBackground);
            if bOut    
                [iOutBackground, bgLimits] = detect(oq(i).oOutlier, double(bgPix));
            else
                iOutBackground = false(size(bgPix));
            end
            oq(i).medianBackground    = median(bgPix(~iOutBackground));
            oq(i).meanBackground      = mean(bgPix(~iOutBackground));
            oq(i).stdBackground       = std(single(bgPix(~iOutBackground)));
            oq(i).minBackground       = min(bgPix(~iOutBackground));
            oq(i).maxBackground       = max(bgPix(~iOutBackground));
            % set ignored pixels
            oq(i).iIgnored = [];
            if bOut
                sigIgnored = bwSignal & (imLocal < sigLimits(1) | imLocal > sigLimits(2));
                bgMask = getBackgroundMask(oq(i)); 
                bgIgnored =  bgMask &  (imLocal < bgLimits(1) | imLocal > bgLimits(2));
                oq(i).iIgnored = find( sigIgnored(:)|bgIgnored(:) );
                oq(i).fractionIgnored = length(oq(i).iIgnored)/length(sigIgnored(:));
            end
            % for the rank test:
            % since pixel intensities are integer, we can handle the ties
            % in MW test below by adding 0.5 to one of the
            % distributions (here: sigPix)
            %oq(i,j).pSignal = test2r(double(sigPix(~iOutSignal))+0.5, double(bgPix(~iOutBackground)), 'n');
            %oq(i).pSignal = ranksum(double(sigPix(~iOutSignal))+0.5, double(bgPix(~iOutBackground)), 'method', 'approximate');
            
            nPix = length(sigPix(~iOutSignal));
            oq(i).signalSaturation = length(find(sigPix(~iOutSignal) >= oq(i).saturationLimit))/nPix;     
            oq(i).dipole = corr(zscore(double(bwSignal(:))), zscore(double(imLocal(:))), 'type', 'spearman');
            oq(i).pSignal = corr(zscore(double(bgMask(:))), zscore(double(imLocal(:))), 'type', 'spearman');
        end
end


%%%%%%%%%%%%%%
    







