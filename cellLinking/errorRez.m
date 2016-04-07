function [cell_count,resetRegions] =  errorRez (time, data_c, data_r, data_f, CONST, cell_count, header, debug_flag)
    
    REMOVE_STRAY = CONST.trackOpti.REMOVE_STRAY;
    SCORE_LIMIT_DAUGHTER =  CONST.trackOpti.SCORE_LIMIT_DAUGHTER;
    SCORE_LIMIT_MOTHER = CONST.trackOpti.SCORE_LIMIT_MOTHER;

    
    resetRegions = false;
    
    for regNum =  1 : data_c.regs.num_regs;
        
        if regNum == 69
            debug_flag = 1;
            
        end
        
        mapCR = data_c.regs.map.r{regNum}; % where regNum maps in reverse
        
        if numel(mapCR) == 0 % maps to 0 in the previous frame - stray
            
            %imshow(cat(3,0.5*ag(data_c.phase),0.2*ag(data_c.regs.regs_label==regNum),ag(data_r.phase)));
            
            if (time ~= 1) && (hasNoFwMapping(data_c,regNum) || REMOVE_STRAY)
                % deletes the regions not appearing at time = 1 that do not map to anything
                % or if remove_stray flag is set to true.
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time), ...
                    ', reg: ', num2str(regNum), '. is a stray region - Deleted.'];
                disp([header, 'ErRes: ',data_c.regs.error.label{regNum}] );
                [data_c] = deleteRegions( data_c,regNum);
                resetRegions = true;
            else % maps to a region in the next frame, or time is 1
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time), ...
                    ', reg: ', num2str(regNum), '. is a stray region.'];
                disp([header, 'ErRes: ',data_c.regs.error.label{regNum}] );
                [data_c,cell_count] = createNewCell (data_c, regNum, time, cell_count);
            end
            
        elseif numel(mapCR) == 1 && numel(data_r.regs.map.f{mapCR}) == 1 % maps to one in the next frame
            
            
            mapRC = data_r.regs.map.f{mapCR};

            if numel(mapRC) == 1 && mapRC ==  regNum % one to one mapping
                % sets cell ID from mapped reg, updates death in data_r
                [data_c, data_r] = continueCellLine( data_c, regNum, data_r,mapCR, time, 0);
                
                if debug_flag
                    figure(1);
                    imshow(cat(3,0.5*ag(data_c.phase), ag(data_c.regs.regs_label==regNum),ag(data_r.regs.regs_label==mapCR)));
                    %keyboard;
                end
            else
                
                % red in c maps to blue in r, but blue in r maps to green
                % in c
                imshow(cat(3,0.5*ag(data_c.phase) + 0.5*ag(data_c.regs.regs_label==regNum),ag(data_r.regs.regs_label == mapCR),ag(data_c.regs.regs_label==mapRC)));
                
                % how to resolve?
                % FIX THIS :  probably best i can do is take all cells that overlap
                % and look for missing segments?
                keyboard;
                
                
                
                % continue anyway and put an error..
                [data_c, data_r] = continueCellLine( data_c, regNum, data_r,mapCR, time, 0);
                data_c.regs.error.label{regNum} = (['Frame: ', num2str(time),...
                    ', reg: ', num2str(regNum),' Disagreement in apping cur -> rev & rev -> cur ].']);
                data_r.regs.error.label{mapCR} = (['Frame: ', num2str(time),...
                    ', reg: ', num2str(regNum),' Disagreement in apping cur -> rev & rev -> cur ].']);
                data_r.regs.error.label{mapRC} = (['Frame: ', num2str(time),...
                    ', reg: ', num2str(regNum),' Disagreement in apping cur -> rev & rev -> cur ].']);
                
                
                disp([header, 'ErRes: ', data_c.regs.error.label{regNum}] );
                
                data_c.regs.error.r(regNum) = 1;
                data_r.regs.error.f(mapCR) = 1;
                data_r.regs.error.f(mapRC) = 1;
                
                
            end
            
        elseif numel(mapCR) == 1 && numel(data_r.regs.map.f{mapCR}) == 2
            % the 1 in reverse maps to two in current : possible splitting event
            mother = mapCR;
            mapRC = data_r.regs.map.f{mother};
           
            if  ~any(mapRC==regNum)
                
                % force mapping
                sister1 = regNum;
                sister2 = mapRC(1);
                sister3 = mapRC(2);
                
                
                imshow(cat(3,0.5*ag(data_c.phase) + 0.5*ag(data_c.regs.regs_label==regNum), ...
                    ag((data_c.regs.regs_label == mapRC(1)) + ...
                    (data_c.regs.regs_label==mapRC(2))),ag(data_r.regs.regs_label==mother)));     
                keyboard;
                % assignments from rev to forward mismatch
            else
                
                sister1 = regNum;
                sister2 = mapRC(mapRC~=sister1);
                
                
                
                
                % check that the two sisters have forward mappings in the
                % next frame - otherwise it may be a wrong division
                
                
                
                % 1 : if one has mapping and hte other has not but they were
                % look like correct cells possible bad mapping in f
                
                % 2 : or one may be a bad cell
                
                % 3 : if they both map to the same thing in f then merge
                
                haveNoMatch = (isempty(data_c.regs.map.f{sister1}) || isempty(data_c.regs.map.f{sister2}))
                matchToTheSame = ~haveNoMatch && (data_c.regs.map.f{sister1} == data_c.regs.map.f{sister2})
                
                
                if ~isempty(data_f) && (haveNoMatch || matchToTheSame)
                    
                    % wrong division atempt to merge!
                    data_c.regs.error.r(regNum) = 1;
                    keyboard;
                    imshow(cat(3,ag(data_c.phase), ag(ag(data_c.regs.regs_label==sister2) +ag(data_c.regs.regs_label==sister1)),ag(data_r.regs.regs_label==mother)));
                    
                    
                else
                    
                    errorM  = (data_r.regs.scoreRaw(mother) < SCORE_LIMIT_MOTHER );
                    errorD1 = (data_c.regs.scoreRaw(sister1) < SCORE_LIMIT_DAUGHTER);
                    errorD2 = (data_c.regs.scoreRaw(sister2) < SCORE_LIMIT_DAUGHTER);
                    
                    if debug_flag && ~data_c.regs.ID(sister1)
                        
                        
                        figure(1);
                        imshow(cat(3,ag(data_c.phase), ag(ag(data_c.regs.regs_label==sister2) +ag(data_c.regs.regs_label==sister1)),ag(data_r.regs.regs_label==mother)));
                        
                        keyboard;
                    end
                    
                    if ~(errorM || errorD1 || errorD2)
                        % good scores for mother and daughters
                        % sets ehist to 0 (no error) and stat0 to 1 (successful division)
                        data_c.regs.error.label{sister1} = (['Frame: ', num2str(time),...
                            ', reg: ', num2str(sister1),'. good cell division. [L1,L2,Sc] = [',...
                            num2str(data_c.regs.L1(sister1),2),', ',num2str(data_c.regs.L2(sister1),2),...
                            ', ',num2str(data_c.regs.scoreRaw(sister1),2),'].']);
                        disp([header, 'ErRes: ', data_c.regs.error.label{sister1}] );
                        data_r.regs.error.r(mother) = 0;
                        data_c.regs.error.r(sister1) = 0;
                        data_c.regs.error.r(sister2) = 0;
                        [data_c, data_r, cell_count] = markDivisionEvent( ...
                            data_c, sister1, data_r, mother, time, 0, sister2, cell_count);
                        
                    else
                        % bad scores for mother or daughters
                        % sets ehist to 1 ( error) and stat0 to 0 (non successful division)
                        data_c.regs.error.r(regNum) = 1;
                        data_c.regs.error.label{sister1} = ['Frame: ', num2str(time),...
                            ', reg: ', num2str(sister1),...
                            '. 1 -> 2 mapping, but not good cell [sm,sd1,sd2,slim] = ['...
                            num2str(data_r.regs.scoreRaw(mother),2),', ',...
                            num2str(data_c.regs.scoreRaw(sister1),2),', ',...
                            num2str(data_c.regs.scoreRaw(sister2),2),'].'];
                        disp([header, 'ErRes: ', data_c.regs.error.label{sister1}] );
                        [data_c, data_r, cell_count] = markDivisionEvent( ...
                            data_c, sister1, data_r, mother, time, 1, sister2, cell_count);
                       
                    end
                    
                end
            end
        elseif numel(mapCR) == 2 && numel(data_r.regs.map.f{mapCR(1)}) == 1 && data_r.regs.map.f{mapCR(1)}==regNum && ...
                numel(data_r.regs.map.f{mapCR(2)}) == 1 && data_r.regs.map.f{mapCR(2)}==regNum
            % 1 in current maps to two in reverse
            % try to find a segment that should be turned on in current
            % frame, exit regNum loop, make time - 1 and relink - dont
            % save anything?
            
            if debug_flag
                imshow(cat(3,ag(data_c.phase), ag(data_c.regs.regs_label==regNum),ag((data_r.regs.regs_label==mapCR(1))>0 + (data_r.regs.regs_label==mapCR(2))>0)));
                keyboard
            end
            
            [data_c,success] = missingSeg2to1 (data_c,regNum,data_r,mapCR,CONST);
            if success % segment found
                data_c.regs.error.r(regNum) = 0;
                data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                    ', reg: ', num2str(regNum),'. Segment added to fix 2 to 1 error'];
                disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
                imshow(cat(3,ag(data_c.regs.regs_label == regNum)+0.5*ag(data_c.phase),...
                    ag(data_r.regs.regs_label == mapCR(1)),...
                    ag(data_r.regs.regs_label == mapCR(2))));
                resetRegions = true;
            else
                % if one region in r is tiny remove it! / or connect it to the
                % other one
                areaR1 = data_r.regs.props(mapCR(1)).Area;
                areaR2 = data_r.regs.props(mapCR(2)).Area;
                
                areaMin = 50;
                if areaR1 < areaMin
                    data_c.regs.error.r(regNum) = 0;
                    data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                        ', reg: ', num2str(regNum),'. Smallest cell deleted'];
                    disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
                    
                    [data_r] = deleteRegions(data_r, mapCR(1));
                    % deletes region from labels and mask
                    resetRegions = true;
                elseif areaR2 < areaMin
                    data_c.regs.error.r(regNum) = 0;
                    data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                        ', reg: ', num2str(regNum),'. Smallest cell deleted'];
                    disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
                    
                    [data_r] = deleteRegions(data_r, mapCR(2));
                    resetRegions = true;
                else
                    
                    % keep the cell with the most overlap - not implemented
                    % yet
                    imshow(cat(3,ag(data_c.regs.regs_label == regNum)+0.5*ag(data_c.phase),...
                        ag(data_r.regs.regs_label == mapCR(1)),...
                        ag(data_r.regs.regs_label == mapCR(2))));
                    
                    data_c.regs.error.r(regNum) = 1; % keep error?
                    data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                        ', reg: ', num2str(regNum),'. 2 -> 1 error, link the one with the most area overlap'];
                    disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
                    
                    % choosing randomly one..
                    [data_c, data_r] = continueCellLine(data_c, regNum, data_r, mapCR(1), time, 0);
        
                    
%                     areaCost1 = data_c.regs.areaCost.r(regNum,mapCR(1));
%                     areaCost2 = data_c.regs.areaCost.r(regNum,mapCR(2));
%                     if areaCost1 > areaCost2
%                         [data_c, data_r] = continueCellLine(data_c, regNum, data_r, mapCR(1), time, 0);
%                     else
%                         [data_c, data_r] = continueCellLine(data_c, regNum, data_r, mapCR(2), time, 0);
%                     end
                end
            end
        end
        
    end
    
 
end

   
    function result = hasNoFwMapping (data_c,regNum)
        result = isempty(data_c.regs.map.f{regNum});
    end

    function result = hasNoBackMapping (data_c,regNum,data_r)
        result = isempty(data_c.regs.map.f{regNum});
        %data_c.regs.info(regNum,1) >= CONST.regionOpti.MIN_LENGTH ;
    end