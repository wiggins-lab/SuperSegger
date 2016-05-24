function [assignments,errorR,totCost,allC,allF,dA,revAssign]  = multiAssignmentFastOnlyOverlap (data_c, data_f, CONST, forward, debug_flag)
% multiAssignmentPairs : links regions in data_c to regions in data_f.
% Each row is assigned to one column only - starting by the minimum
% possible cost and continuing to the next minimum possible cost.
%
% INPUT :
%    (data_c, data_f,CONST, forward, debug_flag)
%
% OUTPUT :
%   [assignments,errorR,totCost,allC,allF]
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


DA_MIN = CONST.trackOpti.DA_MIN;
DA_MAX =  CONST.trackOpti.DA_MAX;
OVERLAP_LIMIT_MIN = CONST.trackOpti.OVERLAP_LIMIT_MIN;


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
allC=[];
allF=[];


if ~isempty(data_c)
    
    if ~isfield(data_c,'regs')
        data_c = updateRegionFields (data_c,CONST);
    end
    
    numRegs1 = data_c.regs.num_regs;
    assignments = cell( 1, numRegs1);
    
    errorR = zeros(1,numRegs1);
    dA = zeros(1,numRegs1);
    
    if ~isempty(data_f)
        
        if ~isfield(data_f,'regs')
            data_f = updateRegionFields (data_f,CONST);
        end
        
        areaMat = [data_f.regs.props(:).Area];
        numRegs2 = data_f.regs.num_regs;
        allC = 1:data_c.regs.num_regs;
        allF = 1:data_f.regs.num_regs;
        revAssign = cell(1, numRegs2);
        totCost = NaN * zeros (numRegs1,numRegs2);
        ss = size(data_c.phase);
        for ii = 1:numRegs1 % loop through the regions
            BB = data_c.regs.props(ii).BoundingBox;
            [BBxx,BByy] = getBBpad( BB,ss,5);
            tmpc_labels = data_c.regs.regs_label(BByy,BBxx);
            maskC =  (tmpc_labels == ii);
            areaC =  data_c.regs.props(ii).Area;
            
            %[maskC,areaC,~] = regProperties (data_c,ii);
            
            % overlapping regions in f
            tmpf_labels = data_f.regs.regs_label(BByy,BBxx);
            tmpregs2 = tmpf_labels(maskC);
            possibleMapInd = unique(tmpregs2);
            possibleMapInd = possibleMapInd(possibleMapInd~=0)'; % remove 0
            overlapAreaNorm = zeros(1,numel(possibleMapInd));
            
            for uu = 1: numel(possibleMapInd)
                % one to one mapping
                regInF = possibleMapInd(uu);
                maskF =  (tmpf_labels == regInF);
                areaF =  data_f.regs.props(regInF).Area;
                overlapMask = maskF(maskC);
                areaOverlap = sum(overlapMask(:)); % area of overlap between jj and ii
                overlapAreaNorm(uu) = areaOverlap/max(areaC,areaF);
                totCost (ii, regInF ) = 1/overlapAreaNorm(uu);
            end
            
            [overlapAreaNormSort, indexesSort] = sort(overlapAreaNorm,'descend');
            indexesSort = indexesSort(overlapAreaNormSort>OVERLAP_LIMIT_MIN);
            tmpAssign = possibleMapInd(indexesSort);
            
            % one - to - one mapping
            if ~isempty(tmpAssign)
                tmpAreaF = areaMat(tmpAssign);
                totAreaF = cumsum(tmpAreaF);
                areaC = data_c.regs.props(ii).Area;
                tmpdA = (totAreaF-areaC)./totAreaF;
                tmpError = setError(tmpdA);
                
                
                if numel(tmpError) > 0 && tmpError(1) == 0
                    assignments{ii} = tmpAssign(1);
                    revAssign{tmpAssign(1)} = [revAssign{tmpAssign(1)},ii];
                elseif numel(tmpError) > 1 && tmpError(2) == 0
                    assignments{ii} = tmpAssign(1:2);
                    revAssign{tmpAssign(1)} = [revAssign{tmpAssign(1)},ii];
                    revAssign{tmpAssign(2)} = [revAssign{tmpAssign(2)},ii];
                else
                    assignments{ii} = tmpAssign(1);
                    revAssign{tmpAssign(1)} = [revAssign{tmpAssign(1)},ii];
                end
            end
        end
        
        
        [~,minIndxF] = min(totCost,[],2);
        [~,minIndxC] = min(totCost,[],1);
        cArea = [data_c.regs.props.Area];
        fArea = [data_f.regs.props.Area];
        
        [assignments,revAssign] =fixProblems(assignments,revAssign,minIndxC, cArea, fArea);
        [revAssign,assignments] =fixProblems(revAssign,assignments,minIndxF, fArea, cArea);
        
        dA = changeInArea(assignments, cArea,fArea);
        errorR = setError(dA);
    end
    
    % if something assigned to two...
    
    
    
    if debug_flag
        visualizeLinking(data_c,data_f,assignments);
    end 
end



    function [assignments, revAssign] =fixProblems (assignments, revAssign, minIndxC, cArea, fArea)
        
        leftInF = find(cellfun('isempty',revAssign));
        
        for jj = leftInF
            bestAssgnC = minIndxC(jj);
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
                        assignments{bestAssgnC} = tempAssgn;
                        revAssign{jj} = bestAssgnC;
                    end
                end
            end
            
        end
        
    end

    function errorR = setError(DA)
        errorR = zeros(1, numel(DA));
        errorR (DA < minDA ) = 2;
        errorR (DA > maxDA) = 3;
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
        randNum = randi(256,1);
        color = randcolor(randNum,:);
        figure(1);
        subplot(1,2,1);
        hold on;
        plot(data_c.regs.props(c).Centroid(1),data_c.regs.props(c).Centroid(2),[randomMarker,'k'],'MarkerFaceColor',color,'MarkerSize',8);
        subplot(1,2,2);
        for i = 1 : numel(assF)
            hold on;
            plot(data_f.regs.props(assF(i)).Centroid(1),data_f.regs.props(assF(i)).Centroid(2),[randomMarker,'k'],'MarkerFaceColor',color,'MarkerSize',8);
        end
    end
end
end

function [comboMask,comboArea,comboCentroid] = regProperties (data_c,regNums)
comboCentroid = 0;
comboMask = 0 * (data_c.regs.regs_label);
comboArea = 0;
regNums = regNums(~isnan(regNums));
for ii = 1: numel(regNums)
    reg = regNums(ii);
    comboCentroid = comboCentroid + data_c.regs.props(reg).Centroid;
    comboMask =  comboMask + (data_c.regs.regs_label==reg);
    comboArea = comboArea + data_c.regs.props(reg).Area;
end

comboCentroid = comboCentroid/numel(regNums); % mean centroid
comboMask = (comboMask>0);
end
