function [data_c, data_r, cell_count,resetRegions] =  errorRezNew (time, ...
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

global SCORE_LIMIT_MOTHER
global SCORE_LIMIT_DAUGHTER
global REMOVE_STRAY
global header_string
global regToDelete
header_string = header;
verbose = CONST.parallel.verbose;
MIN_LENGTH = 10;
REMOVE_STRAY = CONST.trackOpti.REMOVE_STRAY;
SCORE_LIMIT_DAUGHTER =  CONST.trackOpti.SCORE_LIMIT_DAUGHTER;
SCORE_LIMIT_MOTHER = CONST.trackOpti.SCORE_LIMIT_MOTHER;
DA_MIN = CONST.trackOpti.DA_MIN;
DA_MAX =  CONST.trackOpti.DA_MAX;
regToDelete = [];
resetRegions = false;

% set all ids to 0
data_c.regs.ID = zeros(1,data_c.regs.num_regs);
modRegions = [];
for regNum =  1 : data_c.regs.num_regs;
    
    if data_c.regs.ID(regNum) ~= 0
        disp ([header, 'ErRes: Frame: ', num2str(time), ' already has an id ',num2str(regNum)]);
    elseif ismember (regNum,modRegions)
        disp ([header, 'ErRes: Frame: ', num2str(time), ' already modified ',num2str(regNum)]);
    else
        
        rCellsFromC = data_c.regs.map.r{regNum}; % where regNum maps in reverse
        
        if ~isempty(rCellsFromC)
            cCellsTransp = unique([data_c.regs.revmap.r{rCellsFromC}]);
            cCellsFromR = unique([data_r.regs.map.f{rCellsFromC}]);
        else
            cCellsTransp = [];
            cCellsFromR = [];
        end
        
        
        if ~isempty(cCellsFromR)
            rCellsTransp = unique([data_r.regs.revmap.f{cCellsFromR}]);
        else
            rCellsTransp = [];
        end
        
        
        numberMatch = (numel(rCellsFromC) == numel(rCellsTransp)) && ...
            (numel(cCellsFromR) == numel(cCellsTransp));
        assignmentMatch = numberMatch && all(rCellsFromC == rCellsTransp) && ...
            all(cCellsFromR == cCellsTransp);
        partialMatch = any(ismember(rCellsFromC,rCellsTransp)) && any(ismember(cCellsFromR, cCellsTransp));
        
        zeroToOne = numel(rCellsFromC) == 0 ;
        oneToOne = numel(rCellsFromC) == 1 &&  numel (cCellsFromR) == 1 ;
        oneToTwo = numel(rCellsFromC) == 1 &&  numel (cCellsFromR) == 2 ;
        twoToOne = numel(rCellsFromC) == 2 &&  numel (cCellsFromR) == 1 ;
        oneToThree = numel(rCellsFromC) == 1 &&  numel (cCellsFromR) == 3 ;
        
        if numberMatch && assignmentMatch
            
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
                % one to one and agreement
                [data_c, data_r] = continueCellLine( data_c, regNum, data_r, rCellsFromC, time, hasError(data_c, regNum));
                
                
            elseif oneToTwo
                % one to two : possible splitting event
                
                mother = rCellsFromC;
                sister1 = regNum;
                sister2 = cCellsFromR (cCellsFromR~=regNum);
                haveNoMatch = (isempty(data_c.regs.map.f{sister1}) || isempty(data_c.regs.map.f{sister2}));
                matchToTheSame = ~haveNoMatch && all(ismember(data_c.regs.map.f{sister1}, data_c.regs.map.f{sister2}));
                
                % r: one has no forward mapping, or both map to the same in fw
                if  ~isempty(data_f) && (haveNoMatch || matchToTheSame)
                    % wrong division merge cells
                    if ~ignoreError
                        [data_c,reset_tmp] = merge2Regions (data_c, sister1, sister2, CONST);
                        modRegions = [modRegions;sister1;sister2];
                        resetRegions = (resetRegions || reset_tmp);
                    else
                        [data_c,data_r,cell_count,reset_tmp,modids_tmp] = mapBestOfTwo (data_c, cCellsFromR, data_r, rCellsFromC, time, verbose, cell_count,header);
                        modRegions = [modRegions;modids_tmp];
                    end
                    resetRegions = (resetRegions || reset_tmp);
                else
                    [data_c, data_r, cell_count] = createDivision (data_c,data_r,mother,sister1,sister2, cell_count, time,header, verbose);
                    modRegions = [modRegions;sister1;sister2];
                end
                
                
            elseif twoToOne
                % 1 in current maps to two in reverse
                % try to find a segment that should be turned on in current
                
                % The two in reverse map to regNum only : this may be always true by definition
                %twoInRMapToCOnly = numel(data_r.regs.map.f{rCellsFromC(1)}) == 1 && data_r.regs.map.f{rCellsFromC(1)}==regNum && ...
                %   numel(data_r.regs.map.f{rCellsFromC(2)}) == 1 && data_r.regs.map.f{rCellsFromC(2)}==regNum;
                
                success = false;
                if ~ignoreError
                    [data_c,success] = missingSeg2to1 (data_c,regNum,data_r,rCellsFromC,CONST);
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
                        keyboard;
                    end
                    resetRegions = true;
                else
                    % maybe copy from frame instead
                    % ERROR NOT FIXED : link to the one with the best score
                    if debug_flag
                    keyboard;
                end
                    [data_c,data_r] = mapToBestOfTwo (data_c, regNum, data_r, rCellsFromC, time, verbose,header);
                end
            elseif oneToThree
                disp ('merge two?')
                displayMap (data_c,data_r, rCellsFromC, cCellsTransp,cCellsFromR,rCellsTransp)
                if debug_flag
                    keyboard;
                end
            else
                
                disp ('there is another case of correctness?!?')
                displayMap (data_c,data_r, rCellsFromC, cCellsTransp,cCellsFromR,rCellsTransp)
                
                if debug_flag
                    keyboard;
                end
            end
        elseif numberMatch
            if zeroToOne
                % one to one but disagreement.
                displayMap (data_c,data_r, rCellsFromC, cCellsTransp,cCellsFromR,rCellsTransp)
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                    ', reg: ', num2str(regNum),'. 0->1 Error not fixed - misalign.'];
                
                if debug_flag
                    keyboard;
                end
            elseif oneToOne
                displayMap (data_c,data_r, rCellsFromC, cCellsTransp,cCellsFromR,rCellsTransp)
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                    ', reg: ', num2str(regNum),'. 1->1 Error not fixed - misalign.'];
                
                if debug_flag
                    keyboard;
                end
            elseif oneToTwo &&  ~any(cCellsFromR==regNum)
                % regNum maps to mother. but mother maps to two other cells.
                % OTHER POSSIBLE RESOLUTIONS.. :
                % 1 : merging missing, cell divided but piece fell out - check
                % if all three should be mapped
                % 2 : get the best two couples of the three
                
                % create new cell with error
                displayMap (data_c,data_r, rCellsFromC, cCellsTransp,cCellsFromR,rCellsTransp)
                [data_c,cell_count] = createNewCell (data_c, regNum, time, cell_count);
                data_c.regs.error.r(regNum) = 1;
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                    ', reg: ', num2str(regNum),'. Incorrect Mapping 1 to 2 - making a new cell'];
                
                if verbose
                    disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
                end
            else
                disp ('there is another case of matching numbers & un-correctness?!?')
                displayMap (data_c,data_r, rCellsFromC, cCellsTransp,cCellsFromR,rCellsTransp)
                
                if debug_flag
                    keyboard;
                end
            end
        else % mistmatch of numbers and assignments
            c_matches = cCellsFromR(ismember(cCellsFromR, cCellsTransp));
            r_matches = rCellsFromC(ismember(rCellsFromC, rCellsTransp));
            
            if partialMatch && numel(c_matches) == 1 && numel(r_matches) == 1
                [data_c, data_r] = continueCellLine( data_c, c_matches, data_r, r_matches, time, hasError(data_c, c_matches));
                modRegions = [modRegions;c_matches];
                
                
            elseif numel(rCellsFromC) == 1 && numel(cCellsFromR)  == 1 &&  numel (cCellsTransp) == 2
                % c --> r 1, c--->r 1, two c's map to r : inconsistent numbers
                sister1 = regNum;
                sister2 = cCellsTransp (cCellsTransp~=regNum);
                mapRC = cCellsTransp;
                mother = rCellsFromC;
                
                totAreaC = data_c.regs.props(sister1).Area + data_c.regs.props(sister2).Area;
                totAreaR =  data_r.regs.props(mother).Area;
                AreaChange = (totAreaC-totAreaR)/totAreaC;
                divAreaChange = (AreaChange > DA_MIN && AreaChange < DA_MAX);
                haveNoMatch = (isempty(data_c.regs.map.f{sister1}) || isempty(data_c.regs.map.f{sister2}));
                matchToTheSame = ~haveNoMatch && all(ismember(data_c.regs.map.f{sister1}, data_c.regs.map.f{sister2}));
                oneIsSmall = (data_c.regs.info(sister1,1) < MIN_LENGTH) ||  (data_c.regs.info(sister1,1) < MIN_LENGTH);
                
                if divAreaChange && ~ignoreError && ~isempty(data_f) && (haveNoMatch || matchToTheSame || oneIsSmall)
                    % r: one has no forward mapping, or both map to the same in fw, or one small
                    % wrong division merge cells
                    [data_c,mergeReset] = merge2Regions (data_c, sister1, sister2, CONST);
                    modRegions = [modRegions;sister1;sister2];
                    resetRegions = (resetRegions || mergeReset);
                elseif divAreaChange
                    [data_c, data_r, cell_count] = createDivision (data_c,data_r,mother,sister1,sister2, cell_count, time,header, verbose);
                    modRegions = [modRegions;sister1;sister2];
                else
                    % map to best, remove mapping from second
                    [data_c,data_r,cell_count,reset_tmp,modids_tmp] = mapBestOfTwo (data_c, mapRC, data_r, rCellsFromC, time, verbose, cell_count,header);
                    resetRegions = (resetRegions || reset_tmp);
                    modRegions = [modRegions;modids_tmp];
                end
                displayMap (data_c,data_r, rCellsFromC, cCellsTransp,cCellsFromR,rCellsTransp)
                
                if debug_flag
                    keyboard;
                end
            elseif oneToTwo && any([data_c.regs.map.r{cCellsFromR(cCellsFromR~=regNum)}] ~= rCellsFromC)
                % regNum -> mother, mother maps to two, second does not map to mother.
                [data_c, data_r] = continueCellLine( data_c, regNum, data_r, rCellsFromC, time, hasError(data_c, regNum));
                displayMap (data_c,data_r, rCellsFromC, cCellsTransp,cCellsFromR,rCellsTransp)
                
                if debug_flag
                    keyboard;
                end
            else
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                    ', reg: ', num2str(regNum),'. Error not fixed mishmatch and misalign.'];
                
                if debug_flag
                    keyboard;
                end
                
            end
            
        end
        
    end
end

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
global SCORE_LIMIT_MOTHER
global SCORE_LIMIT_DAUGHTER

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


function [data_c,data_r] = mapToBestOfTwo (data_c, regNum, data_r, mapCR, time, verbose,header)
% maps to best from two forward

cost1 = data_c.regs.cost.r(regNum,mapCR(1));
cost2 = data_c.regs.cost.r(regNum,mapCR(2));

if cost1<cost2 || isnan(cost2)
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
    (data_c, mapRC, data_r, mapCR, time, verbose, cell_count,header)
% maps to best from two forward
global regToDelete
global REMOVE_STRAY
resetRegions = 0;
[~,minInd] = min (data_c.regs.dA.r(mapRC));
keeper = mapRC(minInd);
remove = mapRC(mapRC~=keeper);
[data_c, data_r] = continueCellLine( data_c, keeper, data_r, mapCR, time, hasError(data_c, keeper));
data_c.regs.revmap.r{mapCR} = keeper;


data_c.regs.error.r(remove) = 1;
idsOfModRegions = [remove;keeper];
if REMOVE_STRAY && hasNoFwMapping(data_c, data_f,remove)
    data_c.regs.error.label{remove} = (['Frame: ', num2str(time),...
        ', reg: ', num2str(remove),' was not the best match for ', num2str(mapCR),' and was deleted.' num2str(keeper) , ' was.']);
    if verbose
        disp([header, 'ErRes: ', data_c.regs.error.label{remove}] );
    end
    regToDelete = [regToDelete;remove];
    resetRegions = true;
else
    data_c.regs.error.label{remove} = (['Frame: ', num2str(time),...
        ', reg: ', num2str(remove),' was not the best match for ', num2str(mapCR),' .']);
    if verbose
        disp([header, 'ErRes: ', data_c.regs.error.label{remove}] );
    end
end

end

function isError = hasError(data_c, regNum)
isError = 0; % FIX ME
%isError = data_c.regs.error.r(regNum) ~= 0 || data_c.regs.error.f(regNum) ~= 0;
end