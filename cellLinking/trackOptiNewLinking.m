function clist = trackOptiNewLinking(dirname,skip,CONST, CLEAN_FLAG, header)
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
%       dirname : xy folder
%       skip : frames to be skipped in segmentation, default is 1.
%       CONST : Constants file
%       CLEAN_FLAG : 0 (default) continue from previous stop point
%                    1 clean everything and restart segmentation
%       header : information string
% OUTPUT :
%       clist : list of cells with time-independent information about each
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
if isempty(skip)
    skip = 1;
end

% directories' names
if nargin < 1 || isempty( dirname );
    dirname = '.';
end

dirname = fixDir(dirname);
dirname_seg  = [dirname,'seg',filesep];
dirname_full = [dirname,'seg_full',filesep];
dirname_cell = [dirname,'cell',filesep];

if ~exist( dirname_cell, 'dir' )
    mkdir(  dirname_cell );
end



%% Clean directories
if CLEAN_FLAG
    delete ([dirname,'clist.mat']); % clist
    delete ([dirname_seg,'*err.mat']); % error files
    delete ([dirname_cell,'*.mat']); % cell files
    delete ([dirname_cell,'.trackOpti*']); 
    delete ([dirname_seg,'.trackOpti*']); % stamp files
    if skip > 1
        delete ([dirname_full,'*.mat']);
        delete ([dirname_full,'.trackOpti*']);
    end
end


%% trackOptiStripSmall
% removes small regions that are probably not real (bubbles, dust, or minicells)
stamp_name = [dirname_seg,'.trackOptiStripSmall.mat'];
if ~exist( stamp_name, 'file' );
    trackOptiStripSmall(dirname_seg, CONST);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header, 'trackOpti: trackOptiStripSmall already run.'] );
end

%% Link frames and do error resolution
% Calculate the overlap between cells between subsequent frames.
stamp_name = [dirname_seg,'.trackOptiLinkCell.mat'];
if ~exist( stamp_name, 'file' );
    trackOptiLinkCellMulti(dirname_seg, 0, CONST, header);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header, 'trackOpti: trackOptiLinkCell already run.'] );
end

%% Skip Merge
% If skip is bigger than 1, it takes care of merging all the frames skipped.
% the merged skipped frames are placed in the seg_full dir
if skip>1
    dirname_seg  = dirname_full; % change dirname_seg to seg_all directory
    stamp_name = [dirname_seg,'.trackOptiSkipMerge.mat'];
    if ~exist( stamp_name, 'file' );
        trackOptiSkipMerge(dirname,skip,CONST, header);
        time_stamp = clock;
        save( stamp_name, 'time_stamp');
    else
        disp([header,'trackOpti: trackOptiSkipMerge already run.']);
    end
    
    % Relink and do error resolution for the skipped files
    stamp_name = [dirname_seg,'.trackOptiLinkCell.mat'];
    if ~exist( stamp_name, 'file' );
        trackOptiLinkCellMulti(dirname_seg, 0, CONST, header);
        time_stamp = clock;
        save( stamp_name, 'time_stamp');
    else
        disp([header,'trackOpti: trackOptiLink already run.']);
    end
    
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
% Computes cell characteristics and puts them in *err files under CellA{}
stamp_name = [dirname_seg,'.trackOptiMakeCell.mat'];
if ~exist( stamp_name, 'file' );
    trackOptiMakeCell(dirname_seg, CONST, header);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header,'trackOpti: trackOptiMakeCell already run.']);
end


%% Finds loci in each fluorescent channel
if sum(CONST.trackLoci.numSpots(:))
    stamp_name = [dirname_seg,'.trackOptiFindFociCyto.mat'];
    if ~exist( stamp_name, 'file' );
        trackOptiFindFociCyto(dirname_seg, CONST, header);
        time_stamp = clock;
        save( stamp_name, 'time_stamp');
    else
        disp([header,'trackOpti: trackOptiFindFociCyto already run.']);
    end
end


%% Computes cell characteristics in make cells
stamp_name = [dirname_seg,'.trackOptiClist.mat'];
if ~exist( stamp_name, 'file' );
    [clist] = trackOptiClist(dirname_seg, CONST, header);
    
    if isfield( CONST, 'gate' )
        clist.gate = CONST.gate;
    end
    
    try
        save( [dirname,'clist.mat'],'-STRUCT','clist');
    catch ME
        printError(ME);
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
    % delete old cell files
    delete ([dirname_cell,'cell*.mat']);
    delete ([dirname_cell,'Cell*.mat']);
    
    trackOptiCellFiles(dirname_seg,dirname_cell,CONST, header, clist);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header,'trackOpti: trackOptiCellFiles already run.']);
end



end


