function Func = funcDef()
% this function provides a structure with an description of the available
% fitting functions

% simple IC50
Func(1).strModelName            = 'IC50 simple';
Func(1).strModelDescription     = 'Simple IC50 with offset = 0, hill slope = -1, assumes linear x-axis';

Func(1).clParameter{1}          = 'Ymax';
Func(1).clParameter{2}          = 'IC50';

Func(1).strFitFunctionName      = 'cfIC50s';
%#function cfIC50s
Func(1).strIniFunctionName      = 'ifIC50s';
Func(1).strDerFunctionName      = [];
%#function ifIC50s
Func(1).jacFlag                 = 1;

% IC50 with offset
Func(2).strModelName            = 'IC50 offset';
Func(2).strModelDescription     = 'IC50 with variable offset, hillslope = -1, assumes linear x-axis';

Func(2).clParameter{1}          = 'Y0';
Func(2).clParameter{2}          = 'Ymax';
Func(2).clParameter{3}          = 'IC50';

Func(2).strFitFunctionName      = 'cfIC50offset';
Func(2).strIniFunctionName      = 'ifIC50offset';
Func(2).jacFlag                 = 1;

%#function cfIC50offset
%#function ifIC50offset
% Exp Ass Ris
Func(3).strModelName            = 'Exp Associated';
Func(3).strModelDescription     = 'Exponential associated rise';

Func(3).clParameter{1}          = 'Y0';
Func(3).clParameter{2}          = 'Yspan';
Func(3).clParameter{3}          = 'k';

Func(3).strFitFunctionName      = 'cfExpAss';
Func(3).strIniFunctionName      = 'ifExpAss';
Func(3).strDerFunctionName      = 'derExpAss';

Func(3).jacFlag                 = 1;


%#function derExpAss
%#function cfExpAss
%#function ifExpAss

% logIC50, variable slope, offset
Func(4).strModelName            = 'logIC50_1';
Func(4).strModelDescription     = 'logIC50, Ymax to Y0, variable slope. Assumes log10 x-axis';

Func(4).clParameter{1}          = 'Y0';
Func(4).clParameter{2}          = 'Ymax';
Func(4).clParameter{3}          = 'logIC50';
Func(4).clParameter{4}          = 'hs';

Func(4).strFitFunctionName      = 'cfLogIC50';
Func(4).strIniFunctionName      = 'ifLogIC50';
Func(4).jacFlag                 = 1;
%#function cfLogIC50
%#function ifLogIC50

%
Func(5).strModelName            = 'logIC50_2';
Func(5).strModelDescription     = 'logIC50, Ymax to 0, variable slope. Assumes log10 x-axis';

Func(5).clParameter{1}          = 'Ymax';
Func(5).clParameter{2}          = 'logIC50';
Func(5).clParameter{3}          = 'hs';

Func(5).strFitFunctionName      = 'cfLogIC50_2';
Func(5).strIniFunctionName      = 'ifLogIC50_2';
Func(5).jacFlag                 = 1;
%#function cfLogIC50_2
%#function ifLogIC50_2

%
Func(6).strModelName            = 'logIC50_3';
Func(6).strModelDescription     = 'logIC50, Ymax to Y0, fixed slope. Assumes log10 x-axis';

Func(6).clParameter{1}          = 'Y0';
Func(6).clParameter{2}          = 'Ymax';
Func(6).clParameter{3}          = 'logIC50';

Func(6).strFitFunctionName      = 'cfLogIC50_3';
Func(6).strIniFunctionName      = 'ifLogIC50_3';
Func(6).jacFlag                 = 1;
%#function cfLogIC50_3
%#function ifLogIC50_3

%
Func(7).strModelName           = 'logIC50_4';
Func(7).strModelDescription    = 'logIC50, Ymax to 0, fixed slope. Assumes log10 x-axis';

Func(7).clParameter{1}         = 'Ymax';
Func(7).clParameter{2}         = 'logIC50';

Func(7).strFitFunctionName      = 'cfLogIC50_4';
Func(7).strIniFunctionName      = 'ifLogIC50_4';
Func(7).jacFlag                 = 1;
%#function cfLogIC50_4
%#function ifLogIC50_4
Func(8).strModelName            = 'logEC50_1';
Func(8).strModelDescription     = 'logEC50, Ymin to Ymax, variable slope. Assumes log10 x-axis';

Func(8).clParameter{1}          = 'Ymin';
Func(8).clParameter{2}          = 'Ymax';
Func(8).clParameter{3}          = 'logEC50';
Func(8).clParameter{4}          = 'hs';

Func(8).strFitFunctionName      = 'cfLogEC50_1';
Func(8).strIniFunctionName      = 'ifLogEC50_1';
Func(8).jacFlag                 = 1;
%#function cfLogEC50_1
%#function ifLogEC50_1
Func(9).strModelName            = 'logEC50_2';
Func(9).strModelDescription     = 'logEC50, Ymin to 0, variable slope. Assumes log10 x-axis';

Func(9).clParameter{1}          = 'Ymin';
Func(9).clParameter{2}          = 'Ymax';
Func(9).clParameter{3}          = 'hs';

Func(9).strFitFunctionName      = 'cfLogEC50_2';
Func(9).strIniFunctionName      = 'ifLogEC50_2';
Func(9).jacFlag                 = 0;
%#function cfLogEC50_2
%#function ifLogEC50_2
Func(10).strModelName           = 'logEC50_4';
Func(10).strModelDescription    = 'logEC50, Ymax to 0, fixed slope. Assumes log10 x-axis';

Func(10).clParameter{1}         = 'Ymax';
Func(10).clParameter{2}         = 'logIC50';

Func(10).strFitFunctionName      = 'cfLogEC50_4';
Func(10).strIniFunctionName      = 'ifLogEC50_4';
Func(10).jacFlag                 = 0;
%#function cfLogEC50_4
%#function ifLogEC50_4

Func(11).strModelName           = 'logIC50_5';
Func(11).strModelDescription    = 'logIC50, 1 to 0, variable slope';

Func(11).clParameter            = {'logIC50', 'hs'};

Func(11).strFitFunctionName     = 'cfLogIC50_5';
Func(11).strIniFunctionName     = 'ifLogIC50_5';
Func(11).jacFlag                = 1;
%#function cfLogIC50_5
%#function ifLogIC50_5

Func(12).strModelName           = 'logIC50_6';
Func(12).strModelDescription    = 'logIC50, 1 to 0, fixed slope';

Func(12).clParameter            = {'logIC50'};

Func(12).strFitFunctionName     = 'cfLogIC50_6';
Func(12).strIniFunctionName     = 'ifLogIC50_6';
Func(12).jacFlag                = 1;
%#function cfLogIC50_6
%#function ifLogIC50_6
% logIC50, variable slope, offset
Func(13).strModelName            = 'logIC50_1bw';
Func(13).strModelDescription     = 'logIC50, Ymax to Y0, variable slope, suitable for both ways. Assumes log10 x-axis';

Func(13).clParameter{1}          = 'Y0';
Func(13).clParameter{2}          = 'Ymax';
Func(13).clParameter{3}          = 'logIC50';
Func(13).clParameter{4}          = 'hs';

Func(13).strFitFunctionName      = 'cfLogIC50';
Func(13).strIniFunctionName      = 'ifLogIC50bw';
Func(13).jacFlag                 = 1;
%#function cfLogIC50
%#function ifLogIC50bw

%
Func(14).strModelName            = 'logIC50_3bw';
Func(14).strModelDescription     = 'logIC50, both ways, Ymax to Y0, fixed slope. Assumes log10 x-axis';

Func(14).clParameter{1}          = 'Y0';
Func(14).clParameter{2}          = 'Ymax';
Func(14).clParameter{3}          = 'logIC50';

Func(14).strFitFunctionName         = 'cfLogIC50_3';
Func(14).strIniFunctionName       = 'ifLogIC50_3bw';
Func(14).jacFlag                 = 1;
%#function cfLogIC50_3
%#function ifLogIC50_3bw