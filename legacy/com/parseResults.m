function [qNames, qTypes, qTable] = parseResults(oQ)
% [qNames, qTypes, qTable] = parseResults(oQ)
if nargin > 0
    oQ = get(oQ(:));
    oS = [oQ.oSegmentation];
    oS = get(oS);
    sp = oS(1).spotPitch;
    fposition = [oS.finalMidpoint]';
    xPos = fposition(1:2:end);
    yPos = fposition(2:2:end);
    iposition = [oS.initialMidpoint]';
    ixPos = iposition(1:2:end);
    iyPos = iposition(2:2:end);
    d = [xPos, yPos] - [ixPos, iyPos];
    d = sqrt(sum(d.^2,2))/sp;
    diameter = [oS.diameter];    
else
    oQ = get(spotQuantification);
    xPos = [];
    yPos = [];
    d = [];
    diameter = [];
end

%% here the qname, qvalue table is constructed 
qTable =    {   'Row'               , [oQ.arrayRow]'; 
                'Column'            , [oQ.arrayCol]'; 
                'Mean_SigmBg'       , [oQ.meanSignal]' - [oQ.meanBackground]';
                'Median_SigmBg'     , double([oQ.medianSignal]')-double([oQ.medianBackground]');
                'Rse_MedianSigmBg'  , sqrt(([oQ.rseSignal]').^2 + ([oQ.rseBackground]').^2);
                'Mean_Signal'       , [oQ.meanSignal]'; 
                'Median_Signal'     , [oQ.medianSignal]'; 
                'Std_Signal'        , [oQ.stdSignal]'; 
                'Sum_Signal'        , [oQ.sumSignal]';
                'Rse_Signal'        , [oQ.rseSignal]';
                'Mean_Background'   , [oQ.meanBackground]'; 
                'Median_Background' , [oQ.medianBackground]'; 
                'Std_Background'    , [oQ.stdBackground]'; 
                'Sum_Background'    , [oQ.sumBackground]';
                'Rse_Background'    , [oQ.rseBackground]';
                'Signal_Saturation' , [oQ.signalSaturation]';
                'Fraction_Ignored'  , [oQ.fractionIgnored]'; 
                'Diameter'          , diameter;
                'X_Position'        , xPos;
                'Y_Position'        , yPos;
                'Position_Offset'   , d; 
                'Empty_Spot'        , [oQ.isEmpty]';  
                'Bad_Spot'          , [oQ.isBad]';
                'Replaced_Spot'      ,[oQ.isReplaced]'};
                    
qNames = qTable(:,1);
if nargin > 0
    for i=1:length(qNames)
        qTypes(:,i) = qTable{i,2};
    end
else
    qTypes = [];
end




