
function [qNames, qTypes, qTable] = pg_qnt_parse_results(params)

[nSpots, nImg] = size(params.quant);
qTypes         = zeros( nSpots, 17, nImg);



sp        = params.spots(1).grdSpotPitch;
fposition = [params.spots.finalMidpoint]';
 
xPos = fposition(1:2:end);
yPos = fposition(2:2:end);
 
% iposition = [params.spots.initialMidpoint]';
% 
% ixPos = iposition(1:2:end);
% iyPos = iposition(2:2:end);
% 
% d        = [xPos, yPos] - [ixPos, iyPos];
% d        = sqrt(sum(d.^2,2))/sp;
diameter = [params.spots.diameter]';


% ds4.Rse_Background	0
% ds4.Rse_MedianSigmBg	0
% ds4.Rse_Signal	0
% ds4.Std_Background	0
% ds4.Std_Signal	0
% ds4.Sum_Background	0
% ds4.Sum_Signal	0
rows = params.grdRow;
cols = params.grdCol;

if size(rows, 1) < size(rows,2), rows = rows'; end
if size(cols, 1) < size(cols,2), cols = cols'; end
if size(params.segIsReplaced , 1) < size(params.segIsReplaced ,2), params.segIsReplaced  = params.segIsReplaced'; end
for i = 1:nImg

    qTable =    {   ...
        'Row'               , rows;
        'Column'            , cols;
        'Mean_SigmBg'       , [params.quant(:,i).meanSignal]' - [params.quant(:,i).meanBackground]';
        'Median_SigmBg'     , double([params.quant(:,i).medianSignal]')-double([params.quant(:,i).medianBackground]');
        'Mean_Signal'       , [params.quant(:,i).meanSignal]';
        'Median_Signal'     , [params.quant(:,i).medianSignal]';
        'Mean_Background'   , [params.quant(:,i).meanBackground]';
        'Median_Background' , [params.quant(:,i).medianBackground]';
        'Signal_Saturation' , [params.quant(:,i).signalSaturation]';
        'Fraction_Ignored'  , [params.quant(:,i).fractionIgnored]';
        'Diameter'          , diameter;
        'gridX'             , xPos;
        'gridY'             , yPos;
        'Position_Offset'   , diameter;
        'Empty_Spot'        , [params.quant(:,i).isEmpty]';
        'Bad_Spot'          , [params.quant(:,i).isBad]';
        'Replaced_Spot'     , [params.segIsReplaced ]   };
    
    qNames = qTable(:,1);
    
    if nargin > 0
        for j=1:length(qNames)
            qTypes(:,j,i) = qTable{j,2};
        end
    else
        qTypes = [];
    end
    [~,imageName,~] = fileparts( params.imageslist{i} );
%     disp(qTable{1,2})
    


try
    tbl = table(...
        qTable{1,2}, ...
        qTable{2,2}, ...
        qTable{3,2}, ...
        qTable{4,2}, ...
        qTable{5,2}, ...
        qTable{6,2}, ...
        qTable{7,2}, ...
        qTable{8,2}, ...
        qTable{9,2}, ...
        qTable{10,2}, ...
        qTable{11,2}, ...
        qTable{12,2}, ...
        qTable{13,2}, ...
        qTable{14,2}, ...
        qTable{15,2}, ...
        qTable{16,2}, ...
        qTable{17,2}, ...
    repmat(imageName, nSpots, 1) );
catch err
    disp(qTable)
    error(err.message)
    end
    %         qNames_=qNames;
    %     qNames{1}='ROW';
    qNames{end+1} = 'ImageName';
    
    %     tbl.Properties.VariableNames = qNames;
    if i == 1
        if exist(params.outputfile, 'file')
            delete( params.outputfile );
        end
        fid = fopen(params.outputfile, 'w');
        for qi = 1:length(qNames)
            fprintf(fid, '%s', qNames{qi});

            if qi < length(qNames)
                fprintf(fid, ',');
            end
        end
            
        fclose(fid);
        
    end
    
    
    writetable(tbl, params.outputfile,'WriteRowNames',false, ...
        'QuoteStrings',true,'WriteMode','Append');
    
end
end
