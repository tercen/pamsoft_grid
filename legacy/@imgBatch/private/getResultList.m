function [ResultList, clMsg] = getResultList(FoundList, instrumentID)
clMsg = [];
j = 0;
m = 0;
for i=1:length(FoundList)
    if instrumentID == 0 | instrumentID == 1 | instrumentID == 2
          stResEntry = imgReadWFTP(FoundList(i).fName);

    elseif instrumentID == 3
          stResEntry  = imgReadFD10Name(FoundList(i).fName, foundList(i).fPath);
    end
    if ~isempty(stResEntry.W)
        j = j+1;
        clNames = fieldnames(stResEntry);
        for n=1:length(clNames)
            ResultList(j).(clNames{n}) = stResEntry.(clNames{n});
        end
        ResultList(j).fName = FoundList(i).fName;
        ResultList(j).fPath = FoundList(i).fPath;
    else
        m = m+1;
        clMsg{m} = ['Skipped: ',FoundList(i).fName,', because the naming format was not recognized'];
    end

end