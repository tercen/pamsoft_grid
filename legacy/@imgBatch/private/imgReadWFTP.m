    function stRes = imgReadWFTP(baseName)
    % function [arrayID, filter, integrationTime, pumpCycle, chipID,
    % sampleID] = imgReadWFTP(baseName, sInstrument)
    % note that chipID and sampleID may be empty on return.
    
    stRes.W  = [];
    stRes.F = [];
    stRes.T = [];
    stRes.P = [];
    stRes.C = [];
    stRes.S = [];
    
    % check if there's still an extension in basename:
    iPoint = findstr('.', baseName);
    % if so, remove everything after the first point
    if ~isempty(iPoint)
        baseName = baseName(1:iPoint(1)-1);
    end
 
    a = strread(baseName, '%s', 'delimiter', '_');
    iWell = strmatch('W', a);
    if isempty(iWell) | length(iWell) > 1
        return;
    end
    iFilter = strmatch('F',a);
    if isempty(iFilter)| length(iFilter) > 1
        return;
    end
    iTime = strmatch('T', a) ;
    if isempty(iTime)| length(iTime) > 1
        return;
    end
    iPump = strmatch('P', a);
    if isempty(iPump)| length(iPump) > 1
        return;
    end
    arrayID = a(iWell);
    filter = a(iFilter);
    integrationTime = a(iTime);
    pumpCycle  = a(iPump);

    % optionals.
    iSample = strmatch('S', a);
    if length(iSample) == 1
        stRes.S = a(iSample);
    end
    iChip = strmatch('C', a);
    if length(iChip) == 1
        stRes.C = a(iChip);
    end

    stRes.W = char(arrayID);
    stRes.F = char(filter);
    stRes.T = char(integrationTime);
    stRes.P = char(pumpCycle);
    
    


    