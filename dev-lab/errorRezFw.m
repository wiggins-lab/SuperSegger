function [data_c, data_r, cell_count,resetRegions] =  errorRezFw (time, ...
    data_c, data_r, data_f, CONST, cell_count, header, ignoreError, debug_flag)
% errorRezNew : links cells from the frame before to the current and attempts to
% resolve segmentation errors if the linking is inconsistent.
%
% INPUT :
%   time : current frame number
%   data_c : current time frame data (seg/err) file.
%   data_r : reverse time frame data (seg/err) file.
%   data_f : forward time frame data (seg/err) file.
%   CONST : segmentation parameters.
%   cell_count : last cell id used.
%   header : last cell id used.
%   debug_flag : 1 to display figures for debugging
%
% OUTPUT :
%   data_c : updated current time frame data (seg/err) file.
%   data_r : updated reverse time frame data (seg/err) file.
%   cell_count : last cell id used.
%   resetRegions : if true, regions were modified and this frame needs to
%   be relinked.
%
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
data_c.regs.ID = zeros(1,data_c.regs.num_regs);
modRegions = [];
cArea = [data_c.regs.props.Area];
for regNum =  1 : data_c.regs.num_regs;
    
    if data_c.regs.ID(regNum) ~= 0
        disp ([header, 'ErRes: Frame: ', num2str(time), ' already has an id ',num2str(regNum)]);
    elseif ismember (regNum,modRegions)
        disp ([header, 'ErRes: Frame: ', num2str(time), ' already modified ',num2str(regNum)]);
    else
        
        if ~isempty(data_r)
            rCells = data_r.regs.revmap.f{regNum}; % where regNum maps in reverse
        else
            rCells = [];
        end
        
        if ~isempty(rCells)
            cCellsT = unique([data_r.regs.map.f{rCells}]);
        else
            cCellsT = [regNum];
        end
        
        
        zeroToOne = numel(rCells) == 0 ;
        oneToOne = numel(rCells) == 1 &&  numel (cCellsT) == 1 ;
        oneToTwo = numel(rCells) == 1 &&  numel (cCellsT) == 2 ;
        oneToThree = numel(rCells) == 1 &&  numel (cCellsT) == 3 ;
        twoToOne = numel(rCells) == 2 &&  numel (cCellsT) == 1 ;
        twoTotwo = numel(rCells) == 2 &&  numel (cCellsT) == 2 ;
        twoToThree = numel(rCells) == 2 &&  numel (cCellsT) == 3 ;
        threeToOne = numel(rCells) == 3 &&  numel (cCellsT) == 1 ;
        
        if zeroToOne % maps to 0 in the previous frame - stray
            % think whether this is useful :  numel(mapRC) == 0
            if (time ~= 1) && (hasNoFwMapping(data_c, data_f,regNum) && REMOVE_STRAY)
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
            
        elseif oneToOne
            errorStat = (data_c.regs.error.r(regNum)>0);
            [data_c, data_r] = continueCellLine( data_c, regNum, data_r, rCells, time, errorStat);
            
            
        elseif oneToTwo
            % one to two : possible splitting event
            
            mother = rCells;
            sister1 = regNum;
            sister2 = cCellsT (cCellsT~=regNum);
            haveNoMatch = (isempty(data_c.regs.map.f{sister1}) || isempty(data_c.regs.map.f{sister2}));
            matchToTheSame = ~haveNoMatch && all(ismember(data_c.regs.map.f{sister1}, data_c.regs.map.f{sister2}));
            oneIsSmall = (cArea(sister1) < minAreaToMerge) || (cArea(sister1) < minAreaToMerge); 
            % r: one has no forward mapping, or both map to the same in fw
            if  ~isempty(data_f) && (haveNoMatch || matchToTheSame || oneIsSmall)
                % wrong division merge cells
                if ~ignoreError
                    [data_c,reset_tmp] = merge2Regions (data_c, [sister1, sister2], CONST);
                    modRegions = [modRegions;sister1;sister2];
                    resetRegions = (resetRegions || reset_tmp);
                else
                    [data_c,data_r,cell_count,reset_tmp,modids_tmp] = mapBestOfTwo (data_c, cCellsT, data_r, rCells, time, ...
                        verbose, cell_count,header, data_f);
                    modRegions = [modRegions;modids_tmp];
                end
                resetRegions = (resetRegions || reset_tmp);
            else
                [data_c, data_r, cell_count] = createDivision (data_c,data_r,mother,sister1,sister2, cell_count, time,header, verbose);
                modRegions = [modRegions;sister1;sister2];
            end
            
            
        elseif twoToOne || threeToOne
            % 1 in current maps to two in reverse
            % try to find a segment that should be turned on in current
            
            success = false;
            if ~ignoreError
                [data_c,success] = missingSeg2to1 (data_c,regNum,data_r,rCells,CONST);
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
                        ag(data_r.regs.regs_label == rCells(1)),...
                        ag(data_r.regs.regs_label == rCells(2))));
                    keyboard;
                end
                resetRegions = true;
            else
                % maybe copy from frame instead
                % ERROR NOT FIXED : link to the one with the best score
                if debug_flag
                    keyboard;
                end
                [data_c,data_r] = mapToBestOfTwo (data_c, regNum, data_r, rCells, time, verbose,header);
            end
        elseif oneToThree
            disp ('merge')
            [data_c,reset_tmp] = merge2Regions (data_c, cCellsT, CONST);
            modRegions = [modRegions;cCellsT'];
            resetRegions = (resetRegions || reset_tmp);
            
           % displayMap (data_c,data_r, rCellsFromC, cCellsTransp,cCellsTransp,rCellsTransp)
        elseif twoTotwo
            keyboard;
        elseif twoToThree
            keyboard;
        elseif threeToOne
             keyboard;
        else
            disp ('there is another case of correctness?!?')
           % displayMap (data_c,data_r, rCellsFromC, cCellsTransp,cCellsTransp,rCellsTransp)
            
            
            keyboard;
            
        end
    end
end

[data_c] = deleteRegions( data_c,regToDelete);

end


function [ data_c, data_r, cell_count ] = createDivision (data_c,data_r,mother,sister1,sister2, cell_count, time, header, verbose)
data_c.regs.error.label{sister1} = (['Frame: ', num2str(time),...
    ', reg: ', num2str(sister1),' and ', num2str(sister2),' . good cell division from mother reg', num2str(mother),'. [L1,L2,Sc] = [',...
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


function result = hasNoFwMapping (data_c,data_f,regNum)
result = ~isempty(data_f) && isempty(data_c.regs.map.f{regNum});
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




function [data_c,data_r] = mapToBestOfTwo (data_c, regNum, data_r, mapCR, time, verbose,header)
% maps to best from two forward


flaggerC = (data_c.regs.idsC.r(1,:) == regNum) & isnan(data_c.regs.idsC.r(2,:));
flaggerR1 = (data_c.regs.idsR.r(1,:) == mapCR(1)) & isnan(data_c.regs.idsR.r(2,:));
flaggerR2 = (data_c.regs.idsR.r(1,:) == mapCR(2)) & isnan(data_c.regs.idsR.r(2,:));

loc1 = find(flaggerC&flaggerR1);
loc2 = find(flaggerC&flaggerR2);
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
    (data_c, mapRC, data_r, mapCR, time, verbose, cell_count, header, data_f)
% maps to best from two forward
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
idsOfModRegions = [remove;keeper];
if REMOVE_STRAY && hasNoFwMapping(data_c,data_f,remove)
    data_c.regs.error.label{remove} = (['Frame: ', num2str(time),...
        ', reg: ', num2str(remove),' was not the best match for ', num2str(mapCR),' and was deleted.' num2str(keeper) , ' was.']);
    if verbose
        disp([header, 'ErRes: ', data_c.regs.error.label{remove}] );
    end
    regToDelete = [regToDelete;remove];
    resetRegions = true;
else
    [data_c,cell_count] = createNewCell (data_c, remove, time, cell_count);
    data_c.regs.error.label{remove} = (['Frame: ', num2str(time),...
        ', reg: ', num2str(remove),' was not the best match for ', num2str(mapCR),' made into a new cell.']);
    if verbose
        disp([header, 'ErRes: ', data_c.regs.error.label{remove}] );
    end
end
end