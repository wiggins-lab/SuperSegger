function [rawScores] = lassoScore (X,coefficients)
% calculateLassoScores : calculates scores as A_1 + A_i*X_i + A_ij * X_i * X_j
%
% INPUT :
%       X : properties of regions or segments used for score calculation
%       A : coefficients as calculated by lasso regularized regression for
%       the score function above
% OUPUT :
%    rawScores : are calculate from the probabilities 0-1 converted to -50
%    to 50. rawScores < 0 have score 0 (bad segment/region) and rawScores > 0
%    have score 1 (good segment/regin)


linear = false;

if linear
    alldataX = [X];
else % calculates quadratic relationships, keeps unique relationships only
    quadraticX = repmat(X,1,size(X,2)).*repelem(X,1,size(X,2));
    numD = size(X,2);
    indicesToStay = find(tril(ones(numD,numD)));
    quadraticX = quadraticX(:,indicesToStay);
    % adds linear and quadratic in one vector
    alldataX = [X, quadraticX];
end

% calculates scores (rawScores - from 0 to 1). scores are rounded rawScores
rawScores = glmval(coefficients,alldataX,'logit');
rawScores(isnan(rawScores)) = 0;
rawScores = (rawScores - .5) * 100;

end