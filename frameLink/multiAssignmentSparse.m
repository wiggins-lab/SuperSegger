function [assignments,errorR,totCost,indexC,indexF,dA,revAssign]  = multiAssignmentSparse ...
    (data_c, data_f,CONST, forward, debug_flag)
% multiAssignmentSparse : assigns regions in data_c to regions in data_f.
% Uses a combination of area overlap, centroid distance, and outward push
% in colonies. Regions are assigned one-to-one or one-to-pair or
% pair-to-one. Each cell is assigned only once - starting by the
% minimum possible cost and continuing to the next minimum possible cost.
% Uses a sparse matrix to save the costs.
%
% INPUT :
%    data_c : current frame file
%    data_f : forward frame file
%    CONST : segmentation parameters
%    forward : 1 for forward direction (e.g current to forward), 0 for
%    reverse
%    debug_flag : 1 to display assignment result.
%
% OUTPUT :
%   assignments : cell matrix. cell of region c is assigned id of region f 
%   errorR : matrix with 2 (DA<MIN) or 3(DA>MAX) if error, 0 if no error
%   totCost : cost matrix
%   indexC : region ids in data_c for cost matrix
%   indexF : region ids in data_f for cost matrix
%   dA :  area change
%   revAssign : cell matrix with reverse assignments (from ids in f to c)
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou
% University of Washington, 2016
% This file is part of SuperSegger.
%
% SuperSegger is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% SuperSegger is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with SuperSegger.  If not, see <http://www.gnu.org/licenses/>.


global str8
str8 = strel('square',5);
DA_MIN = CONST.trackOpti.DA_MIN;
DA_MAX =  CONST.trackOpti.DA_MAX;

if ~exist('debug_flag','var') || isempty(debug_flag)
    debug_flag = 0;
end

if ~exist('forward','var') || isempty(forward)
    forward = 1;
end

if forward
    sign = 1;
else
    sign = -1;
end

maxDA = max(sign * DA_MIN,sign * DA_MAX);
minDA = min(sign * DA_MIN,sign * DA_MAX);



revAssign = [];
assignments = [];
errorR = [];
totCost=[];
indexC=[];
indexF=[];
noOverlap = 0.0001;
centroidWeight = 5;
areaFactor = 20;
areaChangeFactor = 100;
outwardMotFactor = 1/10;
dA = [];

if ~isempty(data_c)
    if ~isfield(data_c,'regs')
        data_c = updateRegionFields (data_c,CONST);
    end
    ss = size(data_c.phase);
    
    numRegs1 = data_c.regs.num_regs;
    assignments  = cell( 1, numRegs1);
    errorR = zeros(1,numRegs1);
    dA = nan*zeros(1,numRegs1);
    
    if ~isempty(data_f)
        if ~isfield(data_f,'regs')
            data_f = updateRegionFields (data_f,CONST);
        end
        
        numRegs2 = data_f.regs.num_regs;
        regsInC = 1:data_c.regs.num_regs;
        regsInF = 1:data_f.regs.num_regs;
        
        idsC(1,regsInC) = regsInC;
        idsC(2,regsInC) = NaN;
        
        idsF(1,regsInF) = regsInF;
        idsF(2,regsInF) = NaN;
        
        % colony calculation
        maskBgFill= imfill(data_c.mask_bg,'holes');
        colony_labels = bwlabel(maskBgFill);
        colony_props = regionprops( colony_labels,'Centroid','Area');
        
        % find possible pairs
        [pairsF,~] = findNeighborPairs (data_f, numRegs2, regsInF,[]);
        allF = [idsF,pairsF];
        
        [pairsC,neighF] = findNeighborPairs (data_c, numRegs1, regsInC, data_f);
        allC = [idsC,pairsC];
        
        % initialize
        
        
        indexC =  NaN * ones(2,size(allC,2)*10);
        indexF = indexC;
        totCost =  NaN * ones(1,size(allC,2)*10);
        areaOverlapCost = totCost;
        areaChange = totCost;
        centroidCost = totCost;
        areaOverlapTransCost = totCost;
        outwardMot = totCost;
        distFromColonyMat = totCost;
        goodOneToOne = zeros(1,size(allC,2));
        distFromColn = zeros(1,size(allC,2));
        counter = 1;
        
        for ii = 1:size(allC,2) % loop through the regions
            % ind : list of regions that overlap with region ii in data 1
            
         
            % if it already has a good mapping don't bother..
            cRegs = allC(:,ii);
            isSingleRegC = sum(isnan(cRegs)); % has a nan
            
            % condition for good one to one to mapping
            alreadyFoundOneToOne = ~isSingleRegC  && (goodOneToOne(cRegs(1)) ...
                || goodOneToOne(cRegs(2))) ;
            
            % only check pairs if not good one-to-one mapping
            if  ~alreadyFoundOneToOne %&& regionExists
                
                [BB_c_xx,BB_c_yy] = getBoxLimits (data_c,cRegs);
                [maskC,areaC,centroidC] = regProperties (data_c,cRegs,BB_c_xx,BB_c_yy);
                
                % colony it belongs to
                colony_labels_temp = colony_labels(BB_c_yy,BB_c_xx);
                colOverlap = colony_labels_temp(maskC);
                if sum(colOverlap(:)) == 0
                    distFromColony = [0 ,0];
                    distFromColn (ii) = sqrt(sum(distFromColony.^2));
                else
                    colonyId =  max(colOverlap);
                    distFromColony = centroidC - colony_props(colonyId).Centroid;
                    distFromColn (ii) = sqrt(sum(distFromColony.^2));
                end
                
                % dilate mask and get adjacent regions within dilated area
                nonNanCregs = cRegs(~isnan(cRegs));
                tmpregs2 = [neighF{[nonNanCregs]}];
                possibleMapInd = unique(tmpregs2);
                possibleMapInd = possibleMapInd(possibleMapInd~=0)'; % remove 0
                
                startcounter = counter;
                for yy = 1:numel(possibleMapInd)
                    % one to one mapping
                    idF = possibleMapInd(yy);
                    [maskF,areaF,centroidF] = regProperties (data_f,idF,BB_c_xx,BB_c_yy);
                    indexC(:,counter) = cRegs;
                    indexF(1,counter) = idF;
                    overlapMask = maskF(maskC);
                    areaOverlap = sum(overlapMask(:)); % area of overlap between jj and ii
                    areaOverlapCost(counter) = areaOverlap/areaC;
                    
                    if  (areaOverlapCost(counter) == 0)
                        areaOverlapCost(counter) = noOverlap;
                    end
                    
                    displacement = centroidC - centroidF;
                    centroidCost(counter) = sqrt(sum((displacement).^2));
                    if centroidCost(counter) == 0
                        outwardMot(counter) = 0;
                    else
                        outwardMot(counter) = (distFromColony*displacement')/centroidCost(counter);
                    end
                    
                    distFromColonyMat (counter) = exp(-distFromColn(ii)/outwardMotFactor);
                    
                    areaChange(counter) = (areaF - areaC)/(areaC);
                    
                    % moved area
                    offset = round(displacement);
                    maskOut = imshift(maskF,offset);
                    maskOut = maskOut(maskC);
                    areaOverlapTrns = sum(maskOut(:));
                    areaOverlapTransCost(counter) = areaOverlapTrns/areaC;
                    
                    if (areaOverlapTransCost(counter) == 0)
                        areaOverlapTransCost(counter) = noOverlap;
                    end
                    counter = counter + 1;
                    
                    
                    
                end
                
                if isSingleRegC && startcounter~=counter % one cell to be mapped
                    totCost(:,startcounter:counter-1) = areaChangeFactor * 1./areaOverlapTransCost(:,startcounter:counter-1) + ...
                        areaFactor * 1./areaOverlapCost(:,startcounter:counter-1) + centroidCost(:,startcounter:counter-1) + ...
                        areaChangeFactor * abs(areaChange(:,startcounter:counter-1));
                    
                    [~,indx] = min( totCost(:,startcounter:counter-1));
                    
                    goodOneToOne(ii) = abs(areaChange(startcounter+indx-1)) < 0.15 &&...
                        areaOverlapCost(startcounter+indx-1) > 0.7 ...
                        && areaOverlapTransCost(startcounter+indx-1) > 0.8;
                    
                else
                    goodOneToOne (ii) = 1; % no two to two mappings
                end
                
                
                % if the one to one mapping looks good don't bother with
                % pairs - to make faster
                
                if ~goodOneToOne(ii)
                    for yy = 1:numel(possibleMapInd)
                        for kk = (yy+1) : numel(possibleMapInd)
                            
                            sis(1) = possibleMapInd(yy);
                            sis(2) = possibleMapInd(kk);
                            
                            isItPair = all(ismember(allF,[sis(1),sis(2)]));
                            if any(isItPair)
                                % find their location
                                
                                indexC(:,counter) = cRegs;
                                indexF(:,counter) = sis;
                                                                
                                % combined masks, areas, centroids
                                [maskF,areaF,centroidF] = regProperties (data_f,sis,BB_c_xx,BB_c_yy);
                                overlapMask = maskF(maskC);
                                areaOverlap = sum(overlapMask(:)); % area of overlap between jj and ii
                                areaOverlapCost(counter) = areaOverlap/areaC;
                                
                                if  (areaOverlapCost(counter) == 0)
                                    areaOverlapCost(counter) = noOverlap;
                                end
                                
                                displacement = centroidC - centroidF;
                                centroidCost(counter) = sqrt(sum((displacement).^2));
                                
                                if centroidCost == 0
                                    outwardMot(counter) = 0;
                                else
                                    outwardMot(counter) = (distFromColony*displacement')/centroidCost(counter);
                                end
                                distFromColonyMat (counter) = exp(-distFromColn(ii)/outwardMotFactor);
                                
                                offset = round(displacement);
                                maskOut = imshift(maskF,offset);
                                maskOut = maskOut(maskC);
                                areaOverlapTrns = sum(maskOut(:));
                                areaOverlapTransCost(counter) = areaOverlapTrns/areaC;
                                
                                if  (areaOverlapTransCost(counter) == 0)
                                    areaOverlapTransCost(counter) = noOverlap;
                                end
                                
                                areaChange(counter) = (areaF - areaC)/(areaC);
                                counter = counter + 1;
                            end
                        end
                    end
                end
            end
        end
        
        
        areaChangePenalty = zeros(size(areaChange,1),size(areaChange,2));
        
        if forward
            % area decreases
            areaChangePenalty((areaChange) < -0.1) = 100;
        else
            outwardMot = - outwardMot;
            areaChangePenalty((areaChange) > 0.1) = 100;
        end
        
        %  penalty for big area changes
        areaChangePenalty(abs(areaChange) > 0.6) = 1000;
        areaChangePenalty(abs(areaChange) > 0.3) = 50;
        overlapCost = 1 - areaOverlapCost;
        totCost = areaChangePenalty +  areaChangeFactor * 1./areaOverlapTransCost + ...
            centroidWeight * centroidCost +  areaChangeFactor * abs(areaChange) + ...
            distFromColonyMat * areaFactor * 1./areaOverlapCost + outwardMotFactor * outwardMot ;
        
        %nonNanCost = ~isnan(totCost);
        totCost = totCost(1:counter-1);
        indexC = indexC(:,1:counter-1);
        indexF = indexF(:,1:counter-1);
                
        costMat= totCost;        
        flagger = ~isnan(costMat);
        
        while any( flagger(:)) >0
            
            [~,ind] = min(costMat(:));
            assignTemp = indexF(:,ind)';
            assignTemp = assignTemp (~isnan(assignTemp));
            regionsInC = indexC (:,ind);            
            assignments {regionsInC(1)} = assignTemp;
            if ~isnan(regionsInC(2))
                assignments {regionsInC(2)} = assignTemp;
            end
            
            %displayMap (data_c,data_f, assignTemp, regionsInC,[],[])
            
            % find all columns to be set as nans
            colToDelF = any(ismember(indexF,assignTemp));
            colToDelC = any(ismember(indexC,regionsInC));
            costMat (colToDelC) = NaN; % add nans to already assigned
            costMat (colToDelF) = NaN; % add nans to already assigned
            flagger(colToDelC) = 0;
            flagger(colToDelF) = 0;            
        end
        
        % make list of revAssign
        revAssign = getRevAssign();
        
        cArea = [data_c.regs.props.Area];
        fArea = [data_f.regs.props.Area];
       
        % attempt to fix assignment error for cells left without assignment
        [assignments,revAssign] =fixProblems(assignments,revAssign, overlapCost, indexF,indexC, cArea, fArea);
        [revAssign,assignments] =fixProblems(revAssign,assignments, overlapCost, indexC, indexF,fArea, cArea);        
        [assignments,revAssign] = exchangeAssignment (assignments,revAssign, totCost, indexF, indexC);
        [revAssign,assignments] = exchangeAssignment (revAssign,assignments, totCost, indexC, indexF);
        
        dA = changeInArea(assignments, cArea,fArea);
        errorR = setError(dA);
        
        if debug_flag
            visualizeLinking(data_c,data_f,assignments);
        end
        
    end
end





    function [assignments, revAssign] = fixProblems (assignments, revAssign, ...
            totCost, indexF, indexC, cArea, fArea)
        % fixProblems : used to fix cells not assigned to anything.
        
        leftInF = find(cellfun('isempty',revAssign));
        
        for jj = leftInF
            
            bestAssgnC = findBestSingleAssign (jj, totCost, indexF, indexC) ;
            
            if bestAssgnC <= numel(assignments)
                FAlready = assignments{bestAssgnC};
                if isempty(FAlready)
                    assignments{bestAssgnC} = jj;
                else
                    revToAlreadyF = revAssign{FAlready};
                    areaC = sum(cArea(revToAlreadyF));
                    areaFBefore = sum(fArea(FAlready));
                    dABefore = (areaFBefore - areaC)/max(areaFBefore,areaC);
                    
                    if numel(revToAlreadyF) == 2 && ...
                            setError(dABefore)>0
                        % two assigned to other f - steal one
                        areaFjj = fArea(jj);
                        newRevToAlreadyF = revToAlreadyF(revToAlreadyF~=bestAssgnC);
                        newAreaC = cArea(newRevToAlreadyF);
                        areaC = cArea(bestAssgnC);
                        newdAjj = (areaFjj - areaC)/max(areaFjj,areaC);
                        newdAalreadyF = (areaFBefore - newAreaC)/max(areaFBefore,areaC);;
                        if  ~setError(newdAjj) && ...
                                ~setError(newdAalreadyF)
                            assignments{bestAssgnC} = jj;
                            revAssign{jj} = bestAssgnC;
                            revAssign{FAlready} = newRevToAlreadyF;
                        end
                    else
                        % see if assigning both to bestAssgnC solves the problem
                        tempAssgn = [FAlready,jj];
                        areaF = areaFBefore + fArea(jj);
                        dAtmp = (areaF - areaC)/max(areaF,areaC);
                        if  setError(dABefore) > 0 && ...
                                ~setError(dAtmp)
                            % disp (['Assign both  ' ,num2str(jj) , '  ', num2str(FAlready), ' to ' , num2str(bestAssgnC)])
                            assignments{bestAssgnC} = tempAssgn;
                            revAssign{jj} = bestAssgnC;
                        end
                    end
                end
            end
            
        end
        
    end

    function bestAssignC = findBestSingleAssign (value_f, totCost, indexF, indexC)
        
        fAssign =  ((indexF(1,:)== value_f) & (isnan(indexF(2,:))));
        totCost(~fAssign) = NaN;
        [~,indC] = min(totCost);
        bestAssignC = indexC (1,indC);
        
    end

    function errorR = setError(DA)
        if numel(DA) > 0
            errorR = zeros(1, numel(DA));
            errorR (DA < minDA ) = 2;
            errorR (DA > maxDA) = 3;
        else
            errorR = [];
        end
    end

    function dA = changeInArea(assignments, cArea,fArea)
        % change in area set for data_c
        numRegs1 = size(assignments,2);
        dA = nan*zeros(1,numRegs1);
        for ll = 1 : numRegs1
            tmpAssgn =  assignments{ll};
            carea_tmp =  (cArea(ll));
            farea_tmp = sum(fArea(tmpAssgn));
            dA(ll) = (farea_tmp - carea_tmp) / max(carea_tmp,farea_tmp);
        end
        
    end

    function revAssign = getRevAssign()
        revAssign = cell( 1, numRegs2);
        for ll = 1 : numRegs1
            tmpAss =  assignments{ll};
            for uu = tmpAss
                revAssign{uu} = [revAssign{uu},ll];
            end
        end
    end



    function [assignments,revAssign] = exchangeAssignment (assignments,...
            revAssign, totCost, indexF, indexC)
        % finds cells without assignment, and finds their best possible assignment.
        % exchanges assignments for the one that has taken that assignment if
        % it is second best possible choice was also left without assignment.
        
        leftInC = find(cellfun('isempty',assignments));
        leftInF = find(cellfun('isempty',revAssign));
        
        for kk = 1 : numel(leftInC)
            currentCreg = leftInC(kk);
            
            bestF = findBestSingleAssign (currentCreg, totCost, indexC, indexF);
            if ~isempty(bestF)
       
            for badC = 1 : numel(assignments)
                tempAss = assignments{badC};
                if ~isempty(tempAss) && any(tempAss ==bestF)
                    break
                end
            end
            
            flaggerC = (indexC(1,:) == badC) & (isnan(indexC(2,:)));
            flaggerF = (indexF(1,:) == bestF) & (isnan(indexF(2,:)));
            totCostTemp = totCost;
            totCostTemp (~flaggerC) = NaN;
            totCostTemp(flaggerF) = NaN;
            [~,ind] = min(totCostTemp);
            badCSecondF = indexF(:,ind);
            
            if isnan(badCSecondF(2)) &&  any(leftInF == badCSecondF(1))
               % disp (['Exchanging assignment for ', num2str(badC), '  and  ', num2str(currentCreg),  ' ', num2str(bestF)]);
                assignments{badC} = badCSecondF(1);
                revAssign{badCSecondF(1)} = badC;
                revAssign{bestF} = currentCreg;
                assignments{currentCreg} = bestF;
            end
            end
        end
    end




end



function [bbx,bby] = getBoxLimits (data_c,regNums)
% getBoxLimits : returns the bounding box for regNums

regNums = regNums(~isnan(regNums));
comboBoundingBox = [];
ss = size(data_c.phase);
% get total bounding box
for ii = 1: numel(regNums)
    reg = regNums(ii);
    comboBoundingBox = addBB(comboBoundingBox,data_c.regs.props(reg).BoundingBox);
end

pad = 20;
[bbx,bby] =  getBBpad(comboBoundingBox,ss,pad);

end



function [pairsC,neighF] = findNeighborPairs (data_c, numRegs1, regsInC, data_f)
% findNeighborPairs : finds neighboring regions to be considered as pairs

global str8
counter = 1;
pairsC = NaN * zeros(2,numRegs1 * numRegs1);
neighF = cell( 1, numRegs1);
labels_c = data_c.regs.regs_label;
if ~isempty(data_f)
    labels_f = data_f.regs.regs_label;
end

for jj = regsInC
    [bbx,bby] = getBoxLimits (data_c,jj);
    labels_c_box = labels_c(bby,bbx);
    maskc = (labels_c_box==jj);
    tmp_mask = imdilate(maskc, str8);
    neigh = labels_c_box(tmp_mask);% get neighbors
    
    
    ind_neigh = unique(neigh)'; % unique neighbors
    ind_neigh = ind_neigh(ind_neigh > jj); % not already made pairs
    
    if  ~isempty(data_f)
        labels_f_box = labels_f(bby,bbx);
        fneigh = labels_f_box(tmp_mask);
        fneigh = fneigh (fneigh~=0);
        neighF {jj} = unique(fneigh)';
    end
    
    % make pairs
    for uu = ind_neigh
        pairsC(:,counter) = [jj;uu];
        counter = counter + 1;
    end
end

cleanpairIDs = (nansum(pairsC)~=0);
pairsC = pairsC(:,cleanpairIDs);

end


function [comboMask,comboArea,comboCentroid] = regProperties (data_c,regNums,bbx,bby)
% regProperties :  calculates regNums properties : area, mask and centroid

comboCentroid = 0;
comboArea = 0;
regNums = regNums(~isnan(regNums));
regs_labels =  data_c.regs.regs_label(bby,bbx);
comboMask = 0 * (regs_labels);

for ii = 1: numel(regNums)
    reg = regNums(ii);
    comboCentroid = comboCentroid + data_c.regs.props(reg).Centroid;
    comboMask =  comboMask + (regs_labels==reg);
    comboArea = comboArea + data_c.regs.props(reg).Area;
end

comboCentroid = comboCentroid/numel(regNums); % mean centroid
comboMask = (comboMask>0);

end


%         [~,minIndxC] = min(totCost,[],1);
%         % check if it can be added to an assignment?
%         for kk = 1 : numel(leftInF)
%             fToAssign = leftInF(kk);
%             bestAssgn = minIndxC(fToAssign);
%             fAlready = assignments{bestAssgn};
%             tempAssgn = [fAlready,fToAssign];
%             areaF = data_f.regs.props(fAlready).Area + data_f.regs.props(fToAssign).Area;
%             areaC = data_c.regs.props(bestAssgn).Area;
%             dAtmp = (areaF - areaC)/(areaC);
%
%             if  setError(dA(bestAssgn),minDA,maxDA) > 0 && ...
%                  ~setError(dAtmp,minDA,maxDA)
%                 assignments{bestAssgn} = tempAssgn;
%             end
%         end



function visualizeLinking(data_c,data_f,assignments)
figure(1)
clf;
subplot(1,2,1)
imshow(data_c.mask_cell);
subplot(1,2,2)
imshow(data_f.mask_cell);
num_ass = numel(assignments);
randcolor = hsv(256);
markers = {'o','s','d','>','<','^','v','p','h'};

for c = 1 : num_ass
    assF = assignments {c};
    if ~isempty(assF)
        randomMarker = markers{randi(numel(markers),1)};
        randjet = randi(256,1);
        color = randcolor(randjet,:);
        randjet2 = randi(256,1);
        color2 = randcolor(randjet2,:);
        figure(1);
        subplot(1,2,1)
        hold on;
        plot(data_c.regs.props(c).Centroid(1),data_c.regs.props(c).Centroid(2),[randomMarker,'k'],'MarkerFaceColor',color,'MarkerEdgeColor',color2,'MarkerSize',8);
        subplot(1,2,2)
        for i = 1 : numel(assF)
            hold on;
            plot(data_f.regs.props(assF(i)).Centroid(1),data_f.regs.props(assF(i)).Centroid(2),[randomMarker,'k'],'MarkerFaceColor',color,'MarkerEdgeColor',color2,'MarkerSize',8);
        end
    end
end
hold on;
subplot(1,2,1)
title('data-c')
subplot(1,2,2)
title('data-f')

end