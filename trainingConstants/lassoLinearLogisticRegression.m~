function [B1] = lassoLinearLogisticRegression (dirname)
% B1 are the coeffiecients, B1(0) is a constants, B1(1:end) are the
% coefficients for the parameters in info.
%
% dirname is directory with allready trained seg files
% dirname = '/Users/Stella/Dropbox/100XTrain_/'

contents = dir([dirname,'*_seg.mat']);
alldataY = [];
datalinearX = [];


for i = 1 : numel(contents)
    data = load([dirname,contents(i).name]);
    if ~isnan(data.segs.score)
    alldataY = [alldataY;data.segs.score];
    datalinearX = [datalinearX;data.segs.info];
    end
end

% construct squares
dataQuadraticX = repmat(datalinearX,1,size(datalinearX,2)).*repelem(datalinearX,1,size(datalinearX,2));


% numD = size(datalinearX,2);;
% indices = find(triu(ones(numD,numD)));
% [a,b] = ind2sub ([numD,numD],indices);

alldataX = [datalinearX, dataQuadraticX];

options = statset('UseParallel','on');

%Construct a regularized binomial regression using 25 Lambda values and 10-fold cross validation
% B : fitted coefficients with size (number of predictors x lambda)
[B,FitInfo] = lassoglm(alldataX,alldataY,'binomial','NumLambda',25,'CV',10,options);

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

% for non linear regression model

modelfun = @(b,x) b(1) + b(2:numel(x)+1) * x + b(numel(x)+2:end) *x*x


%modelfun = @(b,x)b(1) + b(2)*x(:,1).^b(3) +  b(4)*x(:,2).^b(5);


end