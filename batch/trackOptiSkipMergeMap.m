function trackOptiSkipMergeMap(dirname_seg,skip,CONST,header)
% trackOptiSkipMerge : adds skipped frames back into the time series.
% It makes the _err.mat files with the fluor images corresponding 
% to the current time step. The new _err files are placed in seg_full.
% Frame skip is useful for reducing errors which you have a high frame rate. 
%
% INPUT : 
%   dirname_xy: is the xy directory
%   skip: frames mod skip are processed 
%   CONST: segmentation constants
%   header : string displayed with information
% 
% Copyright (C) 2016 Wiggins Lab 
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

if ~exist('header')
    header = [];
end

if nargin < 2 || isempty( skip )
    skip = 1; % don't skip frames
end

file_filter = '*err.mat';
dirname_seg = fixDir(dirname_seg)

% get error files from seg_fill
contents=dir([dirname_seg,file_filter]);
num_im = numel(contents);
nt = zeros(1, num_im);

% reset nz values
for i = 1:num_im;
    nameInfo = ReadFileName(contents(i).name);    
    nt(i) = nameInfo.npos(1,1);
end

nt = sort(unique(nt));
num_t = numel(nt);

if CONST.parallel.show_status
    h = waitbar( 0, ['Mapping merged skipped frames xy: 0/',num2str(num_t)] );
else
    h=[];
end

% go through the reference frames frames
% mapping is already copied from trackOptiSkipMerge, all we have to do 
% is copy the ids, divide etc..?

for i=1:num_t;
    % get reference mapping
    
    
    if ~mod(i-1,skip) % first one
        % keep births, but not deaths, and divisions..?
   divide
   
    % loads the data reference for the min merge of z phase, sets tha name and
    % nameInfo, and the fluorescence field from the image to be merged.
    if mod(i-1,skip)
        data.phase = phase;
        data.basename = name;
        nameInfo_tmp = nameInfo;
        for k = 2:num_c
            % load fluor image for each channel X and put it in data.fluorX
            nameInfo_tmp.npos(1,1) = nt(i);
            nameInfo_tmp.npos(2,1) = nc(k);
            nameInfo_tmp.npos(4,1) = 1;
            name = MakeFileName( nameInfo_tmp );
            fluorImage = imread( [dirname_xy,'fluor',num2str(nc(k)-1),filesep,name]);
            data.(['fluor',num2str(nc(k)-1)]) = fluorImage;
        end    
    end


 
    if CONST.parallel.show_status && ~CONST.parallel.PARALLEL_FLAG
        waitbar(i/num_t,h,...
            ['Merging Skipped frames t: ',num2str(i),'/',num2str(num_t)]);
    else
        disp( [header, 'skipMerge: No status bar. Frame ',num2str(i), ...
            ' of ', num2str(num_t),'.']);
    end
    
end

if CONST.parallel.show_status && ~CONST.parallel.PARALLEL_FLAG
    close(h);
end

end


function intSkipMapPar(i,dirname_xy,nameInfo,nt,nc,nz,skip,num_c,num_z)
% intSkipPar : makes the _err files for the frames skipped for each xy.
%
% INPUT :
%       i : index for frame number (time), used as nt(i)
%       dirname_xy : path for xy directory
%       nameInfo : information about name of the files
%       nt : list of time values
%       nc : list of unique channel values
%       nz : list of unique z values
%       skip : number of frames skipped during segmentation
%       num_c : total channel number
%       num_z : total z-axis positions


% make the segment file name and check if it already exists
nameInfo_tmp               = nameInfo;
nameInfo_tmp.npos([2,4],:) = 0;
nameInfo_tmp.npos(1,1)     = nt(i);
name                       = MakeFileName( nameInfo_tmp );
nameInfo_tmp               = ReadFileName(name);
name                       = name(1:max(nameInfo_tmp.npos(:,3)));

dataname2 =[dirname_xy,'seg_full', filesep,name,'_err.mat'];

nameInfo_tmp = nameInfo;
nameInfo_tmp.npos(1,1) = nt(i);
nameInfo_tmp.npos(4,1) = 1;
name = MakeFileName(nameInfo_tmp);

% do the min merge of z phase
phase = imread( [dirname_xy,'phase',filesep,name] );
for k = 2:num_z
    nameInfo_tmp.npos(4,1) = nz(k);
    name  = MakeFileName(nameInfo_tmp);
    phase =  min(phase, double(imread( [dirname_xy,'phase',filesep,name] )));
end

% Loads the reference _err file for the image already segmented
i_ref = i-mod(i-1,skip);
nameInfo_tmp_ref = nameInfo;
nameInfo_tmp_ref.npos([2,4],:) = 0;
nameInfo_tmp_ref.npos(1,1) = i_ref;
name_ref = MakeFileName( nameInfo_tmp_ref );
nameInfo_tmp_ref = ReadFileName(name_ref);
name_ref  = name_ref( 1:max(nameInfo_tmp_ref.npos(:,3)));
dataname_ref = [dirname_xy,'seg', filesep,name_ref,'_err.mat'];
data = load(dataname_ref);

% loads the data reference for the min merge of z phase, sets tha name and
% nameInfo, and the fluorescence field from the image to be merged.
if mod(i-1,skip)
    data.phase = phase;
    data.basename = name;
    nameInfo_tmp = nameInfo;
    for k = 2:num_c
        % load fluor image for each channel X and put it in data.fluorX
        nameInfo_tmp.npos(1,1) = nt(i);
        nameInfo_tmp.npos(2,1) = nc(k);
        nameInfo_tmp.npos(4,1) = 1;
        name = MakeFileName( nameInfo_tmp );
        fluorImage = imread( [dirname_xy,'fluor',num2str(nc(k)-1),filesep,name]);
        data.(['fluor',num2str(nc(k)-1)]) = fluorImage;
    end    
end

save(dataname2,'-STRUCT','data');

end
