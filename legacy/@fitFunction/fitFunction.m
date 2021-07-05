function f = fitFunction(strModel)

if nargin == 0 | ~ischar(strModel)
    f.strModelName  = [];
    f.strModelDescription = [];
    f.clParameter   = [];
    f.strFitFunctionName = [];
    f.strIniFunctionName = [];
    f.strDerFunctionName = [];
    f.jacFlag = 0;
    f = class(f, 'fitFunction');
    return
end

Func = funcDef();
if isequal(strModel, 'select')
    h = selectGuim(Func);
    waitfor(h, 'Visible');
    try
        handles= guidata(h);
        if ~isempty(handles.iModel)
            strModel = Func(handles.iModel).strModelName;
        end
        delete(h);
    catch
        % nothing selected
    end
end
[clList{1:length(Func)}] = deal(Func.strModelName);
iMatch = strmatch(strModel, clList, 'exact');
if ~isempty(iMatch)
    f = Func(iMatch);
else
    f.strModelName  = [];
    f.strModelDescription = [];
    f.clParameter   = [];
    f.strFitFunctionName = [];
    f.strIniFunctionName = [];
    f.strDerFunctionName = [];
    f.jacFlag = 0;
end
f = class(f, 'fitFunction');

