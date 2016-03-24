function trackOptiLinkCell (dirname,disp_flag,CONST,header)
% trackOptiCellLink : links the cells frame-to-frame and resolves errors.
%
% INPUT :
%       dirname    : seg folder eg. maindirectory/xy1/seg
%       disp_flag  : a flag set for displaying the results
%       err_flag   : is set when called after error resolution.
%       CONST      : SuperSeggerOpti set parameters
%       header     : displayed string
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

CONST.regionOpti.MIN_LENGTH = 10;

if(nargin<1 || isempty(dirname))
    dirname=uigetdir();
end

dirname = fixDir(dirname);

if ~exist('disp_flag','var') || isempty( disp_flag );
    disp_flag = 0;
end

if ~exist('header','var')
    header = [];
end

REMOVE_STRAY = CONST.trackOpti.REMOVE_STRAY;
SCORE_LIMIT_DAUGHTER = - 30;% CONST.trackOpti.SCORE_LIMIT_DAUGHTER;
SCORE_LIMIT_MOTHER = - 30; %CONST.trackOpti.SCORE_LIMIT_MOTHER;

filt = '*seg.mat'; % files loaded
filt2 = 'err.mat'; % name of final files


contents=dir([dirname,filt]);
numIm = length(contents);
cell_count = 0;
time = 1;

continueFromLast = 1;
if continueFromLast
    disp ('continuing from where i stopped');
    contents2=dir([dirname,'*',filt2]);
    time = numel(contents2)+1;
    dataLast = load(contents2(end).name);
    cell_count = max(dataLast.regs.ID);
else
    !rm *err.mat
end

while time <= numIm
    
    
    if (time == 1)
        data_r = [];
    else
        datarName = [dirname,contents(time-1).name];
        data_r = intDataLoader (datarName);
    end
    
    if (time == numIm)
        data_f = [];
    else
        datafName = [dirname,contents(time+1).name];
        data_f = intDataLoader (datafName);
        data_f = updateRegionFields (data_f,CONST);  % make regions
    end
    
    datacName = [dirname,contents(time).name];
    data_c = intDataLoader (datacName);
    data_c = updateRegionFields (data_c,CONST);  % make regions
    
    % calculate overlaps between time t and time t + 1
    if ~isempty(data_r)
        [data_r.regs.areaCost.f,data_r.regs.centroidCost.f,...
            data_r.regs.totCost.f,data_r.regs.map.f,data_r.regs.error.f,data_r.regs.dA.f] ...
            = calcRegionOverlap( data_r, data_c, CONST);
    end
    
    [data_c.regs.areaCost.r,data_c.regs.centroidCost.r,...
        data_c.regs.totCost.r,data_c.regs.map.r,data_c.regs.error.r,data_c.regs.dA.r] ...
        = calcRegionOverlap( data_c, data_r, CONST);
    
    [data_c.regs.areaCost.f,data_c.regs.centroidCost.f,...
        data_c.regs.totCost.f,data_c.regs.map.f,data_c.regs.error.f,data_c.regs.dA.f] ...
        = calcRegionOverlap( data_c, data_f, CONST);
    
    resetRegions = false;
    lastCellCount = cell_count; % to reset cellID numbering when frame is repeated
    
    % go through regions in current data
    
    for regNum =  1 : data_c.regs.num_regs;
        
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
                
                if disp_flag
                    figure(1);
                    imshow(cat(3,0.5*ag(data_c.phase), ag(data_c.regs.regs_label==regNum),ag(data_r.regs.regs_label==mapCR)));
                    keyboard;
                end
            else
                
                imshow(cat(3,0.5*ag(data_c.phase),ag(data_c.regs.regs_label==regNum),ag(data_r.phase)));
                disp('Error :  disagreement in mapRC ==  mapCR');
                % how to resolve?
                keyboard;
                
            end
            
        elseif numel(mapCR) == 1 && numel(data_r.regs.map.f{mapCR}) == 2
            % the 1 in reverse maps to two in current : possible splitting event
            mapRC = data_r.regs.map.f{mapCR};
            mother = mapCR;
            sister1 = regNum;
            sister2 = mapRC(mapRC~=sister1);
            
            % check that the two sisters have forward mappings in the
            % next frame - otherwise it may be a wrong division
            if ~isempty(data_f) && (isempty(data_c.regs.map.f{sister1}) || isempty(data_c.regs.map.f{sister2}))
                % wrong division atempt to merge!
                data_c.regs.error.r(regNum) = 1;
                keyboard;
            else
                
                errorM  = (data_r.regs.scoreRaw(mother) < SCORE_LIMIT_MOTHER );
                errorD1 = (data_c.regs.scoreRaw(sister1) < SCORE_LIMIT_DAUGHTER);
                errorD2 = (data_c.regs.scoreRaw(sister2) < SCORE_LIMIT_DAUGHTER);
                
                if disp_flag
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
            
        elseif numel(mapCR) == 2 && numel(data_r.regs.map.f{mapCR(1)}) == 1 && data_r.regs.map.f{mapCR(1)}==regNum && ...
               numel(data_r.regs.map.f{mapCR(2)}) == 1 && data_r.regs.map.f{mapCR(2)}==regNum
            % 1 in current maps to two in reverse
            % try to find a segment that should be turned on in current
            % frame, exit regNum loop, make time - 1 and relink - dont
            % save anything?
            
            if disp_flag
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
                    imshow(cat(3,ag(data_c.regs.regs_label == regNum)+0.5*ag(data_c.phase),...
                        ag(data_r.regs.regs_label == mapCR(1)),...
                        ag(data_r.regs.regs_label == mapCR(2))));
                    
                    data_c.regs.error.r(regNum) = 1; % keep error?
                    data_c.regs.error.label{regNum} = ['Frame: ', num2str(time),...
                        ', reg: ', num2str(regNum),'. 2 -> 1 error, link the one with the most area overlap'];
                    disp([header, 'ErRes: ', data_c.regs.error.label{regNum}]);
                    
                    areaCost1 = data_c.regs.areaCost.r(regNum,mapCR(1));
                    areaCost2 = data_c.regs.areaCost.r(regNum,mapCR(2));
                    if areaCost1 > areaCost2
                        [data_c, data_r] = continueCellLine(data_c, regNum, data_r, mapCR(1), time, 0);
                    else
                        [data_c, data_r] = continueCellLine(data_c, regNum, data_r, mapCR(2), time, 0);
                    end
                end
            end
        end
        
    end
    
    if resetRegions
        disp (['Frame ', num2str(time), ' segments reset to resolve error, frame repeated.']);
        cell_count = lastCellCount;
        data_c.regs.ID = zeros(1,data_c.regs.num_regs); % reset cell ids
    else
        time = time + 1;
    end
    
    if ~isempty(data_r)
        dataname=[datarName(1:end-7),filt2];
        save(dataname,'-STRUCT','data_r');
    end
    
    dataname=[datacName(1:end-7),filt2];
    save(dataname,'-STRUCT','data_c');
    
end

    function result = hasNoFwMapping (data_c,regNum)
        result = isempty(data_c.regs.map.f{regNum});
    end

    function result = hasNoBackMapping (data_c,regNum,data_r)
        result = isempty(data_c.regs.map.f{regNum});
        %data_c.regs.info(regNum,1) >= CONST.regionOpti.MIN_LENGTH ;
    end

    function data = intDataLoader (dataName)
        % intDataLoader : loads the data files.
        % if first tries to load the fiele ending with filt2, if it doesn't find it
        % it loads the dataName given, and if that is not found either it
        % return empty.
        
        dataNameMod = [dataName(1:end-7),filt2];
        fidMod = fopen(dataNameMod);
        fid = fopen(dataName);
        
        if  fidMod ~= -1
            data = load(dataNameMod);
        elseif  fid ~= -1
            data = load(dataName);
        else
            data = [];
        end
        fclose('all');
    end

end
