function clist = trackOpti(dirname,skip,CONST, CLEAN_FLAG, header)
% trackOpti : calls the rest of the functions for segmentation 
% After each sub-function is called, is creates a file in the seg directory
% that begins with .trackOpti (they are hidden, you?ll have to use ?ls -a?
% to see these)  and then the function name, e.g. .trackOptiSetEr.mat. 
% This is designed in case the segmentation dies somewhere in middle and you
% want to restart without having to recalculate everything;
% if these files exist, it won't rerun that particular function again. 
% If you DO need to rerun one of these functions, you'll 
% have to delete the respective .trackOpti file for it to work.
%
% INPUT :
%       dirname: xy folder
%       skip : frames to be skipped in segmentation, default is 1.
%       CONST : Constants file
%       CLEAN_FLAG : 0 (default) continue from previous stop point 
%                    1 clean everything and restart segmentation
%       header : information string
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

% init
% if the CLEAN_FLAG does not exist, set it to true and remove all existing
% files. This is the safer option.
if ~exist('CLEAN_FLAG') || isempty( CLEAN_FLAG )
    CLEAN_FLAG = true;
end

if ~exist('header')
    header = [];
    header = 'trackOpti no header: ';
end

% turn skip off if skip isn't set.
if isempty( skip )
    skip = 1;
end


if nargin < 1 || isempty( dirname );
    dirname = '.';
end

% fix the dirname if it doesn't end in a slash.
dirname = fixDir( dirname )
dirname_seg  = [dirname,'seg',filesep];

dirname_cell = [dirname,'cell',filesep];
if ~exist( dirname_cell, 'dir' )
   mkdir(  dirname_cell );
end

dirname_full = [dirname,'seg_full',filesep];


%% Clean directories
if CLEAN_FLAG
            delete ([dirname,'clist.mat']);        
        delete ([dirname_seg,'*trk.mat']);
        delete ([dirname_seg,'*err.mat']);
        delete ([dirname_cell,'*.mat']);
        delete ([dirname_cell,'.trackOpti*']);
        delete ([dirname_seg,'.trackOpti*']);
        if skip > 1
            delete ([dirname_full,'*.mat']);
            delete ([dirname_full,'.trackOpti*']);
        end
%     if ispc % widnows system
%         eval(['!del ',dirname,'clist.mat']);        
%         eval(['!del ',dirname_seg,'*trk.mat']);
%         eval(['!del ',dirname_seg,'*err.mat']);
%         eval(['!del ',dirname_cell,'*.mat']);
%         eval(['!del ',dirname_cell,'.trackOpti*']);
%         eval(['!del ',dirname_seg,'.trackOpti*']);
%         if skip > 1
%             eval(['!del ',dirname_full,'*.mat']);
%             eval(['!del ',dirname_full,'.trackOpti*']);
%         end
%     else
%         eval(['!\rm ',dirname,'clist.mat']);        
%         eval(['!\rm ',dirname_seg,'*trk.mat']);
%         eval(['!\rm ',dirname_seg,'*err.mat']);
%         eval(['!\rm ',dirname_cell,'*.mat']);
%         eval(['!\rm ',dirname_cell,'.trackOpti*']);
%         eval(['!\rm ',dirname_seg,'.trackOpti*']);
%         if skip > 1
%             eval(['!\rm ',dirname_full,'*.mat']);
%             eval(['!\rm ',dirname_full,'.trackOpti*']);
%         end
%     end
else
    % if ErRes2 has not been cleared, wipe out err.mat files
    if skip > 1
        stamp_name1 = [dirname_seg,'.trackOptiLink.mat'];
        stamp_name2 = [dirname_full,'.trackOptiErRes2.mat'];
        if exist( stamp_name1, 'file' ) && ~exist( stamp_name2, 'file' )
            delete ([dirname_seg,'*err.mat']);
            delete ([dirname_full,'*err.mat']);
            
%             
%             if ispc
%                 
%                 eval(['!del ',dirname_seg,'*err.mat']);
%                 eval(['!del ',dirname_full,'*err.mat']);
%             else
%                 eval(['!\rm ',dirname_seg,'*err.mat']);
%                 eval(['!\rm ',dirname_full,'*err.mat']);
%             end
        end
    else
        stamp_name1 = [dirname_seg,'.trackOptiLink.mat'];
        stamp_name2 = [dirname_seg,'.trackOptiErRes2.mat'];
        if exist( stamp_name1, 'file' ) && ~exist( stamp_name2, 'file' )
            delete ([dirname_seg,'*err.mat']);
%             if ispc
%                 eval(['!del ',dirname_seg,'*err.mat']);
%             else
%                 eval(['!\rm ',dirname_seg,'*err.mat']);
%             end
        end
    end
end


%% trackOptiStripMig
% removes small regions that are probably not real (bubbles, dust, or minicells)
stamp_name = [dirname_seg,'.trackOptiStripMig.mat'];
if ~exist( stamp_name, 'file' );
    trackOptiStripMig(dirname_seg, CONST);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header, 'trackOpti: trackOptiStripMig already run.'] );
end

%% Link frames
% Calculate the overlap between cells between subsequent frames.
stamp_name = [dirname_seg,'.trackOptiLink.mat'];
if ~exist( stamp_name, 'file' );
    trackOptiLink(dirname_seg, [], [], 0, CONST, header);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header, 'trackOpti: trackOptiLink already run.'] );
end

%% Er Res (1)
% Define and resolve errors and relink if regions have changed
stamp_name = [dirname_seg,'.trackOptiErRes1.mat'];
if ~exist( stamp_name, 'file' );
    list_touch = trackOptiErRes(dirname_seg, [], [], CONST, header);
    disp([header, 'trackOpti: ErRes modified ', num2str(numel(list_touch)),' frames.']);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header,'trackOpti: trackOptiErRes (1) already run.']);
end



%% Set Er
% reset errors before resolving errors for a second time
stamp_name = [dirname_seg,'.trackOptiSetEr.mat'];
if ~exist( stamp_name, 'file' );
    trackOptiSetEr(dirname_seg, CONST, header);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header,'trackOpti: trackOptiSetEr already run.']);
end



%% Skip Merge
% cflag is the ~ skip flag. If true the skipping is taken care of later.
if skip>1
    % merges skipped frames into the seg_full dir
    dirname_seg  = dirname_full;
    stamp_name = [dirname_seg,'.trackOptiSkipMerge.mat'];
    if ~exist( stamp_name, 'file' );
        trackOptiSkipMerge(dirname,skip,CONST, header);
        time_stamp = clock;
        save( stamp_name, 'time_stamp');
    else
        disp([header,'trackOpti: trackOptiSkipMerge already run.']);
    end
    
    % Relinks the new skipMerge files
    stamp_name = [dirname_seg,'.trackOptiLink.mat'];
    if ~exist( stamp_name, 'file' );
        trackOptiLink(dirname_seg, [], [], 1, CONST, header);
        time_stamp = clock;
        save( stamp_name, 'time_stamp');
    else
        disp([header,'trackOpti: trackOptiLink already run.']);
    end
    
end

%% ErRes (2)
% Resolve Errors passing the no change flag as the last argument
stamp_name = [dirname_seg,'.trackOptiErRes2.mat'];
if ~exist( stamp_name, 'file' );
    list_touch = trackOptiErRes(dirname_seg,[],1, CONST, header);
    disp([header,'trackOpti: ErRes: modified ', num2str(numel(list_touch)),' frames.']);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header,'trackOpti: trackOptiErRes(2) already run.']);
end


%% Cell Marker
% trackOptiCellMarker marks complete cells cycles. clist contains a
% list of cell statistics etc.
stamp_name = [dirname_seg,'.trackOptiCellMarker.mat'];
if ~exist( stamp_name, 'file' );
    trackOptiCellMarker(dirname_seg, CONST, header);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header,'trackOpti: trackOptiCellMarker already run.']);
end

%% Fluor
% Calculates Fluorescence Background
stamp_name = [dirname_seg,'.trackOptiFluor.mat'];
if ~exist( stamp_name, 'file' );  
    trackOptiFluor(dirname_seg,CONST, header);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header,'trackOpti: trackOptiFluor already run.']);
end


%% Make Cell
% Computes cell characteristics in make cells
stamp_name = [dirname_seg,'.trackOptiMakeCell.mat'];
if ~exist( stamp_name, 'file' );
    trackOptiMakeCell(dirname_seg, CONST, header);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header,'trackOpti: trackOptiMakeCell already run.']);
end


%% Find loci in each fluorescent channel
if sum(CONST.trackLoci.numSpots(:))
    stamp_name = [dirname_seg,'.trackOptiFindLoci.mat'];
    if ~exist( stamp_name, 'file' );
        trackOptiFindLoci(dirname_seg, CONST, header);
        time_stamp = clock;
        save( stamp_name, 'time_stamp');
    else
        disp([header,'trackOpti: trackOptiFindLoci already run.']);
    end
end

%% Compute cell characteristics in make cells
stamp_name = [dirname_seg,'.trackOptiClist.mat'];
if ~exist( stamp_name, 'file' );
    [clist] = trackOptiClist(dirname_seg, CONST, header);
    
    if isfield( CONST, 'gate' )
        clist.gate = CONST.gate;    
    end
    
    try
        save( [dirname,'clist.mat'],'-STRUCT','clist');
    catch
        disp([header,'trackOpti: Cell list error being saved.']);
    end
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header,'trackOpti: trackOptiClist already run.']);
end

%% cell files
% Organize data into cell files that contain all the time lapse data
% for a single cell.
stamp_name = [dirname_seg,'.trackOptiCellFiles.mat'];

if ~exist( stamp_name, 'file' );
    clist = load([dirname,'clist.mat']);
    if isfield( CONST, 'gate' )
        clist.gate = CONST.gate;    
    end
    % wipe old cell files
    if ispc
        eval(['!del ',dirname_cell,'cell*.mat']);
        eval(['!del ',dirname_cell,'cell*.mat']);
    else
        eval(['!\rm ',dirname_cell,'cell*.mat']);
        eval(['!\rm ',dirname_cell,'Cell*.mat']);

    end

    trackOptiCellFiles(dirname_seg,dirname_cell,CONST, header, clist);        
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header,'trackOpti: trackOptiCellFiles already run.']);
end



end


