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


global minDA
global maxDA

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
        
        for ii = 1:numRegs1 % loop through the regions
            
            [maskC,areaC,~] = regProperties (data_c,ii);
            
            % overlapping regions in f
            tmpregs2 = data_f.regs.regs_label(maskC);
            possibleMapInd = unique(tmpregs2);
            possibleMapInd = possibleMapInd(possibleMapInd~=0)'; % remove 0
            overlapAreaNorm = zeros(numel(possibleMapInd));
            
            for uu = 1: numel(possibleMapInd)
                % one to one mapping
                regInF = possibleMapInd(uu);
                [maskF,areaF,~] = regProperties (data_f,regInF);
                overlapMask = maskF(maskC);
                areaOverlap = sum(overlapMask(:)); % area of overlap between jj and ii
                overlapAreaNorm(uu) = areaOverlap/max(areaC,areaF);
                totCost (ii, uu ) = 1/overlapAreaNorm(uu);
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
                tmpError = setError(tmpdA,minDA,maxDA);
                
                
                if numel(tmpError) > 0 && tmpError(1) == 0
                    assignments{ii} = tmpAssign(1);
                    revAssign{tmpAssign(1)} = [revAssign{tmpAssign(1)},ii];
                    errorR(ii) =  tmpError(1) ;
                    dA(ii) = tmpdA(1);
                    
                elseif numel(tmpError) > 1 && tmpError(2) == 0
                    assignments{ii} = tmpAssign(1:2);
                    revAssign{tmpAssign(1)} = [revAssign{tmpAssign(1)},ii];
                    revAssign{tmpAssign(2)} = [revAssign{tmpAssign(2)},ii];
                    errorR(ii) =  tmpError(2) ;
                    dA(ii) = tmpdA(2);
                    
                else
                    assignments{ii} = tmpAssign(1);
                    revAssign{tmpAssign(1)} = [revAssign{tmpAssign(1)},ii];
                    errorR(ii) =  tmpError(1);
                    dA(ii) = tmpdA(1);
                end
            end
        end
    end
    
    
    
    
    if debug_flag
        visualizeLinking(data_c,data_f,assignments);
    end
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
markers = {'o','s','d','>','<','^','v','p','h'}

for c = 1 : num_ass
    assF = assignments {c};
    if ~isempty(assF)
        randomMarker = markers{randi(numel(markers),1)};
        randjet = randi(256,1);
        color = randcolor(randjet,:)
        figure(1);
        subplot(1,2,1)
        hold on;
        plot(data_c.regs.props(c).Centroid(1),data_c.regs.props(c).Centroid(2),[randomMarker,'k'],'MarkerFaceColor',color,'MarkerSize',8);
        subplot(1,2,2)
        for i = 1 : numel(assF)
            hold on;
            plot(data_f.regs.props(assF(i)).Centroid(1),data_f.regs.props(assF(i)).Centroid(2),[randomMarker,'k'],'MarkerFaceColor',color,'MarkerSize',8);
        end
    end
end
end

function errorR = setError(DA,minDA,maxDA)
errorR = zeros(1, numel(DA));
errorR (DA < minDA ) = 2;
errorR (DA > maxDA) = 3;
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
