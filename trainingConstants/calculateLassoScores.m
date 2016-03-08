function [scores,rawScores] = calculateLassoScores (X,coefficients)
% calculateLassoScores : calculates scores as A_1 + A_i*X_i + A_ij * X_i * X_j
%
% INPUT :
%       X : properties of regions or segments used for score calculation
%       A : coefficients as calculated by lasso regularized regression for
%       the score function above
%

% calculates quadratic relationships, keeps unique relationships only
quadraticX = repmat(X,1,size(X,2)).*repelem(X,1,size(X,2));
numD = size(X,2);
indicesToStay = find(tril(ones(numD,numD)));
quadraticX = quadraticX(:,indicesToStay);

% adds linear and quadratic in one vector
alldataX = [X, quadraticX];

% calculates scores (rawScores - from 0 to 1). scores are rounded rawScores
rawScores = glmval(coefficients,alldataX,'logit');
scores = round(rawScores);

end