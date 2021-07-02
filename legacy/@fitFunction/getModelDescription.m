function strDescription = getModelDescription(f, strModel)

clModel = getAvailableModelList(f);
iMatch = strmatch(strModel, clModel);
if ~isempty(iMatch)
    Func = funcDef();
    strDescription = Func(iMatch).strModelDescription;
else
    strDescription = [strModel, 'is not available for fitFunction object'];
end


    