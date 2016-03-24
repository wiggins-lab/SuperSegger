function [areaCost,centroidCost,multiCost,assignments,error,areaChange] ...
    = calcRegionOverlap( data_c, data_f, CONST)
% calcRegsInt : calculates the max overlap between data1 and data2 regions
% data 1 and data 2 can be the reverse and current, current and forward
% regions (order does not matter).
%
% INPUT :
%       data1: region (cell) data structure 1s
%       data2 : region (cell) data structure 2
%       CONST :  segmentation constants
% OUTPUT :
%       XX : areal overlap fraction for a region with all other regions
%       map : list of regions that overlap with the current region above the
%      cut off
%       error : 1 if it goes from 2 -> 1 or 2 if it goes from 1 ->2
%       dA : min(A1,A2)/max(A2,A1) between regions of overlap
%       DA : Change in area between regions of overlap
%       dF1 : Change in fluorescence between regions of overlap
%       dF2 : Change in fluorescence between regions of overlap
%       dF1b : Change in fluorescence between regions of overlap
%       dF2b : Change in fluorescence between regions of overlap
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.



% ideas.. area must always increase
% if area shrinks it needs to be matched to two regions in the next frame


DA_MIN            = CONST.trackOpti.DA_MIN;
DA_MAX            = CONST.trackOpti.DA_MAX;
% initialize
areaFactor = 50;

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

if ~isempty( data_c )
    multiCost = cell( 1, data_c.regs.num_regs);
    assignments  = cell( 1, data_c.regs.num_regs);
    error = zeros(1, data_c.regs.num_regs);
    dAmax = zeros(1, data_c.regs.num_regs);
    DAmax = zeros(1, data_c.regs.num_regs);
    
    if ~isempty( data_f )
        loop_ind = 1:data_c.regs.num_regs;
        numRegs1 = data_c.regs.num_regs;
        numRegs2 = data_f.regs.num_regs;
        areaCost = NaN * ones(numRegs1,numRegs2);
        areaChange = NaN * ones(numRegs1,numRegs2);
        centroidCost = NaN * ones(numRegs1,numRegs2);
        error = zeros(1,numRegs1);
        
        for ii = loop_ind % loop through the regions
            % ind : list of regions that overlap with region ii in data 1
            pad = 3;
            [xx,yy] = getBBpad(data_c.regs.props(ii).BoundingBox,size(data_c.phase),pad);
            mask1 = (data_c.regs.regs_label(yy,xx)==ii);
            regs2 = data_f.regs.regs_label(yy,xx); % regions within bounding box
            ind1 = unique(regs2(mask1));
            ind1 = ind1(data_f.regs.num_regs>=ind1); % remove large indices
            ind1 = ind1(~~ind1); % remove 0
            ind1 = ind1';
            
            % consider overlapping regions jj = ind.
            for jj = ind1
                overlapMask = double(regs2==jj); % overlap mask for ii and jj
                areaOverlap = sum(overlapMask(mask1(:))); % area of overlap between jj and ii
                % X is area of overlap / max ( area of ii, area of jj)
                areaCost(ii,jj) = areaOverlap/...
                    max([data_c.regs.props(ii).Area,data_f.regs.props(jj).Area]);
                centroidCost(ii,jj) = sqrt(sum((data_c.regs.props(ii).Centroid -...
                    data_f.regs.props(jj).Centroid).^2));
                areaChange(ii,jj) = abs(data_c.regs.props(ii).Area - data_f.regs.props(jj).Area)/...
                    (data_c.regs.props(ii).Area);
            end
        end
        
        areaCost(areaCost <= 0 ) = NaN;

        map1to2 = centroidCost + areaFactor * 1 ./areaCost + areaChange;
        %[assignment,cTot] = munkres(map1to2);
        [assignment,cTot] = assignByMinimum(map1to2);
        
        
        % get the costs matrix
        multiCost = cell(1,numel(assignment));
        for t = 1 : numel(assignment)
            if assignment(t) ~= 0
                assignments {t} = assignment(t);
                multiCost{t}(1,1) = map1to2(t,assignment(t));
                multiCost{t}(2,1) = 1;
            end
        end
        
        
        % get leftover assignments from frame 1 to 2.
        frame1NoMathces = find(assignment == 0);
        [assignment1extra,~] = assignByMinimum(map1to2(frame1NoMathces,:));
        
        % error = 1, two regions from frame 1 assigned to 1 region in
        % frame2
        for t = 1 : numel(assignment1extra)
            if assignment1extra(t) ~= 0
                frame1reg = frame1NoMathces (t);
                frame2reg = assignment1extra(t);
                assignments {frame1reg} = frame2reg;
                multiCost{frame1reg}(1,1) = map1to2(frame1reg,frame2reg);
                multiCost{frame1reg}(2,1) = 1;
                error(frame1reg) = 1;
                error(find(assignment==frame2reg)) = 1;
            end
        end
        
        
        reg2labels = 1:numRegs2;
        map2to1 = map1to2';
        frame2NoMatches = setdiff(reg2labels,assignment);
        [assignment2extra,~] = assignByMinimum(map2to1(frame2NoMatches,:));
        
        % error = 2, two regions from frame 2 assigned to 1 region in
        % frame 1
        for t = 1 : numel(assignment2extra)
            if assignment2extra(t) ~= 0
                frame2reg = frame2NoMatches (t);
                frame1reg = assignment2extra(t);
                
                tempAssignArray = assignments{frame1reg};
                tempAssignElements = numel(tempAssignArray);
                tempAssignArray(tempAssignElements + 1) = frame2reg;
                assignments{frame1reg} = tempAssignArray;
                
                tempCostArray = multiCost{frame1reg}(1,:);
                tempCostArray2 = multiCost{frame1reg}(2,:);
                
                numElem = numel(tempCostArray)+1;
                tempCostArray(numElem) = frame2reg;
                tempCostArray2(numElem) = numElem;
                multiCost{frame1reg}(1,1:numElem) = tempCostArray;
                multiCost{frame1reg}(2,1:numElem) = tempCostArray2;
                error(frame1reg) = 1;
            end
        end
        
        
        dA = cell(1,numel(assignment));
        DA = cell(1,numel(assignment));
        dAmax = NaN * ones(1,numel(assignment));
        DAmax = NaN * ones(1,numel(assignment));
        
        for ind1 = 1 : size(assignments,2)
            assignInd = assignments{ind1};
            if assignInd ~= 0
                dA_temp = NaN * ones(numel(assignInd));
                DA_temp = NaN * ones(numel(assignInd));
                
                for ll = 1 : numel(assignInd)
                    ind2 = assignInd(ll);
                    % calculate change in areas
                    dA_temp(ll) =  min([data_c.regs.props(ind1).Area,data_f.regs.props(ind2).Area])/...
                        max([data_c.regs.props(ind1).Area,data_f.regs.props(ind2).Area]);
                    % difference in areas over area of region ii
                    DA_temp(ll) =  (data_f.regs.props(ind2).Area-data_c.regs.props(ind1).Area)/...
                        data_c.regs.props(ind1).Area;
                end
                if size(dA_temp)>0
                    dAmax(ind1) = dA_temp(1);
                    DAmax(ind1) = DA_temp(1);
                end
                % error3
                if error(ind1) == 0 && (any (DA_temp < DA_MIN) || any( DAmax > DA_MAX))
                    error(ind1) = 1;
                end
                dA {ind1} = dA_temp;
                DA {ind1} = DA_temp;
            end
        end
        
        data_c.regs.L1(ii)= data_c.regs.info(ii,1);
        data_c.regs.L2(ii)= data_c.regs.info(ii,2);
        if CONST.trackOpti.NEIGHBOR_FLAG
            try
                data_c.regs.neighbors{ii} = trackOptiNeighbors(data_c,ii);
                data_c.regs.contact(ii)  = numel(data_c.regs.neighbors{ii});
            catch
                disp('Error in neighbor calculation in trackOptiIntDiskNR.m');
            end
            
        end
        
        
    end
    
    
end

    function showAssignments(multiAssignments)
        
        for i = 1 : size(multiAssignments,2)
            
            mask1 = (data_c.regs.regs_label==i);
            assigned = multiAssignments{i};
            
            mask2 = double(0 * data_c.phase) ;
            for a = 1 : numel(assigned)
                mask2 = double(data_f.regs.regs_label==assigned(a)) + mask2;
            end
            
            figure(1)
            imshow( cat(3, 0.8*ag(data_c.phase) + 0.5*ag(data_c.mask_cell-mask1), ...
                0.8*ag(data_c.phase), ...
                0.8*ag(data_c.phase)+ag(mask1)) , 'InitialMagnification', 'fit');
            
            figure(2)
            imshow( cat(3, 0.8*ag(data_f.phase) + 0.5*ag(data_f.mask_cell-mask2), ...
                0.8*ag(data_f.phase), ...
                0.8*ag(data_f.phase)+ag(mask2)) , 'InitialMagnification', 'fit');
            pause;
        end
    end
end



function error = generateError(map,DA,CONST)
% genError : generates error for regions if mapping or DA is incorrect.
% The error is generated if the number of regions mapping to the region are
% not 1 or if difference in the areas is not within the min and max in
% the constants.
%
% INPUT :
%       map: contains region numbers for mapping in the order of amount of overlap
%       DA : difference in areas between the regions
%       CONST :  Segmentation Constants
% OUTPUT :
%       error : list of 0 if no error or 1 if there is an error
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


if isempty( map )
    error = [];
else
    num_regs = numel(map);
    numMapped  = zeros(1,num_regs);
    
    for ii = 1:num_regs;
        numMapped(ii) = numel(map{ii});
    end
    
    DA_MIN            = CONST.trackOpti.DA_MIN;
    DA_MAX            = CONST.trackOpti.DA_MAX;
    error = or(numMapped ~= 1, or(DA < DA_MIN, DA > DA_MAX));
end
end



