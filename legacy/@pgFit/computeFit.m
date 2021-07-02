function [pRes, pStdError, wRes, pgfit] = computeFit(pgfit, X, Y, W)

% check size and shape of input
if nargin < 4
    W = [];
end


[sx1, sx2] = size(X);
if sx1 < sx2
    X = X';
    Y = Y';
    W = W';
end
if min(size(X)) ~= 1
    error('Input argument X must be a vector');
end

[sy1, sy2] = size(Y);
if sy1 ~= length(X)
    error('Size of input argument Y does not correspond to that of X');
end

if isempty(W) 
    W = ones(size(Y));
elseif size(W) ~= size(Y)
    error('Size of input argument W must be equal to that of Y'); 
end
% --------------------

if isequal(pgfit.TolMode, 'Relative')
    bRelative = logical(1);
else
    bRelative = logical(0);
end


% loop over the datasets Y(:,i)
for i=1:sy2

    % get the default initalization parameters from the modelObject
    [p0, pLower, pUpper] = getInitialParameters(pgfit.modelObj, X, Y(:,i));

    % override initialization parameters when specified in pgfit object
    if ~isempty(pgfit.iniPars)
        p0 = pgfit.iniPars;
    end
    if ~isempty(pgfit.lbPars)
        pLower = pgfit.lbPars;
    end
    if ~isempty(pgfit.ubPars)
        pUpper = pgfit.ubPars;
    end
    
    outofbound = p0 <= pLower | p0 >= pUpper; 
    if any(outofbound)
        error(['pgFit: initial parameters are not within set bounds for parameter no: ',num2str(find(outofbound'))]);
    end
    
        
    switch pgfit.fitMethod
        case 'Normal'
            options = optimset('Jacobian', pgfit.jacobian,'Display', 'none' ,'MaxFunEvals', 10, 'TolX', 1e-8);
            nIter = 0;
            while(1)
                nIter = nIter + 1;
               [pOut, ChiSqr, Res, ExitFlag,dummy1,dummy2,jac] = lsqnonlin(@lsqFun, p0, pLower, pUpper,options,pgfit, X, Y(:,i), W(:,i));
              
                if bRelative
                    iZero = p0 == 0;
                    p0(iZero) = 1e-10;
                    eps = abs((p0-pOut)./p0);
                else
                    eps = abs(p0-pOut);
                end

                if eps <= pgfit.TolX | nIter >= pgfit.maxIterations
                    break;
                else
                    p0 = pOut;
                end
            end
            pRes(:,i) = pOut;
            wRes(:,i) = W(:,i);

        case 'Robust'
            options = optimset('Jacobian', pgfit.jacobian,'Display', 'none' ,'MaxFunEvals', 5, 'TolX', 1e-8);
            nIter = 0;
            
            % first iteration before reweight
            [pOut, ChiSqr, Res, ExitFlag,dummy1,dummy2,jac] = lsqnonlin(@lsqFun, p0, pLower, pUpper,options,pgfit, X, Y(:,i), W(:,i));
            fit = getCurve(pgfit.modelObj, X, pOut);
            wRob = calcRobustWeights((Y(:,i)-fit), pgfit.robTune);
            wIn = W(:,i).*wRob;
            
            while(1)
                nIter = nIter + 1;
                [pOut, ChiSqr, Res, ExitFlag,dummy1,dummy2,jac] = lsqnonlin(@lsqFun, p0, pLower, pUpper,options,pgfit, X, Y(:,i), wIn);
                fit = getCurve(pgfit.modelObj, X, pOut);

                wRob = calcRobustWeights((Y(:,i)-fit), pgfit.robTune);
                wIn = W(:,i).*wRob;
                
                if bRelative
                    iZero = p0 == 0;
                    p0(iZero) = 1e-10;
                    eps = abs((p0-pOut)./p0);
                else
                    eps = abs(p0-pOut);
                end

                if eps <= pgfit.TolX | nIter >= pgfit.maxIterations
                    break;
                else
                    p0 = pOut;
                end
            end
            pRes(:,i) = pOut;
            wRes(:,i) = wIn;
        case 'Robust2'
                options = optimset('Jacobian', pgfit.jacobian,'Display', 'none' ,'MaxFunEvals', 5, 'TolX', 1e-8);
            nIter = 0;
            
            % first iteration before reweight
            [pOut, ChiSqr, Res, ExitFlag,dummy1,dummy2,jac] = lsqnonlin(@lsqFun, p0, pLower, pUpper,options,pgfit, X, Y(:,i), W(:,i));
            fit = getCurve(pgfit.modelObj, X, pOut);
            wRob = calcRobustWeights2((Y(:,i)-fit), full(jac), pgfit.robTune);
            wIn = W(:,i).*wRob;
            
            while(1)
                nIter = nIter + 1;
                [pOut, ChiSqr, Res, ExitFlag,dummy1,dummy2,jac] = lsqnonlin(@lsqFun, p0, pLower, pUpper,options,pgfit, X, Y(:,i), wIn);
                fit = getCurve(pgfit.modelObj, X, pOut);

                wRob = calcRobustWeights2((Y(:,i)-fit), jac, pgfit.robTune);
                wIn = W(:,i).*wRob;
                
                if bRelative
                    iZero = p0 == 0;
                    p0(iZero) = 1e-10;
                    eps = abs((p0-pOut)./p0);
                else
                    eps = abs(p0-pOut);
                end

                if eps <= pgfit.TolX | nIter >= pgfit.maxIterations
                    break;
                else
                    p0 = pOut;
                end
            end
            pRes(:,i) = pOut;
            wRes(:,i) = wIn;
        
        
        case 'Filter'
            cppgFit = pgFit(pgfit);
            cppgFit = set(cppgFit, 'fitMethod','Robust');
            [pOut, w] = computeFit(cppgFit, X, Y(:,i), W(:,i));
            W(w < 0.1) = 0;
            cppgFit = set(cppgFit, 'fitMethod', 'Normal');
            [pRes(:,i), wRes(:,i)] = computeFit(cppgFit, X, Y(:,i), W(:,i));

    end %<switch>
    jac = full(jac);
    fit = getCurve(pgfit.modelObj, X, pRes(:,i));
    
    switch pgfit.errorMethod
        case 'ASE'
            bUsed = logical(pgfit.fitPars);
            pStdError(:,i) = zeros(size(p0));
            pStdError(bUsed,i) = fitAse(fit - Y(:,i), jac(:,bUsed));
    end
    
end %<i loop>

