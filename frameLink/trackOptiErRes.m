function [list_touch] = trackOptiErRes(dirname,nc_flag,CONST,header)
% trackOptiErRes : defines and resolves errors produced during frame linking.
% This function can do calculations on the regions and fix regions
% by frame skipping, removing, and splitting regions and by calling good
% divisions based on the cell score function from regionScoreFun.
%
% INPUT :
%       dirname_ : seg folder eg. maindirectory/xy1/seg
%       nc_flag : no change flag, passed the second time in error resolution
%       runs
%       CONST : Constants file
%       header : information string.
% OUTPUT :
%       list_touch :
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


REMOVE_STRAY = CONST.trackOpti.REMOVE_STRAY;
OVERLAP_LIMIT_MIN = CONST.trackOpti.OVERLAP_LIMIT_MIN;
SCORE_LIMIT_DAUGHTER = CONST.trackOpti.SCORE_LIMIT_DAUGHTER;
SCORE_LIMIT_MOTHER = CONST.trackOpti.SCORE_LIMIT_MOTHER;
OVERLAP_LIMIT_MAX = CONST.trackOpti.OVERLAP_LIMIT_MAX;
AREA_CHANGE_LIMIT = CONST.trackOpti.AREA_CHANGE_LIMIT;
dA_LIMIT_ErRes = CONST.trackOpti.dA_LIMIT_ErRes;
dA_LIMIT = CONST.trackOpti.dA_LIMIT;
MAX_WIDTH = CONST.trackOpti.MAX_WIDTH;


if nargin < 2 || isempty(nc_flag);
    nc_flag = 0;
end

if ~exist('header','var')
    header = 'ErRes no header';
end

list_touch = [];

if(nargin<1 || isempty(dirname))
    dirname='.';
end
dirname = fixDir(dirname);

contents=dir([dirname '*_trk.mat']);
if isempty(contents)
    contents=dir([dirname '*_err.mat']);
end

num_im = length(contents);

if CONST.parallel.show_status
    h = waitbar( 0, 'Error Resolution');
else
    h = [];
end

list_change_last = [];
break_flag = 0;
i = 1;
cell_count = 0;

while i <= num_im % loop through number of frames
    
    if CONST.parallel.show_status
        waitbar((i-1)/num_im,h,['Error Resolution--Frame: ',...
            num2str(i),'/',num2str(num_im)])
    end
    
    if (i ==1) && (1 == num_im) % if there is only one image
        data_r = [];
        data_c = loaderInternal([dirname,contents(i).name]);
        data_f = [];
    elseif i == 1 % first frame - load current and forward
        data_r = [];
        data_c = loaderInternal([dirname,contents(i).name]);
        data_f = loaderInternal([dirname,contents(i+1).name]);
    elseif i == num_im % last frame - load reverse and currrent
        data_r = loaderInternal([dirname,contents(i-1).name]);
        data_c = loaderInternal([dirname,contents(i).name]);
        data_f = [];
    else % all other frames
        data_r = loaderInternal([dirname,contents(i-1).name]);
        data_c = loaderInternal([dirname,contents(i).name]);
        data_f = loaderInternal([dirname,contents(i+1).name]);
    end
    
    
    % Calculate overlaps
    % Loop through regions    
    list_c_del = [];
    list_f_add = [];
    list_r_add = [];
    
    for ii = 1: data_c.regs.num_regs
        
        if isfield( data_c.regs, 'ignoreError' );
            ignoreError = data_c.regs.ignoreError(ii);
        else
            ignoreError  = 0;
        end
        
        % first frame only: set stray flag for regions that don't map to
        % any regions in the next frame.
        if (i == 1) && isempty(data_c.regs.map.f{ii}) && (num_im>1)
            if ~ignoreError
                if REMOVE_STRAY
                    if ~nc_flag
                        disp([header, 'ErRes: Frame: ', num2str(i), ', reg: ',...
                            num2str(ii),'. removed stray region' ]);
                        
                        % if the regions are mapped to by nobody of map into
                        % nobody, zero them out.                        
                        list_c_del = [list_c_del, ii];
                        data_c.regs.stat0(ii) = 3;
                        % set the break flag to recalculate the regions
                        break_flag = 1;                       
                    end
                else
                    data_c.regs.error.label{ii} = ['Frame: ', ...
                        num2str(i), ', reg: ', num2str(ii),...
                        '. is a stray region.'];
                    disp( [header, 'ErRes: ',data_c.regs.error.label{ii}] );
                end
            end
        end
        
        % list of the regs that the current regions maps to in last Frame
        list_r     = data_c.regs.map.r{ii};
        list_f     = data_c.regs.map.f{ii};
        
 
        
        if ~isempty(list_r) && all(data_r.regs.stat0(list_r)==3)
            stray_flag = 1;
            data_c.regs.error.r(ii) = 1;
        else
            stray_flag = 0;
        end
        
        
        if ~data_c.regs.error.r(ii) || ismember(ii,list_change_last) ...
                || ismember(ii,list_c_del)
            % update if no error, region in deleted list or changed last
            if (i>1) && (numel(list_r) > 0)
                % not first frame, and maps to something
                    disp (['updating cell from id ', num2str(data_r.regs.ID(list_r))]);
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, list_r(1), i, 0, [], cell_count);
            else % first frame or maps to nothing
                [data_c, data_r, cell_count] = update_cell( ...
                    data_c, ii, data_r, list_r, i, 0, [], cell_count);
            end
        else
            
            % error flags for region ii are set in this script
            setFlagsErRes;
            
            if stray_flag
                % Stray Region : gets rid of regions that appear from nowhere.
                % map to nowhere and map to nothing
                if ignoreError
                    % creates a new cell
                    data_c.regs.error.r(ii) = 0;
                    data_r.regs.error.f(list_r(1)) = 0;
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, list_r(1), i, 0, [], cell_count);
                else
                    if REMOVE_STRAY
                        if ~nc_flag
                            % add the region to the regions to be deleted
                            disp([header, 'ErRes: Frame: ', num2str(i),...
                                ', reg: ', num2str(ii),'. removed stray region' ])
                            list_c_del = [list_c_del, ii];
                            data_c.regs.stat0(ii) = 3;
                            break_flag = 1; % to recalculate the regions
                            
                        end
                    else
                        data_c.regs.error.label{ii} = ['Frame: ', ...
                            num2str(i), ', reg: ', num2str(ii),...
                            '. is a stray region.'];
                        disp([header, 'ErRes: ',data_c.regs.error.label{ii}] );
                    end
                end
            elseif cshift_flag
                % Cell sometiems shift rapidly because of being pushed
                % Clear the error if the cell size doesn't change very much
                if ignoreError
                    % continue the cell with id of list_r(1)
                    data_c.regs.error.r(ii) = 0;
                    data_r.regs.error.f(list_r(1)) = 0;
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, list_r(1), i, 0, [], cell_count);
                else  
                    if  ~isempty( data_c.regs.dA.r(ii) ) && (data_c.regs.dA.r(ii) > dA_LIMIT_ErRes)
                        % area changed by less than dA_Limit_Res
                        % clear error and continue cell
                        data_c.regs.error.label{ii} = (['Frame: ', ...
                            num2str(i), ', reg: ', num2str(ii),'. Cell shift.']);                     
                        disp([header, 'ErRes: ', data_c.regs.error.label{ii}] );
                        data_c.regs.error.r(ii) = 0;
                        data_r.regs.error.f(list_r(1)) = 0;
                        [data_c, data_r, cell_count] = update_cell( ...
                            data_c, ii, data_r, list_r(1), i, 0, [], cell_count);
                    else
                        % continue cell but keep the error
                        data_c.regs.error.label{ii} = ['Frame: ', num2str(i), ', reg: ', ...
                            num2str(ii),...
                            '. Cell shift failed due dA: ',num2str(data_c.regs.dA.r(ii),3), ' < ',...
                            num2str(dA_LIMIT_ErRes,3),'.'];
                        disp([header, 'ErRes: ', data_c.regs.error.label{ii}] );
                        [data_c, data_r, cell_count] = update_cell( ...
                            data_c, ii, data_r, list_r(1), i, 0, [], cell_count);
                    end
                end
                
            elseif localMapGoodFlag
                data_c.regs.error.label{ii} = (['Frame: ', num2str(i), ...
                    ', reg: ', num2str(ii),'. LocalMapGoodFlag.']);
                disp([header, 'ErRes: ', data_c.regs.error.label{ii}] );
                data_c.regs.error.r(ii) = 0;
                if ~isempty(list_r)
                    % remove error in reverse frame
                    data_r.regs.error.f(list_r(1)) = 0;
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, list_r(1), i, 0, [], cell_count);
                else
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, [], i, 0, [], cell_count);
                end
                
            elseif merged_flag
                % when two regions in data_r correspond to one in data_c
                % possible merging of region in data_c, attempts to find a 
                % segment that was missed.
                if ignoreError
                    % remove errors
                    data_c.regs.error.r(ii) = 0;
                    data_r.regs.error.f(list_r(1)) = 0;
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, list_r(1), i, 0, [], cell_count);
                else                 
                    [data_new, ind_new] = fix2to1 (data_c, ii, data_r, data_c.regs.map.r{ii});                     
                    if isempty( data_new ) || nc_flag                       
                        data_c.regs.error.label{ii} = ...
                            ['Frame: ', num2str(i), ', reg: ', num2str(ii),...
                            '. Merged fix fails'];
                        disp([header, 'ErRes: ',data_c.regs.error.label{ii}]);
                        data_c.regs.error.r(ii) = 2;
                        [data_c, data_r, cell_count] = update_cell( ...
                            data_c, ii, data_r, list_r(1), i, 1, [], cell_count);
                    else                        
                        data_c = deleteRegions( data_c, ii);
                        data_c = addRegions(data_c, data_new, ind_new );     
                        break_flag = 1;
                        data_c.regs.error.label{ii} = ...
                            ['Frame: ', num2str(i), ', reg: ', num2str(ii),...
                            '. Merged fixed.'];
                        disp([header, 'ErRes: ',data_c.regs.error.label{ii}]);
                    end
                end
            elseif fskip_flag
                % One frame skip :
                % This method of error resolution attempts to resolve the
                % error by checking if there in no error in a map between the
                % overlapping regions in the previous and next frames. If this
                % is true, the regions from the next frame, that overlap the
                % error segment, are copied into the current frame.
                if ignoreError
                    data_c.regs.error.r(ii) = 0;
                    data_r.regs.error.f(list_r(1)) = 0;
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, list_r(1), i, 0, [], cell_count);
                else
                    if ~nc_flag
                        % project the overlapping regions in the previous frame to
                        % the next frame
                        list_rcrf    = unique([data_c.regs.map.rf{list_rcr}]);
                        list_rcrfc   = unique([data_f.regs.map.r{list_rcrf}]);
                        list_rcrfcf  = unique([data_c.regs.map.f{list_rcrfc}]);
                        list_rcrfcfc = unique([data_f.regs.map.r{list_rcrfcf}]);
                        
                        if numel(list_rcrfcfc) > numel(list_rcrfc)                            
                            data_c.regs.error.label{ii} = ['Frame: ', num2str(i),...
                                ', reg: ', ...
                                num2str(ii),'. has mapping error. Cannot recovered.'];
                            disp([header, 'ErRes: ', data_c.regs.error.label{ii}] );
                            [data_c, data_r, cell_count] = update_cell( ...
                                data_c, ii, data_r, list_r(1), i, 1, [], cell_count);
                        elseif (numel(list_rcrfcfc) == 0) || (numel(list_rcrfc) == 0)
                            data_c.regs.error.label{ii} = ['Frame: ', num2str(i),...
                                ', reg: ', ...
                                num2str(ii),'. has mapping error. Attempted frame', ...
                                'skip but no regions added/deled. Cannot recovered.'];
                            disp([header, 'ErRes: ', data_c.regs.error.label{ii}] );
                            [data_c, data_r, cell_count] = update_cell( ...
                                data_c, ii, data_r, list_r(1), i, 1, [], cell_count);
                        else
                            data_c.regs.error.label{ii} = ['Frame: ', num2str(i),...
                                ', reg: ', num2str(ii),'. fixed an error by frame skipping.'];
                            disp([header, 'ErRes: ',data_c.regs.error.label{ii}]);
                            
                            % zero out connected segments in the current frame;
                            list_c_del = [list_c_del, list_rcrfc];
                            list_f_add = [list_f_add, list_rcrfcf];

                            % Set changes flag and break the segment loop.
                            break_flag = 1;
                        end
                    end
                end
            elseif split_flag
                % region in current frame split in the previous frame or current frame
                % attempt to resegment and delete regions
                if ignoreError
                    data_c.regs.error.r(ii) = 0;
                    data_r.regs.error.f(list_r(1)) = 0;
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, list_r(1), i, 0, [], cell_count);
                else
                    if ~nc_flag
                        data_c.regs.error.label{ii} = ['Frame: ', num2str(i),...
                            ', reg: ', num2str(ii),'. Splitting'];
                        disp([header, 'ErRes: ', data_c.regs.error.label{ii}]);
                        
                        [xx,yy] = getBB( data_c.regs.props(ii).BoundingBox);               
                        mask = (data_c.regs.regs_label(yy,xx)==ii);                      
                        reseg = -double(mask);
                        
                        for mm = list_r;
                            reseg = reseg + -double(data_r.regs.regs_label(yy,xx)==mm);
                        end
                        for mm = list_f;
                            reseg = reseg + -double(data_f.regs.regs_label(yy,xx)==mm);
                        end
                        
                        try
                            ws = double(watershed(reseg)).*mask;
                        catch
                            keyboard;
                        end
                        data_c = deleteRegions( data_c, ii);
                        data_c.regs.regs_label(yy,xx) = data_c.regs.regs_label(yy,xx)+ double(ws>0)*ii;
                        data_c.mask_cell(yy,xx) = data_c.mask_cell(yy,xx)+ double(ws>0);
                        break_flag = 1;
                    end
                end
            elseif s21_flag
                % From 2 regions to 1 Stable
                % This error occurs when cells combine and cannot be resolved 
                % by skipping. It attempts to turn on regions to fix this.
                if ignoreError
                    data_c.regs.error.r(ii) = 0;
                    data_r.regs.error.f(list_r(1)) = 0;
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, list_r(1), i, 0, [], cell_count);
                else   
                    [data_new, ind_new] = fix2to1( data_c, ii, data_r, data_c.regs.map.r{ii} );
                    if isempty( data_new ) || nc_flag
                        % stable : the error cannot be resolved.
                        data_c.regs.error.label{ii} = ...
                            ['Frame: ', num2str(i), ', reg: ', num2str(ii),...
                            '. 2 -> 1 stable'];
                        disp([header, 'ErRes: ',data_c.regs.error.label{ii}]);
                        data_c.regs.error.r(ii) = 2;
                        [data_c, data_r, cell_count] = update_cell( ...
                            data_c, ii, data_r, list_r(1), i, 1, [], cell_count);
                    else
                        data_c = deleteRegions( data_c, ii);
                        data_c = addRegions( data_c, data_new, ind_new );                       
                        break_flag = 1;
                        data_c.regs.error.label{ii} = ...
                            ['Frame: ', num2str(i), ', reg: ', num2str(ii),...
                            '. 2 -> 1 fixed'];
                        disp([header, 'ErRes: ',data_c.regs.error.label{ii}]);
                    end    
                end 
            elseif s12_flag
                % 1 to 2 regions 
                % This is an error compatible with cell division. If the
                % intial and final cells have a reasonable size, clear the
                % error and let this event be considered a cell division.
                
                tmp_list = list_rc(1:2);
                
                % check for the existence ignore error flag for back
                % compatibility
                if isfield( data_c.regs, 'ignoreError' );
                    ignoreErrorM  = data_r.regs.ignoreError(list_r(1));
                    ignoreErrorD1 = data_c.regs.ignoreError(tmp_list(1));
                    ignoreErrorD2 = data_c.regs.ignoreError(tmp_list(2));
                else
                    ignoreErrorM  = 0;
                    ignoreErrorD1 = 0;
                    ignoreErrorD2 = 0;
                end
                
                errorM  = ((data_r.regs.scoreRaw(list_r(1))   < ...
                    SCORE_LIMIT_MOTHER   ) && ~ignoreErrorM  );
                errorD1 = ((data_c.regs.scoreRaw(tmp_list(1)) < ...
                    SCORE_LIMIT_DAUGHTER ) && ~ignoreErrorD1 );
                errorD2 = ((data_c.regs.scoreRaw(tmp_list(2)) < ...
                    SCORE_LIMIT_DAUGHTER ) && ~ignoreErrorD2 );
                
                if ~(errorM || errorD1 || errorD2)
                    data_c.regs.error.label{ii} = (['Frame: ', num2str(i),...
                        ', reg: ', num2str(ii),'. good cell division. [L1,L2,Sc] = [',...
                        num2str(data_c.regs.L1(ii),2),', ',num2str(data_c.regs.L2(ii),2),...
                        ', ',num2str(data_c.regs.scoreRaw(ii),2),'].']);
                    disp([header, 'ErRes: ', data_c.regs.error.label{ii}] );
                    data_c.regs.error.r(ii) = 0;
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, list_r(1), i, 0, tmp_list(ii~=tmp_list), cell_count);
                else
                    data_c.regs.error.label{ii} = ['Frame: ', num2str(i),...
                        ', reg: ', num2str(ii),...
                        '. 1 -> 2 stable, but not good cell [sm,sd1,sd2,slim] = ['...
                        num2str(data_r.regs.scoreRaw(list_r(1)),2),', ',...
                        num2str(data_c.regs.scoreRaw(tmp_list(1)),2),', ',...
                        num2str(data_c.regs.scoreRaw(tmp_list(2)),2),...
                        ', ',num2str(SCORE_LIMIT_MOTHER,2), ', ',...
                        num2str(SCORE_LIMIT_DAUGHTER,2),'].'];
                    disp([header, 'ErRes: ', data_c.regs.error.label{ii}] );
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, list_r(1), i, 1, tmp_list(ii~=tmp_list), cell_count);
                end
            elseif localMapGoodFlagEnd
                % change in area with reverse region
                % is in between  2*DA_MIN and 2*DA_MAX
                data_c.regs.error.label{ii} = (['Frame: ', num2str(i), ...
                    ', reg: ', num2str(ii),'. LocalMapGoodFlagEnd.']);             
                disp([header, 'ErRes: ', data_c.regs.error.label{ii}] );
                data_c.regs.error.r(ii) = 0;
                if ~isempty(list_r)
                    data_r.regs.error.f(list_r(1)) = 0;
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, list_r(1), i, 0, [], cell_count);
                else
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, [], i, 0, [], cell_count);
                end
            else
                % unresolved error
                % none of the choices above were able to resolve it
                if ignoreError
                    data_c.regs.error.r(ii) = 0;
                    data_r.regs.error.f(list_r(1)) = 0;
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, list_r(1), i, 0, [], cell_count);
                else
                    data_c.regs.error.label{ii} = ...
                        ['Frame: ', num2str(i), ', reg: ', ...
                        num2str(ii),'. error NOT fixed'];
                    disp([header, 'ErRes: ',data_c.regs.error.label{ii}]);
                end
                
                if ~isempty(list_r )
                    fix_flag = 0;
                    [data_c, data_r, cell_count] = update_cell( ...
                        data_c, ii, data_r, list_r(1), i, ~fix_flag, [], cell_count);
                end
            end
        end
    end
    
    
    if break_flag
        if ~isempty( list_c_del );
            list_c_del = unique(list_c_del);
            [data_c] = deleteRegions( data_c, list_c_del);
        end
        
        if ~isempty( list_f_add );
            list_f_add = unique(list_f_add);
            [data_c] = addRegions(data_c,data_f,list_f_add);
            
        end
        
        if i == 1
            list_touch = [list_touch,i,i+1];
        elseif i == num_im
            list_touch = [list_touch,i-1,i];
        else
            list_touch = [list_touch,i-1,i,i+1];
        end
    end
    
    list_change_last = list_f_add;
    
    if (i>1) && nc_flag;
        [data_c,data_r] = intRepairErr( data_c,data_r);
    end
    
    dataname=[dirname,contents(i).name(1:length(contents(i).name)-7),'err.mat'];
    save(dataname,'-STRUCT','data_c');
    if (i>1) && nc_flag;
        dataname=[dirname,contents(i-1).name(1:length(contents(i).name)-7),'err.mat'];
        save(dataname,'-STRUCT','data_r');
    end
    
    break_flag = 0;
    i = i+1;
    
end

if CONST.parallel.show_status
    close(h);
end

list_touch = sort(unique(list_touch));

if ~isempty( list_touch)
    disp('Linking again the frames that had segments modified')
    trackOptiLink(dirname,[],sort(list_touch),1,CONST,header);
    %trackOptiLinkNew(dirname,[],sort(list_touch),'*err.mat',CONST,header);
end
end


function data = loaderInternal( filename )
filename_mod = [filename(1:end-7),'err.mat'];
fid = fopen(filename_mod);

if  fid == -1
    data = load( filename );
else
    fclose(fid);
    data =  load( filename_mod );
end

end

