function [B1] = lassoLogisticRegression (datalinearX,alldataY,parallel)
% B1 are the coeffiecients, B1(0) is a constants, B1(1:end) are the
% coefficients for the parameters in info.
%   choice for x : 'segs', 'regs'
%
% dirname is directory with allready trained seg files
% dirname = '/Users/Stella/Dropbox/100XTrain_/'

% construct squares
dataQuadraticX = repmat(datalinearX,1,size(datalinearX,2)).*repelem(datalinearX,1,size(datalinearX,2));

numD = size(datalinearX,2);
indicesToStay = find(tril(ones(numD,numD)));
dataQuadraticX = dataQuadraticX(:,indicesToStay);

alldataX = [datalinearX, dataQuadraticX];

if parallel == 1
    options = statset('UseParallel',true);
else
    options = statset('UseParallel',false);
end

%Construct a regularized binomial regression using 25 Lambda values and 10-fold cross validation
% B : fitted coefficients with size (number of predictors x lambda)
tic;
%[B,FitInfo] = lassoglm(alldataX,alldataY,'normal','NumLambda',10,'CV',10,'Options',options);
[B,FitInfo] = lassoglm(alldataX,alldataY,'normal','NumLambda',20,'CV',5,'Options',options);
toc

lassoPlot(B,FitInfo,'PlotType','CV');
lassoPlot(B,FitInfo,'PlotType','Lambda','XScale','log');
indx = FitInfo.Index1SE; % index of lambda with minimum deviance plus one standard deviation
B0 = B(:,indx); % B for the lambda with min deviance + std
nonzeros = sum(B0 ~= 0) % non zero coefficients

% create a coefficient vector with the constant term first.
cnst = FitInfo.Intercept(indx);
B1 = [cnst;B0];

% residuals
preds = glmval(B1,alldataX,'logit');
histogram(alldataY - preds) % plot residuals
title('Residuals from lassoglm model')
disp (['error : ', num2str(sum(alldataY - round(preds)))])
disp (['percentage error :', num2str(sum(alldataY - round(preds))/numel(alldataY))])


end