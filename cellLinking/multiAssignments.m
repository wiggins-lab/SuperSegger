function [assignment,cost]  = multiAssignments (data_c, data_f)
% each row is assigned to one column only - starting by the minimum
% possible cost and continuing to the next minimum possible cost.

debug_flag = 1

assignments = [];
error = [];
dA = {};
DA={};
dAmax=[];
DAmax=[];
areaCost=[];
areaChange = [];
centroidCost = [];
multiCost = {};
multiCost = cell( 1, data_c.regs.num_regs);
assignments  = cell( 1, data_c.regs.num_regs);
error = zeros(1, data_c.regs.num_regs);
dAmax = zeros(1, data_c.regs.num_regs);
DAmax = zeros(1, data_c.regs.num_regs);
loop_ind = 1:data_c.regs.num_regs;
numRegs1 = data_c.regs.num_regs;
numRegs2 = data_f.regs.num_regs;
areaOverlapCost = NaN * ones(numRegs1,numRegs2);
areaChange = NaN * ones(numRegs1,numRegs2);
centroidCost = NaN * ones(numRegs1,numRegs2);
error = zeros(1,numRegs1);


for ii = 1:numRegs1 % loop through the regions
    % ind : list of regions that overlap with region ii in data 1
    pad = 3;
    [xx,yy] = getBBpad(data_c.regs.props(ii).BoundingBox,size(data_c.phase),pad);
    mask1 = (data_c.regs.regs_label(yy,xx)==ii);
    
    
    % get overalping regions in data_f with ii in data_c
    regs2 = data_f.regs.regs_label(yy,xx);
    ind1 = unique(regs2);
    ind1 = ind1(data_f.regs.num_regs>=ind1); % remove large indices
    ind1 = ind1(~~ind1); % remove 0
    ind1 = ind1';
    
    for jj = ind1 % regions in data_f
        overlapMask = double(regs2(mask1)==jj); % overlap mask for ii and jj
        areaOverlap = sum(overlapMask(:)); % area of overlap between jj and ii
        % X is area of overlap / max ( area of ii, area of jj)
        areaOverlapCost(ii,jj) = areaOverlap/...
            max([data_c.regs.props(ii).Area,data_f.regs.props(jj).Area]);
        centroidCost(ii,jj) = sqrt(sum((data_c.regs.props(ii).Centroid -...
            data_f.regs.props(jj).Centroid).^2));
        areaChange(ii,jj) = abs(data_c.regs.props(ii).Area - data_f.regs.props(jj).Area)/...
            (data_c.regs.props(ii).Area);
    end
end


totCost = 50 * 1./areaOverlapCost + centroidCost;

% assignments
assignments = cell(1,data_c.regs.num_regs);
for ii = 1:data_c.regs.num_regs
    % get first 5 minimum costs
    cost = totCost(ii,:);
    [sortedCost, indices] = sort(cost,'ascend');
    indices = indices (~isnan(sortedCost));
    sortedCost = sortedCost (~isnan(sortedCost));
    if ~isempty(sortedCost)
        for jj = 1 : size(sortedCost,2)
            % is this the best choice for jj? then add it the assignments
            j = indices(jj)
            costJJ = totCost(:,j)
            [~,ci] = min(costJJ);
            if ci == ii
                temp = assignments {ii};
                temp = [temp,j];
                assignments {ii} = temp;
            end
            
            % if the dA decreases with the assignments I got so far.. I may
            % have lost the other daughter..  see if you can find it?
        end
    end
end


if debug_flag
    figure(1)
    imshow(data_f.phase,[]);
    figure(2)
    imshow(data_c.phase,[]);
    
    figure(3);
    % check out the assignments :)
    for ii = 1:data_c.regs.num_regs
        regF = assignments {ii};
        if isempty(regF)
            disp('nothing')
            imshow (cat(3,0*ag(maskF),ag(data_c.regs.regs_label==ii),ag(data_c.mask_cell)));
            pause
        else
            maskF = data_f.regs.regs_label*0;
            for f = 1 : numel(regF)
                maskF = maskF + (data_f.regs.regs_label == regF(f))>0;
            end
            
            imshow (cat(3,ag(maskF),ag(data_c.regs.regs_label==ii),ag(data_c.mask_cell)));
            pause;
        end
    end
end

end