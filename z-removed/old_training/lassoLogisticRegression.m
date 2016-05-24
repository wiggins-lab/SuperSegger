function [B1] = lassoLogisticRegression (datalinearX,alldataY,parallel,linear)
% B1 are the coeffiecients, B1(0) is a constants, B1(1:end) are the
% coefficients for the parameters in info.
%   choice for x : 'segs', 'regs'
%
% dirname is directory with allready trained seg files
% dirname = '/Users/Stella/Dropbox/100XTrain_/'


% what i used to train it with regularized logistic regression on segments
% disp ('starting training on segments...');
% [Xsegs,Ysegs] = getInfoScores (segDirMod,'segs');
% A = lassoLogisticRegression (Xsegs,Ysegs,parallel);
%updateScores(segDirMod,'segs',A,calculateLassoScores);


% construct squares

if ~exist('linear','var')
    linear = false;
end

if linear
    alldataX = datalinearX;
else
    dataQuadraticX = repmat(datalinearX,1,size(datalinearX,2)).*repelem(datalinearX,1,size(datalinearX,2));
    numD = size(datalinearX,2);
    indicesToStay = find(tril(ones(numD,numD)));
    dataQuadraticX = dataQuadraticX(:,indicesToStay);
    alldataX = [datalinearX, dataQuadraticX];
end

if parallel == 1
    options = statset('UseParallel',true);
else
    options = statset('UseParallel',false);
end

alldataY (isnan(alldataY)) = 0

%Construct a regularized binomial regression using 25 Lambda values and 10-fold cross validation
% B : fitted coefficients with size (number of predictors x lambda)
tic;
[B,FitInfo] = lassoglm(alldataX,alldataY,'normal','NumLambda',20,'CV',5,'Options',options);
toc

% plots to look at different lambdas
%lassoPlot(B,FitInfo,'PlotType','CV');
%lassoPlot(B,FitInfo,'PlotType','Lambda','XScale','log');

indx = FitInfo.Index1SE; % index of lambda with minimum deviance plus one standard deviation
B0 = B(:,indx); % B for the lambda with min deviance + std
nonzeros = sum(B0 ~= 0) % non zero coefficients

% create a coefficient vector with the constant term first.
cnst = FitInfo.Intercept(indx);
B1 = [cnst;B0];

% residuals
preds = glmval(B1,alldataX,'logit');
preds(isnan(preds)) = 0;

% results 
histogram(alldataY - preds) % histogram of residuals
title('Residuals from lassoglm model')
disp (['error : ', num2str(sum(alldataY - round(preds)))])
disp (['percentage error :', num2str(sum(alldataY - round(preds))/numel(alldataY))])


end