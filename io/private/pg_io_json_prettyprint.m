function strOut = pg_io_json_prettyprint(strIn)

nChar   = length(strIn);

isArray = 0;
strOut = '';
nTabs  = 0;
for i = 1:nChar
    
    if strIn(i) == '['
        isArray = 1;
    end
    
    if strIn(i) == ']'
        isArray = 0;
    end
    
    if strIn(i) == '{'
        
        strOut(end+1) = '{';
        strOut(end+1) = newline;
        nTabs = nTabs + 1;
    elseif strIn(i) == '}'
        strOut(end+1) = newline;
        strOut(end+1) = '}';
        
        nTabs = nTabs - 1;
    elseif strIn(i) == ','
        if isArray
            strOut(end+1) = ',';
        else
            strOut(end+1) = ',';
            strOut(end+1) = newline;

        end
    else
        
        strOut(end+1) = strIn(i);
    end
    
end

% strOut = strrep(strIn, ',', ',\n');
% add a return character after curly brackets:
% strOut = strrep(strOut, '@', newline);

end