function [assignments,errorR]  = multiAssignmentCombo (data_c, data_f)
% each row is assigned to one column only - starting by the minimum
% possible cost and continuing to the next minimum possible cost.
% works only c - > f (r -> c) not backwards. attempts to map candidates to
% one or two cells, but not the other way around.

% other ideas :
% - center them over the same centroid and then get area overlap?
% - the distance of centroid fromt the line is good.. but I also need the centroid
% distance.
% the last two should be distance of centroid maybe..?
%

% also need the opposite - would merging two together in c make them match
% something better?

areaFactor = 5;
areaChangeFactor = 50;

numRegs1 = data_c.regs.num_regs;
numRegs2 = data_f.regs.num_regs;
regsInC = 1:data_c.regs.num_regs;
regsInF = 1:data_f.regs.num_regs;


idsF(1,regsInF) = regsInF;
idsF(2,regsInF) = NaN;


areaOverlapCost = NaN * ones(numRegs1,numRegs2);
areaChange = NaN * ones(numRegs1,numRegs2);
centroidCost = NaN * ones(numRegs1,numRegs2);
assignments  = cell( 1, numRegs1);

% find possible pairs....
counter = 1;
pairsF = NaN * zeros(2,numRegs2 * numRegs2);
for jj = regsInF
    pad = 3;
    [xx,yy] = getBBpad(data_f.regs.props(jj).BoundingBox,size(data_c.phase),pad);
    mask1 = (data_f.regs.regs_label==jj);
    
    % get neighbors
    neigh = data_f.regs.regs_label(yy,xx);
    ind_neigh = unique(neigh)'; % unique neighbors
    ind_neigh = ind_neigh(ind_neigh > jj); % not already made pairs
    
    % make pairs
    for uu = ind_neigh
        pairsF(:,counter)   = [jj;uu];
        counter = counter + 1;
    end
end

cleanpairIDs = (nansum(pairsF)~=0);
pairsF = pairsF(:,cleanpairIDs);


% one to one costs
for ii = regsInC % loop through the regions
    % ind : list of regions that overlap with region ii in data 1
    pad = 3;
    [xx,yy] = getBBpad(data_c.regs.props(ii).BoundingBox,size(data_c.phase),pad);
    maskC = (data_c.regs.regs_label==ii);
    areaC = (data_c.regs.props(ii).Area);
    centroidC = data_c.regs.props(ii).Centroid;
    
    % dilate mask and get adjacent regions within dilated area
    regs2 = data_f.regs.regs_label(yy,xx);
    ind1 = unique(regs2);
    ind1 = ind1(ind1~=0)'; % remove 0
    
    for jj = ind1 % regions in data_f
        
        maskF = (data_f.regs.regs_label == jj);
        areaF = (data_f.regs.props(jj).Area);
        centroidF = (data_f.regs.props(jj).Centroid);
        overlapMask = double(maskF(maskC)); % overlap mask for ii and jj
        areaOverlap = sum(overlapMask(:)); % area of overlap between jj and ii
        % X is area of overlap / max ( area of ii, area of jj)
        areaOverlapCost(ii,jj) = areaOverlap/areaC;
        
        if  (areaOverlapCost(ii,jj) == 0)
            areaOverlapCost(ii,jj) = 0.001;
        end
        
        centroidCost(ii,jj) = sqrt(sum((centroidC - centroidF).^2));
        areaChange(ii,jj) = (areaF - areaC)/(areaC);
    end
end


costOneToOneAll = areaFactor * 1./areaOverlapCost + centroidCost +  areaChangeFactor * abs(areaChange);
costOneToOne = costOneToOneAll;

oneToTwoCentroidCost = NaN *ones(numRegs1, size(pairsF,2));
oneToTwoAreaChangeCost = NaN *ones(numRegs1, size(pairsF,2));
areaOverlapCost = NaN *ones(numRegs1, size(pairsF,2));
oneToTwoCentroidDist = NaN *ones(numRegs1, size(pairsF,2));

for ii = regsInC
    % get first 5 minimum costs
    cost = costOneToOneAll(ii,:);
    mask1 = (data_c.regs.regs_label == ii);
    
    if sum(~isnan(cost)) > 1 % two possible assignments
        possibleMapInd = find(~isnan(cost));
        
        for jj = 1 : numel(possibleMapInd)-1
            for kk = jj+1 : numel(possibleMapInd)
                sis1 = possibleMapInd(jj);
                sis2 = possibleMapInd(kk);
                isItPair = all(ismember(pairsF,[sis1,sis2]));
                if any(isItPair)
                    % find their location
                    counter = find (isItPair);
                    
                    % calculates cost of centroid in data_c from the line that
                    % centroid1 and centroid2 make
                    Centroid1 = data_f.regs.props(sis1).Centroid;
                    Centroid2 = data_f.regs.props(sis2).Centroid;
                    CentroidBef = data_c.regs.props(ii).Centroid;
                    %oneToTwoCentroidCost(ii,counter) = abs(det([Centroid1-Centroid2;CentroidBef-Centroid1]))/norm(Centroid1-Centroid2);
                    oneToTwoCentroidDist (ii,counter) = sqrt(sum((mean([Centroid1; Centroid2]) -  CentroidBef).^2));
                    
                    
                    % somehow put some weight for cells being along the length of each other
                    % make the centroid distance be along the long axis
                    % of the cell??
                    comboMask = (data_f.regs.regs_label==sis1) + (data_f.regs.regs_label==sis2);
                    comboMask = double (comboMask >0);
                    comboCentroid = (mean([Centroid1; Centroid2]));
                    %offset = round(CentroidBef - comboCentroid );
                    %maskOut = imtranslate(comboMask,offset);
                    
                    totMaskF = comboMask(mask1);
                    totAreaOverap = sum(totMaskF(:));
                    areaOverlapCost(ii,counter) = totAreaOverap/(data_c.regs.props(ii).Area);
                    if  (areaOverlapCost(ii,counter) == 0)
                        areaOverlapCost(ii,counter) = 0.001;
                    end
                    
                    oneToTwoAreaChangeCost (ii,counter) = (data_f.regs.props(sis1).Area +...
                        data_f.regs.props(sis2).Area - ...
                        data_c.regs.props(ii).Area)/...
                        (data_c.regs.props(ii).Area);
                end
            end
        end
    end
end

totCostOneToTwo = (oneToTwoCentroidDist + areaChangeFactor * abs(oneToTwoAreaChangeCost) + areaFactor * 1./(0.5*areaOverlapCost));

totalCost = [costOneToOne, totCostOneToTwo];
costMat = totalCost;
allids = [idsF,pairsF];

numElements = size(costMat,1);
cost = NaN*zeros(1,numElements);
assignedInC = [];
assignedInF = [];


while nansum (costMat(:)) > 0
    [minCost,ind] = min(costMat(:));
    [asgnRow,asgnCol] = ind2sub(size(costMat),ind);
    assignTemp = allids(:,asgnCol)';
    assignTemp = assignTemp (~isnan(assignTemp));
    assignments {asgnRow} = assignTemp;
    
    % show assignments
    
    intDisplay (data_c,data_f,assignments,asgnRow)
    
    assignedInC  = [assignedInC;asgnRow];
    assignedInF = [assignedInF;assignTemp'];
    % find all columns to be set as nans
    colToDel1 = any(ismember(allids,assignTemp));
    cost (asgnRow) = minCost;
    costMat (asgnRow, :) = NaN; % add nans to already assigned
    costMat (:, colToDel1) = NaN; % add nans to already assigned
end


% find leftovers, give them max assignments, and put errors in them..
leftInC = setdiff (regsInC,assignedInC);
leftInF = setdiff (regsInF,assignedInF);

% errors to the ones that do not map to anything
errorR = zeros(1,numRegs1);
for ii = leftInC
    errorR (ii) = 1;
end


debug_flag = 1;
if debug_flag
    figure(1)
    imshow(data_f.phase,[]);
    figure(2)
    imshow(data_c.phase,[]);
    
    figure(3);
    % check out the assignments :)
    for ii = 1:data_c.regs.num_regs
        regF = assignments {ii};
        maskF = data_f.regs.regs_label*0;
        if isempty(regF)
            disp('nothing')
            imshow (cat(3,0*ag(maskF),ag(data_c.regs.regs_label==ii),ag(data_c.mask_cell)));
            pause
        else
            for f = 1 : numel(regF)
                maskF = maskF + (data_f.regs.regs_label == regF(f))>0;
            end
            imshow (cat(3,ag(maskF),ag(data_c.regs.regs_label==ii),ag(data_c.mask_cell)));
            pause;
        end
    end
end


end


function intDisplay (data_c,data_f,assignments,ii)
regF = assignments {ii};
maskF = data_f.regs.regs_label*0;
if isempty(regF)
    disp('nothing')
    imshow (cat(3,0*ag(maskF),ag(data_c.regs.regs_label==ii),ag(data_c.mask_cell)));
else
    for f = 1 : numel(regF)
        maskF = maskF + (data_f.regs.regs_label == regF(f))>0;
    end
    imshow (cat(3,ag(maskF),ag(data_c.regs.regs_label==ii),ag(data_c.mask_cell)));
end
end