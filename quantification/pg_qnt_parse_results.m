% function [qNames, qTypes, qTable] = pg_qnt_parse_results(oQ)
function [qNames, qTypes, qTable] = pg_qnt_parse_results(params)
% [qNames, qTypes, qTable] = parseResults(oQ)
%%
[nSpots, nImg] = size(params.quant);
qTypes = zeros( nSpots, 24, nImg);
sp = params.spots(1).grdSpotPitch;
fposition = [params.spots.finalMidpoint]';
xPos = fposition(1:2:end);
yPos = fposition(2:2:end);
iposition = [params.spots.initialMidpoint]';
ixPos = iposition(1:2:end);
iyPos = iposition(2:2:end);
d = [xPos, yPos] - [ixPos, iyPos];
d = sqrt(sum(d.^2,2))/sp;
diameter = [params.spots.diameter]; 
for i = 1:nImg
 
    % here the qname, qvalue table is constructed 
    qTable =    {   'Row'               , params.grdRow'; 
                    'Column'            , params.grdCol'; 
                    'Mean_SigmBg'       , [params.quant(:,i).meanSignal]' - [params.quant(:,i).meanBackground]';
                    'Median_SigmBg'     , double([params.quant(:,i).medianSignal]')-double([params.quant(:,i).medianBackground]');
                    'Rse_MedianSigmBg'  , sqrt(([params.quant(:,i).rseSignal]').^2 + ([params.quant(:,i).rseBackground]').^2);
                    'Mean_Signal'       , [params.quant(:,i).meanSignal]'; 
                    'Median_Signal'     , [params.quant(:,i).medianSignal]'; 
                    'Std_Signal'        , [params.quant(:,i).stdSignal]'; 
                    'Sum_Signal'        , [params.quant(:,i).sumSignal]';
                    'Rse_Signal'        , [params.quant(:,i).rseSignal]';
                    'Mean_Background'   , [params.quant(:,i).meanBackground]'; 
                    'Median_Background' , [params.quant(:,i).medianBackground]'; 
                    'Std_Background'    , [params.quant(:,i).stdBackground]'; 
                    'Sum_Background'    , [params.quant(:,i).sumBackground]';
                    'Rse_Background'    , [params.quant(:,i).rseBackground]';
                    'Signal_Saturation' , [params.quant(:,i).signalSaturation]';
                    'Fraction_Ignored'  , [params.quant(:,i).fractionIgnored]'; 
                    'Diameter'          , diameter;
                    'X_Position'        , xPos;
                    'Y_Position'        , yPos;
                    'Position_Offset'   , d; 
                    'Empty_Spot'        , [params.quant(:,i).isEmpty]';  
                    'Bad_Spot'          , [params.quant(:,i).isBad]';
                    'Replaced_Spot'     , [params.segIsReplaced]'    };

    qNames = qTable(:,1);

    if nargin > 0
        for j=1:length(qNames)
            qTypes(:,j,i) = qTable{j,2};
        end
    else
        qTypes = [];
    end
end
