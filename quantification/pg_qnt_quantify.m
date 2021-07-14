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
        %         idxSignal = get(oq(i).oSegmentation, 'bsTrue'); % foreground pixel index
        idxSignal = spot.bsTrue;
        %         idxBackground = get(oq(i).oSegmentation, 'bbTrue');
        idxBackground = spot.bbTrue;
        
        
        
        if ~isempty(idxSignal)
            sigPix = I(idxSignal); % vector of pixels making up the spot
            if bOut
                %                 [iOutSignal, sigLimits] = detect(oq(i).oOutlier, double(sigPix));
                [iOutSignal, ~, ~] = pg_seg_detect_outlier(double(sigPix), params);
            else
                iOutSignal = false(size(sigPix));
            end
            quant(i,k).medianSignal = median(sigPix(~iOutSignal));
            quant(i,k).meanSignal = mean(sigPix(~iOutSignal));
            
%             if i == 148
%                fprintf('%.5f\n',mean(sigPix(~iOutSignal)));
%              end
            
%             legacy = load('/media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/test/legacy.mat');
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
                %                 [iOutBackground, bgLimits] = detect(oq(i).oOutlier, double(bgPix));
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
            quant(i,k).signalSaturation = length(find(sigPix(~iOutSignal) >= params.qntSaturationLimit))/nPix;
        else
            % no spot found
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

% Parse results


% 
% qTable =    {   'Row'               , [oQ.arrayRow]'; 
%                 'Column'            , [oQ.arrayCol]'; 
%                 'Mean_SigmBg'       , [oQ.meanSignal]' - [oQ.meanBackground]';
%                 'Median_SigmBg'     , double([oQ.medianSignal]')-double([oQ.medianBackground]');
%                 'Rse_MedianSigmBg'  , sqrt(([oQ.rseSignal]').^2 + ([oQ.rseBackground]').^2);
%                 'Mean_Signal'       , [oQ.meanSignal]'; 
%                 'Median_Signal'     , [oQ.medianSignal]'; 
%                 'Std_Signal'        , [oQ.stdSignal]'; 
%                 'Sum_Signal'        , [oQ.sumSignal]';
%                 'Rse_Signal'        , [oQ.rseSignal]';
%                 'Mean_Background'   , [oQ.meanBackground]'; 
%                 'Median_Background' , [oQ.medianBackground]'; 
%                 'Std_Background'    , [oQ.stdBackground]'; 
%                 'Sum_Background'    , [oQ.sumBackground]';
%                 'Rse_Background'    , [oQ.rseBackground]';
%                 'Signal_Saturation' , [oQ.signalSaturation]';
%                 'Fraction_Ignored'  , [oQ.fractionIgnored]'; 
%                 'Diameter'          , diameter;
%                 'X_Position'        , xPos;
%                 'Y_Position'        , yPos;
%                 'Position_Offset'   , d; 
%                 'Empty_Spot'        , [oQ.isEmpty]';  
%                 'Bad_Spot'          , [oQ.isBad]';
%                 'Replaced_Spot'      ,[oQ.isReplaced]'};

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









