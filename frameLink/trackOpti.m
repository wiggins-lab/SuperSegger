function clist = trackOpti(dirname,skip,CONST, header, startEnd) 
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
%       header : information string
%       startEnd : start and end stage
% OUTPUT :
%       clist : list of cells with time-independent information about each
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Stylianidou & Paul Wiggins
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



% if the CLEAN_FLAG does not exist, set it to true and remove all existing
% files. This is the safer option.
% if ~exist('CLEAN_FLAG') || isempty( CLEAN_FLAG )
%     CLEAN_FLAG = true;
% end

if ~exist('header','var')
    header = 'trackOpti no header: ';
end

% turn skip off if skip isn't set.
if ~exist('skip','var') || isempty(skip)
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

if ~exist( 'startEnd', 'var' ) || isempty( startEnd )
    startEnd = [1 20];
end


%% trackOptiStripSmall
% removes small regions that are probably not real (bubbles, dust, or minicells)
stamp_name = [dirname_seg,'.trackOptiStripSmall-Step1.mat'];
if ~exist( stamp_name, 'file' ) && (startEnd(1) <= 3 && startEnd(2) >= 3)
    disp([header,'trackOpti - Step 1: Running trackOptiStripSmall.']);
    trackOptiStripSmall(dirname_seg, CONST);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header, 'trackOpti: trackOptiStripSmall already run.'] );
end

%% Link frames and do error resolution
% Calculate the overlap between cells between subsequent frames.
stamp_name = [dirname_seg,'.trackOptiLinkCell-Step2.mat'];
if ~exist( stamp_name, 'file' ) && (startEnd(1) <= 4 && startEnd(2) >= 4)
    disp([header,'trackOpti - Step 2: Running trackOptiLinkCell.']);
    delete_old_err_files = 1;
    trackOptiLinkCellMulti(dirname_seg, delete_old_err_files, CONST, header);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header, 'trackOpti: trackOptiLinkCell already run.'] );
end

%% Skip Merge
% If skip is bigger than 1, it takes care of merging all the frames skipped.
% the merged skipped frames are placed in the seg_full dir
if skip>1  && ( startEnd(1) <= 4 && startEnd(2) >= 4)
    dirname_seg  = dirname_full; % change dirname_seg to seg_all directory
    stamp_name = [dirname_seg,'.trackOptiSkipMerge-Step2merge.mat'];
    if ~exist( stamp_name, 'file' );
        disp([header,'trackOpti - Step 2, merge: Running trackOptiSkipMerge.']);
        trackOptiSkipMerge(dirname,skip,CONST, header);
        time_stamp = clock;
        save( stamp_name, 'time_stamp');
    else
        disp([header,'trackOpti: trackOptiSkipMerge already run.']);
    end
    
    % Relink and do error resolution for the skipped files
    stamp_name = [dirname_seg,'.trackOptiLinkCell-Step2merge.mat'];
    if ~exist( stamp_name, 'file' );
        disp([header,'trackOpti - Step 2, merge: Running trackOptiLinkCell.']);        
        trackOptiLinkCellMulti(dirname_seg, 1, CONST, header);
        time_stamp = clock;
        save( stamp_name, 'time_stamp');
    else
        disp([header,'trackOpti: trackOptiLink already run.']);
    end   
end


%% Cell Marker
% trackOptiCellMarker marks complete cells cycles. clist contains a
% list of cell statistics etc.
stamp_name = [dirname_seg,'.trackOptiCellMarker-Step3.mat'];
if ~exist( stamp_name, 'file' ) && (startEnd(1) <= 5 && startEnd(2) >= 5)
    disp([header,'trackOpti - Step 3: Running trackOptiCellMarker.']);        
    trackOptiCellMarker(dirname_seg, CONST, header);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header,'trackOpti: trackOptiCellMarker already run.']);
end

%% Fluor
% Calculates Fluorescence Background
stamp_name = [dirname_seg,'.trackOptiFluor-Step4.mat'];
if ~exist( stamp_name, 'file' )  && (startEnd(1) <= 6 && startEnd(2) >= 6)
    disp([header,'trackOpti - Step 4: Running trackOptiFluor.']);  
    trackOptiFluor(dirname_seg,CONST, header);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header,'trackOpti: trackOptiFluor already run.']);
end


%% Make Cell
% Computes cell characteristics and puts them in *err files under CellA{}
stamp_name = [dirname_seg,'.trackOptiMakeCell-Step5.mat'];
if ~exist( stamp_name, 'file' )  && (startEnd(1) <= 7 && startEnd(2) >= 7)
    disp([header,'trackOpti - Step 5: Running trackOptiMakeCell.']); 
    trackOptiMakeCell(dirname_seg, CONST, header);
    time_stamp = clock;
    save( stamp_name, 'time_stamp');
else
    disp([header,'trackOpti: trackOptiMakeCell already run.']);
end


%% Finds loci in each fluorescent channel
if sum(CONST.trackLoci.numSpots(:)) && (startEnd(1) <= 8 && startEnd(2) >= 8)
    stamp_name = [dirname_seg,'.trackOptiFindFoci-Step6.mat'];
    if ~exist( stamp_name, 'file' );
        disp([header,'trackOpti - Step 6: Running trackOptiFindFoci.']); 
        trackOptiFindFoci(dirname_seg, CONST, header);
        time_stamp = clock;
        save( stamp_name, 'time_stamp');
    else
        disp([header,'trackOpti: trackOptiFindFoci already run.']);
    end
end


%% Make the clist
stamp_name = [dirname_seg,'.trackOptiClist-Step7.mat'];
if ~exist( stamp_name, 'file' ) && (startEnd(1) <= 9 && startEnd(2) >= 9)
    disp([header,'trackOpti - Step 7: Running trackOptiClist.']);  
    
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
stamp_name = [dirname_seg,'.trackOptiCellFiles-Step8.mat'];

if ~exist( stamp_name, 'file' ) && (startEnd(1) <= 10 && startEnd(2) >= 10)
    disp([header,'trackOpti - Step 8: Running trackOptiCellFiles.']);  
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

warning('on','MATLAB:DELETE:Permission')

disp([header,'SuperSegger complete!']);

end


