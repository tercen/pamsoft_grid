% function oq = quantify(oq, I)
function [params, exitCode] = pg_qnt_quantify( params )
% function oq = quantify(oq, I)
% IN:
% oq: array of spotQuantification objects (one for each spot) with relevant
% properties set
% I: image to quantify
% OUT:
% oq: array of spotQuantification objects (corresponding to IN) contatining
% the quantification
% for i=1:length(oq(:))
% I     = params.images;
exitCode = 0;
quant = internal_create_empty_quant_struct();
quant = repmat( quant, length(params.spots), size(params.images,3) );

for k = 1:size(quant,2)
    
    I = squeeze( params.images(:,:,k) );
    for i = 1:length(params.spots)
        
        spot = params.spots(i);
        % @FIXME MAYBE OUTLIERS ARE NOT BEING SAVE IN THE LEGACY CODE
        % In the tests, all spots were marked as outliers...
        
        bOut = true;%logical(params.segOutliers(i));
        %         if isempty(oq(i).oOutlier)
        %             bOut = false;
        %         else
        %             bOut = true;
        %         end
        idxSignal = spot.bsTrue;
        idxBackground = spot.bbTrue;
% 
%         
%         if ~isempty(idxSignal)
%             sigPix = I(idxSignal); 
%             [iOutSignal, ~, ~] = pg_seg_detect_outlier(double(sigPix), params);
%         end
%         
        
        if ~isempty(idxSignal) 
%&& ~isempty(iOutSignal)
%%
            sigPix = I(idxSignal); % vector of pixels making up the spot
            
                
%  bgPix = I(idxBackground);
% clf;
% I_ = I;
% I_(idxBackground) = 0;
% I_(idxSignal) = 5000;
% imagesc(I_);
% disp('.');
%   [iOutSignal, ~, ~] = pg_seg_detect_outlier(double(sigPix), params);
%  [iOutBackground, ~, ~] = pg_seg_detect_outlier(double(bgPix), params);

%             end
% median(sigPix(~iOutSignal))- median(bgPix(~iOutBackground))
% 332
%%
            if bOut
                [iOutSignal, ~, ~] = pg_seg_detect_outlier(double(sigPix), params);
            else
                iOutSignal = false(size(sigPix));
            end



            quant(i,k).medianSignal = median(sigPix(~iOutSignal));
            quant(i,k).meanSignal = mean(sigPix(~iOutSignal));
            

            quant(i,k).sumSignal  = sum(sigPix(~iOutSignal));
            % As of R2007A std does not support integer data
            quant(i,k).stdSignal = std(single(sigPix(~iOutSignal)));
            nsg = length(sigPix(~iOutSignal));
            quant(i,k).rseSignal = (quant(i,k).stdSignal/sqrt(nsg))/quant(i,k).meanSignal;
            quant(i,k).minSignal = min(sigPix(~iOutSignal));
            quant(i,k).maxSignal = max(sigPix(~iOutSignal));
            % quantify background
            
            bgPix = I(idxBackground);
            
            
            if bOut
                [iOutBackground, ~, ~] = pg_seg_detect_outlier(double(bgPix), params);
            else
                iOutBackground = false(size(bgPix));
            end
            quant(i,k).medianBackground    = median(bgPix(~iOutBackground));
            quant(i,k).meanBackground      = mean(bgPix(~iOutBackground));
            quant(i,k).sumBackground       = sum(bgPix(~iOutBackground));
            quant(i,k).stdBackground       = std(single(bgPix(~iOutBackground)));
            quant(i,k).minBackground       = min(bgPix(~iOutBackground));
            quant(i,k).maxBackground       = max(bgPix(~iOutBackground));
            nbg = length(bgPix(~iOutBackground));
            quant(i,k).rseBackground = (quant(i,k).stdBackground/sqrt(nbg))/quant(i,k).meanBackground;
            % set ignored pixels
            quant(i,k).iIgnored = [];
            if bOut
                idxSigIgnored = idxSignal(iOutSignal);
                idxBgIgnored =  idxBackground(iOutBackground);
                quant(i,k).iIgnored = union(idxSigIgnored, idxBgIgnored);
                quant(i,k).fractionIgnored = length(quant(i,k).iIgnored)/(length(sigPix ) + length(bgPix));
            end
            nPix = length(sigPix(~iOutSignal));
            disp(params.qntSaturationLimit)
%             disp('........');
%             disp(sigPix(~iOutSignal))
            if any(iOutSignal) && any(sigPix) && ~isstruct(sigPix(~iOutSignal) )
                quant(i,k).signalSaturation = length(find(sigPix(~iOutSignal) >= params.qntSaturationLimit))/nPix;
            else
                quant(i,k).signalSaturation = 0;
            end
        else
            % no spot found
% %%
% clf;
% I_ = I;
% I_(idxBackground) = 0;
% imagesc(I_);
% %%

            quant(i,k).medianSignal      = NaN;
            quant(i,k).meanSignal        = NaN;
            quant(i,k).sumSignal         = NaN;
            quant(i,k).stdSignal         = NaN;
            quant(i,k).rseSignal         = NaN;
            quant(i,k).minSignal         = NaN;
            quant(i,k).maxSignal         = NaN;
            quant(i,k).medianBackground  = NaN;
            quant(i,k).meanBackground    = NaN;
            quant(i,k).sumBackground     = NaN;
            quant(i,k).stdBackground     = NaN;
            quant(i,k).minBackground     = NaN;
            quant(i,k).maxBackground     = NaN;
            quant(i,k).rseBackground     = NaN;
            quant(i,k).iIgnored          = NaN;
            quant(i,k).fractionIgnored   = NaN;
            quant(i,k).signalSaturation  = NaN;
        end
    end
end

params.quant = quant;


end

function quantStruct = internal_create_empty_quant_struct()
quantStruct = struct( 'medianSignal', NaN, ...
    'meanSignal', NaN, ...
    'sumSignal', NaN, ...
    'stdSignal', NaN, ...
    'rseSignal', NaN, ...
    'minSignal', NaN, ...
    'maxSignal', NaN, ...
    'meanBackground', NaN, ...
    'sumBackground', NaN, ...
    'stdBackground', NaN, ...
    'rseBackground', NaN, ...
    'minBackground', NaN, ...
    'maxBackground', NaN, ...
    'iIgnored', NaN, ...
    'fractionIgnored', NaN, ...
    'signalSaturation', NaN );



end









