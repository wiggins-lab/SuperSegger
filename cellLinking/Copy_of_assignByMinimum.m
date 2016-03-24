function [assignment,cost]  = assignByMinimum (costMat)
% each row is assigned to one column only - starting by the minimum
% possible cost and continuing to the next minimum possible cost.

numElements = size(costMat,1);
assignment = zeros(1,numElements);
cost = zeros(1,numElements);

while nansum (costMat(:)) > 0    
    [minCost,ind] = min(costMat(:));
    [asgnRow,asgnCol] = ind2sub(size(costMat),ind);
    assignment (asgnRow) = asgnCol;
    cost (asgnRow) = minCost;
    costMat (asgnRow, :) = NaN;
end

end