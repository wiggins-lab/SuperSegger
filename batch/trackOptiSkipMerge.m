function trackOptiSkipMerge(dirname_xy,skip,CONST,header)
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
% Written by Stella Stylianidou & Paul Wiggins.
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

if ~exist('header','var')
    header = [];
end

if nargin < 2 || isempty( skip )
    skip = 1; % don't skip frames
end

file_filter = '*.tif';
dirname_xy = fixDir(dirname_xy);

% Reset n values in case directories have already been made.
contents = dir([dirname_xy,'fluor*']);
num_dir_tmp = numel(contents);
nc = 1;
num_c = 1;

% reset values for nc
for i = 1:num_dir_tmp
    if (contents(i).isdir) && (numel(contents(i).name) > numel('fluor'))
        num_c = num_c+1;
        nc = [nc, str2double(contents(i).name(numel('fluor')+1:end))+1];
    end
end

% Process data....

contents=dir([dirname_xy,'phase',filesep,file_filter]);
num_im = numel(contents);

nz = zeros(1, num_im);
nt = zeros(1, num_im);

% reset nz values
for i = 1:num_im;
    nameInfo = ReadFileName( contents(i).name );    
    nt(i) = nameInfo.npos(1,1);
    nz(i) = nameInfo.npos(4,1);
end

nt = sort(unique(nt));
nz = sort(unique(nz));
num_t = numel(nt);
num_z = numel(nz);

if nz(1)==-1
    nz = 1;
end

if ~exist([dirname_xy,'seg_full'],'dir')
    mkdir( [dirname_xy,'seg_full'] );
end

if CONST.parallel.show_status
    h = waitbar( 0, ['Merging Skipped frames xy: 0/',num2str(num_t)]);
    cleanup = onCleanup( @()( delete( h ) ) );
else
    h=[];
end

%parfor i=1:num_t;
for i=1:num_t;
    intSkipPar(i,dirname_xy,nameInfo,nt,nc,nz,skip,num_c,num_z);
    if CONST.parallel.show_status
        waitbar(i/num_t,h,...
            ['Merging Skipped frames t: ',num2str(i),'/',num2str(num_t)]);
    else
        disp( [header, 'skipMerge: No status bar. Frame ',num2str(i), ...
            ' of ', num2str(num_t),'.']);
    end
    
end
if CONST.parallel.show_status
    close(h);
end
end


function intSkipPar(i,dirname_xy,nameInfo,nt,nc,nz,skip,num_c,num_z)
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

dataname2 =[dirname_xy,'seg_full', filesep,name,'_seg.mat'];

nameInfo_tmp = nameInfo;
nameInfo_tmp.npos(1,1) = nt(i);
nameInfo_tmp.npos(4,1) = 1;
name = MakeFileName(nameInfo_tmp);


% do the min merge of z phase
phase = intImRead( [dirname_xy,'phase',filesep,name] );
for k = 2:num_z
    nameInfo_tmp.npos(4,1) = nz(k);
    name  = MakeFileName(nameInfo_tmp);
    phase =  min(phase, double(intImRead( [dirname_xy,'phase',filesep,name] )));
end

% Loads the reference _err file for the image already segmented
i_ref = nt(i)-mod(i-1,skip);
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
    
    imRange = nan( [2, num_c ] );
    imRange(:,1) = intRange( phase(:) );

    data.phase = phase;
    data.basename = name;
    nameInfo_tmp = nameInfo;
    for k = 2:num_c
        % load fluor image for each channel X and put it in data.fluorX
        nameInfo_tmp.npos(1,1) = nt(i);
        nameInfo_tmp.npos(2,1) = nc(k);
        nameInfo_tmp.npos(4,1) = 1;
        name = MakeFileName( nameInfo_tmp );
        fluorImage = intImRead( [dirname_xy,'fluor',num2str(nc(k)-1),filesep,name]);
        data.(['fluor',num2str(nc(k)-1)]) = fluorImage;
        
        imRange(:,k) = intRange( fluorImage(:) );
    end  
    
    data.imRange = imRange;

end


save(dataname2,'-STRUCT','data');

end
