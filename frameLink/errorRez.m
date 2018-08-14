function [data_c, data_r, cell_count,resetRegions] =  errorRez (time, ...
    data_c, data_r, data_f, CONST, cell_count, header, ignoreError, debug_flag)
% errorRez : links cells from the current frame to the frame before and
% attempts to resolve segmentation errors if the linking is inconsistent.
%
% INPUT :
%   time : current frame number
%   data_c : current time frame data (seg/err) file.
%   data_r : reverse time frame data (seg/err) file.
%   data_f : forward time frame data (seg/err) file.
%   CONST : segmentation parameters.
%   cell_count : last cell id used.
%   header : last cell id used.
%   ignoreError : when set to true, no cells are merged or divided.
%   debug_flag : 1 to display figures for debugging
%
% OUTPUT :
%   data_c : updated current time frame data (seg/err) file.
%   data_r : updated reverse time frame data (seg/err) file.
%   cell_count : last cell id used.
%   resetRegions : if true, regions were modified and this frame needs to
%   be relinked.
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

global REMOVE_STRAY
global header_string
global regToDelete

header_string = header;
verbose = CONST.parallel.verbose;
REMOVE_STRAY = CONST.trackOpti.REMOVE_STRAY;
DA_MIN = CONST.trackOpti.DA_MIN;
DA_MAX =  CONST.trackOpti.DA_MAX;
regToDelete = [];
resetRegions = false;
minAreaToMerge = CONST.trackOpti.SMALL_AREA_MERGE;

% set all ids to 0
cArea = [data_c.regs.props.Area];
data_c.regs.ID = zeros(1,data_c.regs.num_regs);
modRegions = [];

for regNum =  1 : data_c.regs.num_regs
    
%     if regNum == 37;
%         'hi'
%     end
    
    if isfield (data_c.regs, 'manual_link')
        manual_link = data_c.regs.manual_link.r(regNum);
    else
        manual_link = 0;
    end
    if data_c.regs.ID(regNum) ~= 0
        disp ([header, 'ErRes: Frame: ', num2str(time), ' already has an id ',num2str(regNum)]);
    elseif ismember (regNum,modRegions)
        disp ([header, 'ErRes: Frame: ', num2str(time), ' already modified ',num2str(regNum)]);
    else
        
        rCellsFromC = data_c.regs.map.r{regNum}; % where regNum maps in reverse
        if ~isempty(rCellsFromC)
            cCellsFromR = data_r.regs.map.f{rCellsFromC};
            cCellsTransp = data_c.regs.revmap.r{rCellsFromC};
        else
            cCellsFromR = [];
            cCellsTransp = [];
        end
        
        if numel(rCellsFromC) == 0 % maps to 0 in the previous frame - stray
            % think whether this is useful :  numel(mapRC) == 0
            if (time ~= 1) && (hasNoFwMapping(data_c,regNum) && REMOVE_STRAY)
                % deletes the regions not appearing at time = 1 that do not map to anything
                % or if remove_stray flag is set to true.
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time), ...
                    ', reg: ', num2str(regNum), '. is a stray region - Deleted.'];
                if verbose
                    disp([header, 'ErRes: ',data_c.regs.error.label{regNum}] );
                end
                regToDelete = [regToDelete;regNum];
                resetRegions = true;
            else % maps to a region in the next frame, or time is 1
                if time~=1
                    data_c.regs.error.label{regNum} = ['Frame: ', num2str(time), ...
                        ', reg: ', num2str(regNum), '. is a stray region.'];
                    if verbose
                        disp([header, 'ErRes: ',data_c.regs.error.label{regNum}] );
                    end
                end
                [data_c,cell_count] = createNewCell (data_c, regNum, time, cell_count);
            end
        elseif numel(rCellsFromC) == 1 && numel (cCellsTransp) == 1
            % Maps to one in the previous frame.
            % Sets cell ID from mapped reg, updates death in data_r
            errorStat = (data_c.regs.error.r(regNum)>0);
            [data_c, data_r] = continueCellLine(data_c, regNum, data_r,...
                rCellsFromC, time, errorStat);
        elseif numel(rCellsFromC) == 1 && numel(cCellsFromR) == 1 && ...
                numel (cCellsTransp) == 2
            % Cell (regNum) and another cell in current frame map to one
            % in reverse but one cell in reverse, but reverse cell only
            % maps to one of them forward.
            sister1 = regNum;
            sister2 = cCellsTransp (cCellsTransp~=regNum);
            mapRC = cCellsTransp;
            mother = rCellsFromC;
            
            if debug_flag
                % red in c maps to blue in r, blue in r maps to green in c
                imshow(cat(3,0.5*ag(data_c.phase) + 0.5*ag(data_c.regs.regs_label==sister1),...
                    ag(data_r.regs.regs_label == mother),ag(data_c.regs.regs_label==sister2)));
            end
            
            totAreaC = data_c.regs.props(sister1).Area + data_c.regs.props(sister2).Area;
            totAreaR =  data_r.regs.props(mother).Area;
            AreaChange = (totAreaC-totAreaR)/totAreaC;
            goodAreaChange = (AreaChange > DA_MIN && AreaChange < DA_MAX);
            haveNoMatch = (isempty(data_c.regs.map.f{sister1}) || isempty(data_c.regs.map.f{sister2}));
            matchToTheSame = ~haveNoMatch && all(ismember(data_c.regs.map.f{sister1}, data_c.regs.map.f{sister2}));
            oneIsSmall = (cArea(sister1) < minAreaToMerge) || (cArea(sister2) < minAreaToMerge);
            doNotAllowMerge =  ignoreError || manual_link;
            if goodAreaChange && ~doNotAllowMerge && ...
                    ~isempty(data_f) && (haveNoMatch || matchToTheSame || oneIsSmall)
                % r: one has no forward mapping, or both map to the same in fw, or one small
                % wrong division merge cells
                [data_c,mergeReset] = merge2Regions (data_c, [sister1, sister2], CONST);
                modRegions = [modRegions;col(cCellsTransp)];
                resetRegions = (resetRegions || mergeReset);
            elseif goodAreaChange || manual_link
                % Divide if
                [data_c, data_r, cell_count] = createDivision (data_c, data_r, mother, sister1, sister2, cell_count, time, header, verbose);
                modRegions = [modRegions;col(cCellsTransp)];
            else
                % map to best, remove mapping from second
                [data_c,data_r,cell_count,reset_tmp,modids_tmp] = mapBestOfTwo (data_c, mapRC, data_r, rCellsFromC, time, verbose, cell_count,header,data_f);
                resetRegions = or(reset_tmp,resetRegions);
                modRegions = [modRegions;col(modids_tmp)];
            end
        elseif numel(rCellsFromC) == 1 && numel(cCellsFromR) == 2
            % the 1 in reverse maps to two in current : possible splitting event
            mother = rCellsFromC;
            sister1 = regNum;
            mapRC = data_r.regs.map.f{mother};
            sister2 = mapRC (mapRC~=regNum);
            sister2Mapping = data_c.regs.map.r{sister2};
            
            if numel(sister2) == 1 && any(mapRC==regNum) && ~isempty(sister2Mapping) && all(sister2Mapping == mother)
                
                totAreaC = data_c.regs.props(sister1).Area + data_c.regs.props(sister2).Area;
                totAreaR =  data_r.regs.props(mother).Area;
                AreaChange = (totAreaC-totAreaR)/totAreaC;
                goodAreaChange = (AreaChange > DA_MIN && AreaChange < DA_MAX);
                haveNoMatch = ~isempty(data_f) && (isempty(data_c.regs.map.f{sister1}) || isempty(data_c.regs.map.f{sister2}));
                matchToTheSame = ~isempty(data_f) && ~haveNoMatch && all(ismember(data_c.regs.map.f{sister1}, data_c.regs.map.f{sister2}));
                oneIsSmall = (cArea(sister1) < minAreaToMerge) || (cArea(sister2) < minAreaToMerge);
                doNotAllowMerge =  ignoreError || manual_link;
                if goodAreaChange && ~doNotAllowMerge && (haveNoMatch || matchToTheSame || oneIsSmall)
                    % wrong division merge cells
                    if ~ignoreError
                        [data_c,reset_tmp] = merge2Regions (data_c, [sister1, sister2], CONST);
                        modRegions = [modRegions;col(mapRC) ];
                    else
                        [data_c,data_r,cell_count,reset_tmp,modids_tmp] = mapBestOfTwo (data_c, mapRC, data_r, rCellsFromC, time, verbose, cell_count,header,data_f);
                        modRegions = [modRegions;col(modids_tmp)];
                    end
                    resetRegions = or(reset_tmp,resetRegions);
                else
                    [data_c, data_r, cell_count] = createDivision (data_c,data_r,mother,sister1,sister2, cell_count, time,header, verbose);
                    modRegions = [modRegions;col(mapRC) ];
                end
            elseif numel(sister2) == 1 && any(mapRC==regNum) && any(data_c.regs.map.r{sister2} ~= mother)
                % map the one-to-one to mother
                errorStat = (data_c.regs.error.r(regNum)>0);
                [data_c, data_r] = continueCellLine( data_c, regNum, data_r, rCellsFromC, time, errorStat);
                
            elseif  ~any(mapRC==regNum)
                % ERROR NOT FIXED :  mapCR maps to mother. but mother maps to
                % two other cells.
                % OTHER POSSIBLE RESOLUTIONS :
                % 1 : merging missing, cell divided but piece fell out - check
                % if all three should be mapped
                % 2 : map the best two cells out of the three.
                
                % force mapping
                sister1 = regNum;
                sister2 = mapRC(1);
                sister3 = mapRC(2);
                
                % make a new cell for regNum with error.
                [data_c,cell_count] = createNewCell (data_c, regNum, time, cell_count);
                data_c.regs.error.r(regNum) = 1;
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                    ', reg: ', num2str(regNum),'. Incorrect Mapping 1 to 2 - making a new cell'];
                
                if verbose
                    disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
                end
                % red : regNum, green : ones mother maps to, blue : mother
                if debug_flag
                    imshow(cat(3,0.5*ag(data_c.phase) + 0.5*ag(data_c.regs.regs_label==regNum), ...
                        ag((data_c.regs.regs_label == mapRC(1)) + ...
                        (data_c.regs.regs_label==mapRC(2))),ag(data_r.regs.regs_label==mother)));
                end
            else
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                    ', reg: ', num2str(regNum),'. Error not fixed - two to 1 but don''t know what to do.'];
                
                if verbose
                    disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
                end
                
            end
        elseif numel(rCellsFromC) > 1
            % 1 in current maps to two in reverse
            % try to find a segment that should be turned on in current
            % frame, exit regNum loop, make time - 1 and relink
            
            if debug_flag
                imshow(cat(3,0.5*ag(data_c.phase), 0.7*ag(data_c.regs.regs_label==regNum),...
                    ag((data_r.regs.regs_label==rCellsFromC(1)) + (data_r.regs.regs_label==rCellsFromC(2)))));
            end
            
            if ~ignoreError
                [data_c,success] = missingSeg2to1 (data_c,regNum,data_r,rCellsFromC,CONST);
            else
                success = false;
            end
            
            if success % segment found
                data_c.regs.error.r(regNum) = 0;
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                    ', reg: ', num2str(regNum),'. Segment added to fix 2 to 1 error'];
                if verbose
                    disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
                end
                if debug_flag
                    imshow(cat(3,ag(data_c.regs.regs_label == regNum)+0.5*ag(data_c.phase),...
                        ag(data_r.regs.regs_label == rCellsFromC(1)),...
                        ag(data_r.regs.regs_label == rCellsFromC(2))));
                end
                resetRegions = true;
            else
                % Error could not be fixed: link to the one with the best
                % score.
                [data_c,data_r] = mapToBestOfTwo (data_c, regNum, data_r, rCellsFromC, time, verbose,header);
            end
        elseif numel(rCellsFromC) == 1 && numel(cCellsFromR) > 2
            haveNoMatch = any(isempty({data_c.regs.map.f{cCellsFromR}}));
            forwMap = [data_c.regs.map.f{cCellsFromR}];
            forwardMap = unique(forwMap);
            occur = histc(forwMap,forwardMap);
            matchToTheSame = ~haveNoMatch && numel(forwardMap)==1;
            someMatchToSame = ~haveNoMatch && any(occur>1);
            % r: one has no forward mapping, or both map to the same in fw
            if  ~isempty(data_f) && (haveNoMatch || matchToTheSame)
                if ~ignoreError
                    % wrong division merge cells
                    [data_c,reset_tmp] = merge2Regions (data_c, cCellsFromR, CONST);
                    modRegions = [modRegions;col(cCellsFromR)];
                else
                    [data_c,data_r,cell_count,reset_tmp,modids_tmp] = mapBestOfTwo (data_c, cCellsTransp, data_r, rCellsFromC, time, verbose, cell_count,header,data_f);
                    modRegions = [modRegions;col(modids_tmp)];
                end
                resetRegions = or(reset_tmp,resetRegions);
            elseif ~isempty(data_f) && (someMatchToSame)
                indFwMap = find(occur>1);
                valueFw = forwardMap(indFwMap);
                cellsToMerge = [];
                for i = 1 : numel(cCellsFromR)
                    cur_cell = cCellsFromR(i);
                    if any(data_c.regs.map.f{cur_cell} == valueFw)
                        cellsToMerge = [cellsToMerge ;cur_cell];
                    end
                    
                end
                [data_c,reset_tmp] = merge2Regions (data_c, cellsToMerge, CONST);
                modRegions = [modRegions;col(cellsToMerge)];
                resetRegions = or(reset_tmp,resetRegions);
            end
        else
            data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                ', reg: ', num2str(regNum),'. Error not fixed'];
            
            if verbose
                disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
            end
            if debug_flag
                intDisplay (data_r,rCellsFromC,data_c,regNum);
                
            end
            
        end
    end
    
    % if the current ID is still zero, make a new cell
    if data_c.regs.ID(regNum) == 0
          [data_c,cell_count] = createNewCell (data_c, regNum, time, cell_count);        
    end
    
end
%intDisplay (data_c,regToDelete,data_f,[]);
[data_c] = deleteRegions( data_c,regToDelete);

end



function intDisplay (data_c,regC,data_f,regF)
% intDisplay : displays linking
% reg : maskF
% green : maskC
% blue : all cell masks  in c



maskC = data_c.regs.regs_label*0;
for c = 1 : numel(regC)
    if ~isnan(regC(c))
        maskC = maskC + (data_c.regs.regs_label == regC(c))>0;
    end
end

if ~isempty (data_f)
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
end




function [ data_c, data_r, cell_count ] = createDivision (data_c,data_r,mother,sister1,sister2, cell_count, time, header, verbose)

data_c.regs.error.label{sister1} = (['Frame: ', num2str(time),...
    ', reg: ', num2str(sister1),' and ', num2str(sister2),' . cell division from mother reg', num2str(mother),'. [L1,L2,Sc] = [',...
    num2str(data_c.regs.L1(sister1),2),', ',num2str(data_c.regs.L2(sister1),2),...
    ', ',num2str(data_c.regs.scoreRaw(sister1),2),'].']);
if verbose
    disp([header, 'ErRes: ', data_c.regs.error.label{sister1}] );
end
data_r.regs.error.r(mother) = 0;
data_c.regs.error.r(sister1) = 0;
data_c.regs.error.r(sister2) = 0;
[data_c, data_r, cell_count] = markDivisionEvent( ...
    data_c, sister1, data_r, mother, time, 0, sister2, cell_count);

end


function result = hasNoFwMapping (data_c,regNum)
result = isempty(data_c.regs.map.f{regNum});
end


function [data_c,data_r] = mapToBestOfTwo (data_c, regNum, data_r, mapCR, time, verbose,header)
% maps to best from two forward
flaggerC = (data_c.regs.idsC.r(1,:) == regNum) & isnan(data_c.regs.idsC.r(2,:));
flaggerR1 = (data_c.regs.idsR.r(1,:) == mapCR(1)) & isnan(data_c.regs.idsR.r(2,:));
flaggerR2 = (data_c.regs.idsR.r(1,:) == mapCR(2)) & isnan(data_c.regs.idsR.r(2,:));

loc1 = flaggerC&flaggerR1;
loc2 = flaggerC&flaggerR2;
cost1 = data_c.regs.cost.r(loc1);
cost2 = data_c.regs.cost.r(loc2);

if isempty(cost2) || cost1<cost2 || isnan(cost2)
    data_c.regs.error.r(regNum) = 2;
    errorStat = 1;
    data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
        ', reg: ', num2str(regNum),'. Map to minimum cost'];
    
    if verbose
        disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
    end
    [data_c, data_r] = continueCellLine(data_c, regNum, data_r, mapCR(1), time, errorStat);
    
else
    errorStat = 1;
    data_c.regs.error.r(regNum) = 2;
    data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
        ', reg: ', num2str(regNum),'. Map to minimum cost'];
    
    if verbose
        disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
    end
    
    [data_c, data_r] = continueCellLine(data_c, regNum, data_r, mapCR(2), time, errorStat);
    
end
end


function [data_c,data_r,cell_count,resetRegions,idsOfModRegions] = mapBestOfTwo ...
    (data_c, mapRC, data_r, mapCR, time, verbose, cell_count,header,data_f)
% Cell in reverse is mapped to the best of the cells in current. The other
% cells are made into new cells.
global regToDelete
global REMOVE_STRAY
resetRegions = 0;
[~,minInd] = min (data_c.regs.dA.r(mapRC));
keeper = mapRC(minInd);
remove = mapRC(mapRC~=keeper);
errorStat = (data_c.regs.error.r(keeper)>0);
[data_c, data_r] = continueCellLine( data_c, keeper, data_r, mapCR, time, errorStat);
data_c.regs.revmap.r{mapCR} = keeper;
data_c.regs.error.r(remove) = 1;

idsOfModRegions = [col(remove);col(keeper)];

if REMOVE_STRAY && ~isempty(data_f) && hasNoFwMapping(data_c,remove)
    data_c.regs.error.label{remove} = (['Frame: ', num2str(time),...
        ', reg: ', num2str(remove),' was not the best match for ', num2str(mapCR),' and was deleted.' num2str(keeper) , ' was.']);
    if verbose
        disp([header, 'ErRes: ', data_c.regs.error.label{remove}] );
    end
    regToDelete = [regToDelete;remove];
    resetRegions = true;
else
    for i = 1 : numel(remove)
        [data_c,cell_count] = createNewCell (data_c, remove(i), time, cell_count);
        data_c.regs.error.label{remove(i)} = (['Frame: ', num2str(time),...
            ', reg: ', num2str(remove(i)),' was not the best match for ', num2str(mapCR),'. Converted into a new cell.']);
        if verbose
            disp([header, 'ErRes: ', data_c.regs.error.label{remove(i)}] );
        end
    end
end
end