function [data_c, data_r, cell_count,resetRegions] =  errorRez (time, ...
    data_c, data_r, data_f, CONST, cell_count, header, debug_flag, verbose)
% errorRez :
%
% INPUT :
% OUTPUT :

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


MIN_LENGTH = 10;
REMOVE_STRAY = CONST.trackOpti.REMOVE_STRAY;
SCORE_LIMIT_DAUGHTER =  CONST.trackOpti.SCORE_LIMIT_DAUGHTER;
SCORE_LIMIT_MOTHER = CONST.trackOpti.SCORE_LIMIT_MOTHER;
DA_MIN = CONST.trackOpti.DA_MIN;
DA_MAX =  CONST.trackOpti.DA_MAX;

resetRegions = false;

% set all ids to 0
data_c.regs.ID = zeros(1,data_c.regs.num_regs);

for regNum =  1 : data_c.regs.num_regs;
    
    if data_c.regs.ID(regNum) == 0
        mapCR = data_c.regs.map.r{regNum}; % where regNum maps in reverse
        
        if ~isempty(mapCR)
            revMap = data_c.regs.revmap.r{mapCR};
        else
            revMap = 0;
        end
        
        
        %%% maps to 0
        if numel(mapCR) == 0 % maps to 0 in the previous frame - stray
            
            % think whether this is useful :  numel(mapRC) == 0
            if (time ~= 1) && (hasNoFwMapping(data_c,regNum) || REMOVE_STRAY)
                % deletes the regions not appearing at time = 1 that do not map to anything
                % or if remove_stray flag is set to true.
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time), ...
                    ', reg: ', num2str(regNum), '. is a stray region - Deleted.'];
                if verbose
                    disp([header, 'ErRes: ',data_c.regs.error.label{regNum}] );
                end
                [data_c] = deleteRegions( data_c,regNum);
                resetRegions = true;
            else % maps to a region in the next frame, or time is 1
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time), ...
                    ', reg: ', num2str(regNum), '. is a stray region.'];
                if verbose
                    disp([header, 'ErRes: ',data_c.regs.error.label{regNum}] );
                end
                [data_c,cell_count] = createNewCell (data_c, regNum, time, cell_count,verbose);
            end
            
        elseif numel(mapCR) == 1 &&  numel (revMap) == 1 && all(data_r.regs.map.f{mapCR} == regNum)
            % MAPS TO ONE AND AGREES
            % sets cell ID from mapped reg, updates death in data_r
            [data_c, data_r] = continueCellLine( data_c, regNum, data_r, mapCR, time, 0, verbose);
            
        elseif numel(mapCR) == 1 && numel(data_r.regs.map.f{mapCR}) == 1 &&  numel (revMap) == 2
            %% one to one but disagreement
            
            % red in c maps to blue in r, but blue in r maps to green
            % in c
            sister1 = regNum;
            sister2 = revMap (revMap~=regNum);
            mother = mapCR;
            
            imshow(cat(3,0.5*ag(data_c.phase) + 0.5*ag(data_c.regs.regs_label==sister1),...
                ag(data_r.regs.regs_label == mother),ag(data_c.regs.regs_label==sister2)));
            
            totAreaC = data_c.regs.props(sister1).Area + data_c.regs.props(sister2).Area;
            totAreaR =  data_c.regs.props(mother).Area;
            AreaChange = (totAreaC-totAreaR)/totAreaC;
            divAreaChange = (AreaChange > DA_MIN && AreaChange < DA_MAX)
            
            if divAreaChange
                haveNoMatch = (isempty(data_c.regs.map.f{sister1}) || isempty(data_c.regs.map.f{sister2}));
                matchToTheSame = ~haveNoMatch && all(ismember(data_c.regs.map.f{sister1}, data_c.regs.map.f{sister2}));
                oneIsSmall = (data_c.regs.info(sister1,1) < MIN_LENGTH) ||  (data_c.regs.info(sister1,1) < MIN_LENGTH)
                % or one is small..
                % r: one has no forward mapping, or both map to the same in forwa
                if ~isempty(data_f) && (haveNoMatch || matchToTheSame || oneIsSmall)
                    % wrong division merge cells
                    [data_c] = merge2Regions (data_c, sister1, sister2);
                    resetRegions = true;
                else
                    [data_c, data_r, cell_count] = createDivision (data_c,data_r,mother,sister1,sister2, cell_count, time,header, verbose);
                end
            else
                
                
                % map to best, remove mapping from second
                sisters = [sister1,sister2];
                [~,minInd] = min ([data_c.regs.dA.r(sisters)]);
                keeper = sisters(minInd);
                remove = sisters(sisters~=keeper);
                [data_c, data_r] = continueCellLine( data_c, keeper, data_r, mapCR, time, 0, verbose);
                
                
                data_c.regs.map.r{remove} = [];
                data_c.regs.revmap.r{mapCR} = keeper;
                
                data_r.regs.error.label{remove} = (['Frame: ', num2str(time),...
                    ', reg: ', num2str(remove),' was not the best match for ', num2str(mother),'.']);
                if verbose
                    disp([header, 'ErRes: ', data_c.regs.error.label{remove}] );
                end
                
                data_c.regs.error.r(remove) = 1;
                [data_c,cell_count] = createNewCell (data_c, remove, time, cell_count, verbose);
                % make it stray..
                
            end
            %         % check costs for division
            %         idC = find(all(ismember(data_c.regs.idsC.r,[regNum,mapRC])));
            %         costC = data_c.regs.cost.r(idC,cellR); % cost for both
            %         costBef = data_c.regs.cost.r(cellC,cellR); % cost for one
            %         costChangeValue = 200;
            %
            %         % maprRC maps to nothing and cost to map both is low
            %         %markDivEmptyLowCost = isempty(data_c.regs.map.r (cellRmapsTo)) && (costC + costChangeValue < costBef);
            %
            %         % both cell C and cellRmapsTo map to cellR - but cellR maps to only one of them.
            %         % mark division anyway.
            %         markDiv1RCagree = all(data_c.regs.map.r {cellRmapsTo} == cellR) && all(data_c.regs.map.r {regNum} == cellR);
            %
            %
            %         % mark division
            %         if markDiv1RCagree
            %             sister2 = mapRC;
            %             sister1 = regNum;
            %             mother = mapCR;
            %             [data_c, data_r, cell_count] = createDivision (data_c,data_r,mother,sister1,sister2, cell_count, time,header);
            %
            %         elseif ~data_r.regs.deathF(mapCR)
            %             % Error not fixed : one to one mapping but disagreement between current and
            %             % reverse
            %             % continue the cell line anyway and put an error..
            %             if debug_flag
            %                 keyboard;
            %             end
            %             errorStat = 1;
            %             [data_c, data_r] = continueCellLine( data_c, regNum, data_r, mapCR, time, errorStat);
            %             data_c.regs.error.label{regNum} = (['Frame: ', num2str(time),...
            %                 ', reg: ', num2str(regNum),' Disagreement in mapping cur -> rev & rev -> cur ].']);
            %             data_r.regs.error.label{mapCR} = (['Frame: ', num2str(time),...
            %                 ', reg: ', num2str(regNum),' Disagreement in mapping cur -> rev & rev -> cur ].']);
            %             data_r.regs.error.label{mapRC} = (['Frame: ', num2str(time),...
            %                 ', reg: ', num2str(regNum),' Disagreement in mapping cur -> rev & rev -> cur ].']);
            %
            %             disp([header, 'ErRes: ', data_c.regs.error.label{regNum}] );
            %             data_c.regs.error.r(regNum) = 1;
            %             data_r.regs.error.f(mapCR) = 1;
            %
            %
            %         end
            
            
        elseif numel(mapCR) == 1 && numel(data_r.regs.map.f{mapCR}) == 2
            % the 1 in reverse maps to two in current : possible splitting event
            mother = mapCR;
            mapRC = data_r.regs.map.f{mother};
            
            if  ~any(mapRC==regNum)
                % ERROR NOT FIXED :  mapCR maps to mother. but mother maps to
                % two other cells..
                
                % POSSIBLE RESOLUTIONS :
                % 1 : merging missing, cell divided but piece fell out - check
                % if all three should be mapped
                % 2 : get the best two couples of the three
                % other?
                
                
                % force mapping
                sister1 = regNum;
                sister2 = mapRC(1);
                sister3 = mapRC(2);
                
                % make a new cell for regNum with error...
                [data_c,cell_count] = createNewCell (data_c, regNum, time, cell_count,verbose);
                data_c.regs.error.r(regNum) = 1;
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                    ', reg: ', num2str(regNum),'. Incorrect Mapping 1 to 2 - making a new cell'];
                
                if verbose
                    disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
                end
                % red is regNum, green is the ones mother maps to, blue is
                % mother
                imshow(cat(3,0.5*ag(data_c.phase) + 0.5*ag(data_c.regs.regs_label==regNum), ...
                    ag((data_c.regs.regs_label == mapRC(1)) + ...
                    (data_c.regs.regs_label==mapRC(2))),ag(data_r.regs.regs_label==mother)));
            else
                
                sister1 = regNum;
                sister2 = mapRC(mapRC~=sister1);
                haveNoMatch = (isempty(data_c.regs.map.f{sister1}) || isempty(data_c.regs.map.f{sister2}));
                matchToTheSame = ~haveNoMatch && all(ismember(data_c.regs.map.f{sister1}, data_c.regs.map.f{sister2}));
                
                % r: one has no forward mapping, or both map to the same in forwa
                if ~isempty(data_f) && (haveNoMatch || matchToTheSame)
                    % wrong division merge cells
                    [data_c] = merge2Regions (data_c, sister1, sister2);
                    resetRegions = true;
                else
                    [data_c, data_r, cell_count] = createDivision (data_c,data_r,mother,sister1,sister2, cell_count, time,header, verbose);
                end
            end
        elseif numel(mapCR) == 2
            % 1 in current maps to two in reverse
            % try to find a segment that should be turned on in current
            % frame, exit regNum loop, make time - 1 and relink
            
            % The two in reverse map to regNum only
            twoInRMapToCOnly = numel(data_r.regs.map.f{mapCR(1)}) == 1 && data_r.regs.map.f{mapCR(1)}==regNum && ...
                numel(data_r.regs.map.f{mapCR(2)}) == 1 && data_r.regs.map.f{mapCR(2)}==regNum;
            
            if debug_flag
                imshow(cat(3,0.5*ag(data_c.phase), 0.7*ag(data_c.regs.regs_label==regNum),...
                    ag((data_r.regs.regs_label==mapCR(1)) + (data_r.regs.regs_label==mapCR(2)))));
                
            end
            
            success = false;
            
            if twoInRMapToCOnly
                [data_c,success] = missingSeg2to1 (data_c,regNum,data_r,mapCR,CONST);
            end
            
            if success % segment found
                data_c.regs.error.r(regNum) = 0;
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                    ', reg: ', num2str(regNum),'. Segment added to fix 2 to 1 error'];
                
                if verbose
                    disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
                end
                imshow(cat(3,ag(data_c.regs.regs_label == regNum)+0.5*ag(data_c.phase),...
                    ag(data_r.regs.regs_label == mapCR(1)),...
                    ag(data_r.regs.regs_label == mapCR(2))));
                resetRegions = true;
            else
                % ERROR NOT FIXED : link to the one with the best score
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
                    [data_c, data_r] = continueCellLine(data_c, regNum, data_r, mapCR(1), time, errorStat, verbose);
                    
                else
                    errorStat = 1;
                    data_c.regs.error.r(regNum) = 2;
                    data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                        ', reg: ', num2str(regNum),'. Map to minimum cost'];
                    
                    if verbose
                        disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
                    end
                    [data_c, data_r] = continueCellLine(data_c, regNum, data_r, mapCR(2), time, errorStat, verbose);
                    
                end
                
            end
        else
            data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                ', reg: ', num2str(regNum),'. Error not fixed'];
            
            if verbose
                disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
            end
            if debug_flag
                intDisplay (data_r,mapCR,data_c,regNum)
                keyboard;
            end
            
        end
        
    else
        if verbose
            disp([header, 'ErRes: Frame: ', num2str(time),...
                ', reg: ', num2str(regNum),' already has an ID.']);
        end
        
        
    end
end
end



function intDisplay (data_c,regC,data_f,regF)
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




function [ data_c, data_r, cell_count ] = createDivision (data_c,data_r,mother,sister1,sister2, cell_count, time, header, verbose)
global SCORE_LIMIT_MOTHER
global SCORE_LIMIT_DAUGHTER


errorM  = (data_r.regs.scoreRaw(mother) < SCORE_LIMIT_MOTHER );
errorD1 = (data_c.regs.scoreRaw(sister1) < SCORE_LIMIT_DAUGHTER);
errorD2 = (data_c.regs.scoreRaw(sister2) < SCORE_LIMIT_DAUGHTER);

% if debug_flag && ~data_c.regs.ID(sister1)
%     figure(1);
%     imshow(cat(3,ag(data_c.phase), ag(ag(data_c.regs.regs_label==sister2) +ag(data_c.regs.regs_label==sister1)),ag(data_r.regs.regs_label==mother)));
%     keyboard;
% end

if ~(errorM || errorD1 || errorD2)
    % good scores for mother and daughters
    % sets ehist to 0 (no error) and stat0 to 1 (successful division)
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
        data_c, sister1, data_r, mother, time, 0, sister2, cell_count, verbose);
    
else
    % bad scores for mother or daughters
    % sets ehist to 1 ( error) and stat0 to 0 (non successful division)
    errorStat = 1;
    %data_c.regs.error.r(sister1) = 1;
    data_r.regs.error.r(mother) = 0;
    data_c.regs.error.r(sister1) = 0;
    data_c.regs.error.r(sister2) = 0;
    
    data_c.regs.error.label{sister1} = (['Frame: ', num2str(time),...
        ', reg: ', num2str(sister1),' and ', num2str(sister2),...
        '. 1 -> 2 mapping  from mother reg', num2str(mother),', but not good cell [sm,sd1,sd2,slim] = [',...
        num2str(data_r.regs.scoreRaw(mother),2),', ',...
        num2str(data_c.regs.scoreRaw(sister1),2),', ',...
        num2str(data_c.regs.scoreRaw(sister2),2)]);
    
    if verbose
        disp([header, 'ErRes: ', data_c.regs.error.label{sister1}] );
    end
    [data_c, data_r, cell_count] = markDivisionEvent( ...
        data_c, sister1, data_r, mother, time, errorStat, sister2, cell_count, verbose);
    
end
end


function result = hasNoFwMapping (data_c,regNum)
result = isempty(data_c.regs.map.f{regNum});
end
