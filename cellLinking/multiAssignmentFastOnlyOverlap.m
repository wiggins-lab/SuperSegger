function [assignments,errorR,totCost,allC,allF,DA]  = multiAssignmentFastOnlyOverlap (data_c, data_f, CONST, forward, debug_flag)
% each row is assigned to one column only - starting by the minimum
% possible cost and continuing to the next minimum possible cost.
% works only c - > f (r -> c) not backwards. attempts to map candidates to
% one or two cells, but not the other way around.




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
    DA = zeros(1,numRegs1);
    
    if ~isempty(data_f)
        
        if ~isfield(data_f,'regs')
            data_f = updateRegionFields (data_f,CONST);
        end
        
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

            totAreaF = 0;
            
            areaC = data_c.regs.props(ii).Area;
            
            for kk = possibleMapInd(indexesSort)
                % area change calculation
                revAssign{kk} = [revAssign{kk},ii];
                totAreaF = totAreaF + data_f.regs.props(kk).Area;              
            end
            
            assignments{ii} = possibleMapInd(indexesSort);
            DA(ii) = (totAreaF - areaC)/totAreaF;
            errorR(ii) = setError(DA(ii),minDA,maxDA);
        end
        
        % check area change of f -> c two to 1
        numMapToF = cellfun('length',revAssign);
        moreThan1 = find(numMapToF > 1);
        
        
        for kk = moreThan1
            totAreaC = 0;
            totAreaF = data_f.regs.props(kk).Area;
            for xx = revAssign{kk}
                totAreaC = totAreaC + data_c.regs.props(xx).Area;
            end
            
            DA(ii) = (totAreaC-totAreaF)/totAreaF;
            
            for xx = revAssign{kk}
                errorR(xx) = setError(DA(ii),minDA,maxDA);
            end
        end   
        
        % any resolvable errors - take only two for now
        % probably need to do the opposite for ~forward..
        numMapToC = cellfun('length',assignments);
        errors = find((errorR~=0) & numMapToC == 2);
        for jj = errors
            first_assgn = assignments{jj}(1);
            second_assgn = assignments{jj}(2);
            areaF = data_f.regs.props(first_assgn).Area;
            areaC = data_c.regs.props(jj).Area;
            DA_temp = (areaF - areaC)/areaF;
            error_temp = setError(DA_temp,minDA,maxDA);
            revAss = revAssign{second_assgn};
            if numel(revAss) > 1 && ~error_temp
                 revAss = revAss(revAss~=jj);
                 revAssign{second_assgn}=revAss;
                 assignments{jj} =  assignments{jj}(1);
            end
        end
        
    end
    
    
    
end

% for uu = 1:data_c.regs.num_regs
%     if errorR(uu)
%         intDisplay (data_c,data_f,assignments{uu},uu)
%         pause;
%     end
% end

if debug_flag
    figure(1)
    imshow(data_f.phase,[]);
    figure(2)
    imshow(data_c.phase,[]);   
    figure(3);
    % check out the assignments :)
    for uu = 1:data_c.regs.num_regs
        intDisplay (data_c,data_f,assignments{uu},uu)
        pause;
    end
end


end

function errorR = setError(DA,minDA,maxDA)
errorR = 0;

if (DA < minDA ) 
    errorR  = 2;
elseif (DA > maxDA)
    errorR  = 3;
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






function intDisplay (data_c,data_f,regF,regC)
% reg : maskF
% green : maskC
% blue : all cell masks  in c


maskC = data_c.regs.regs_label*0;
for c = 1 : numel(regC)
    if ~isnan(regC(c))
        maskC = maskC + (data_c.regs.regs_label == regC(c))>0;
    end
end

maskF = data_f.regs.regs_label*0;

if isempty(regF)
    disp('nothing')
    imshow (cat(3,0*ag(maskF),ag(maskC),ag(data_c.mask_cell)));
else
    for f = 1 : numel(regF)
        if ~isnan(regF(f))
            maskF = maskF + (data_f.regs.regs_label == regF(f))>0;
        end
    end
    imshow (cat(3,ag(maskF),ag(maskC),ag(data_c.mask_cell)));
end
end

