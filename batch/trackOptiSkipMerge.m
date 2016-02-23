function trackOptiSkipMerge(dirname_xy,skip,CONST,header)
% trackOptiSkipMerge : adds skipped frames back into a time series.
% It makes the _err.mat files with the fluor images corresponding 
% to the current time step. Frame skip is useful for reducing errors 
% which you have a high frame rate.
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


file_filter = '*.tif';
if dirname_xy(end) ~= filesep
    dirname_xy = [dirname_xy, filesep];
end


%%
% Reset n values incase directories have already been made.



% setup nxy values
% contents = dir([dirname,'xy*']);

% reset values for nc
contents = dir([dirname_xy,'fluor*']);
num_dir_tmp = numel(contents);
nc = [1];
num_c = 1;

for i = 1:num_dir_tmp
    if (contents(i).isdir) && (numel(contents(i).name) > numel('fluor'))
        num_c = num_c+1;
        nc = [nc, str2num(contents(i).name(numel('fluor')+1:end))+1];
    end
end
%nc

%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Process data....
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% reset nz values
contents=dir([dirname_xy,'phase',filesep,file_filter]);
num_im = numel(contents);

nz = [];
nt = [];

for i = 1:num_im;
    nameInfo = ReadFileName( contents(i).name );
    
    nt = [nt, nameInfo.npos(1,1)];
    nz = [nz, nameInfo.npos(4,1)];
end


nt = sort(unique(nt));
nz = sort(unique(nz));

num_t = numel(nt);
num_z = numel(nz);

if  nz(1)==-1
    nz = 1;
end

if ~exist([dirname_xy,'seg_full'],'dir')
    mkdir( [dirname_xy,'seg_full'] );
end



if CONST.show_status
    h = waitbar( 0, ['Merging Skipped frames xy: 0/',num2str(num_t)] );
else
    h=[];
end

%parfor i=1:num_t;
for i=1:num_t;
    intSkipPar(i,dirname_xy,nameInfo,nt,nc,nz,skip,num_c,num_z);
    if CONST.show_status
        try
        waitbar( i/num_t,h,...
            ['Merging Skipped frames t: ',num2str(i),'/',num2str(num_t)]);
        end
    else
        disp( [header, 'skipMerge: No status bar. Frame ',num2str(i), ...
            ' of ', num2str(num_t),'.']);
    end
    
end
if CONST.show_status
    close(h);
end
end


function intSkipPar(i,dirname_xy,nameInfo,nt,nc,nz,skip,num_c,num_z)

data = [];
% make the segment file name and check if it already exists
nameInfo_tmp               = nameInfo;
nameInfo_tmp.npos([2,4],:) = 0;
nameInfo_tmp.npos(1,1)     = nt(i);
name                       = MakeFileName( nameInfo_tmp );
nameInfo_tmp               = ReadFileName(name);
name                       = name( 1:max(nameInfo_tmp.npos(:,3)));



dataname  =[dirname_xy,'seg', filesep,name,'_err.mat'];
dataname2 =[dirname_xy,'seg_full', filesep,name,'_err.mat'];



nameInfo_tmp = nameInfo;
nameInfo_tmp.npos(1,1) = nt(i);
nameInfo_tmp.npos(4,1) = 1;
name = MakeFileName(nameInfo_tmp);

% do the min merge of z phase:
phase = imread( [dirname_xy,'phase',filesep,name] );
for k = 2:num_z
    nameInfo_tmp.npos(4,1) = nz(k);
    name  = MakeFileName(nameInfo_tmp);
    phase =  min( phase, double(imread( [dirname_xy,'phase',filesep,name] )));
end


%Make ref name to load;
i_ref                      = i-mod(i-1,skip);
%i_ref                      = i-mod(i-1,skip)-1;


nameInfo_tmp_ref               = nameInfo;
nameInfo_tmp_ref.npos([2,4],:) = 0;
nameInfo_tmp_ref.npos(1,1)     = i_ref;
name_ref                       = MakeFileName( nameInfo_tmp_ref );
nameInfo_tmp_ref               = ReadFileName(name_ref);
name_ref                       = name_ref( 1:max(nameInfo_tmp_ref.npos(:,3)));

dataname_ref  =[dirname_xy,'seg', filesep,name_ref,'_err.mat'];

data = load(dataname_ref);

if mod(i-1,skip)
    data.phase = phase;
    data.basename = name;
    
    nameInfo_tmp = nameInfo;
    for k = 2:num_c
        nameInfo_tmp.npos(1,1) = nt(i);
        nameInfo_tmp.npos(2,1) = nc(k);
        nameInfo_tmp.npos(4,1) = 1;
        name = MakeFileName( nameInfo_tmp );
        data = setfield( data, ['fluor',num2str(nc(k)-1)], imread( [dirname_xy,'fluor',num2str(nc(k)-1),filesep,name] ));
    end
    
end
save(dataname2,'-STRUCT','data');



end