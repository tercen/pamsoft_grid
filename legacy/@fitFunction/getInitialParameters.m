function [p0, pLow, pHigh] = getInitialParameters(f,x,y)
strIniFunc = f.strIniFunctionName;
[p0, pLow, pHigh] = feval(strIniFunc, x, y);
