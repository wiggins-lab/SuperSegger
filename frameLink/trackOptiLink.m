function trackOptiLink(dirname,disp_flag,iii,err_flag,CONST,header)
% trackOptiLink : computes the links (or overlaps) between subsequent frames
% and sets an error flag if the mapping isn't 1-to-1.
%
% INPUT :
%       dirname    : seg folder eg. maindirectory/xy1/seg
%       disp_flag  : a flag set for displaying the results
%       iii        : is the list of frames to relink.
%       err_flag   : is set when this function is called from trackOptiErRes.
%       CONST      : SuperSeggerOpti set parameters
%       header     : displayed string
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

if ~exist('disp_flag') || isempty( disp_flag );
    disp_flag = 0;
end

if ~exist('header')
    header = [];
end


if(nargin<1 || isempty(dirname))
    dirname=uigetdir()
end

dirname = fixDir(dirname);

if ~exist('err_flag') || isempty(err_flag)
    err_flag = 0;
end


if err_flag
    contents=dir([dirname '*_err.mat']);
else
    contents=dir([dirname '*_seg.mat']);
end

num_im = length(contents);

if ~exist('iii') || isempty(iii)
    iii = 1:num_im;
end

num_loop = numel(iii);

if CONST.show_status
    h = waitbar( 0, 'Linking Cells');
else
    h = [];
end

num_iii = numel(iii);

parfor(i = 1:num_iii, CONST.parallel_pool_num)
%for i = 1:num_iii
    intParFun( iii(i), num_im, dirname, contents, err_flag, CONST );
    if CONST.show_status
        waitbar(i/num_iii,h,['Linking Cells--Frame: ',num2str(iii(i)),'/',num2str(num_im)]);
    else
        disp( [header, 'Link: No status bar. Frame ',num2str(i), ...
            ' of ', num2str(num_im),'.']);
    end
end

if CONST.show_status
    close(h);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% write over old files                                                    %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

contents=dir([dirname '*.mat_']);
if ispc
    move_cmd = '!move ';
else
    move_cmd = '!mv ';
end
num_ch = numel(contents);
for i = 1:num_ch
    
    tmp = [dirname,contents(i).name];
    tot_move_cmd = [move_cmd,'"',tmp,'" "',tmp(1:end-1),'"'];
    eval(tot_move_cmd);
end

end


function intParFun( i, num_im, dirname, contents, err_flag, CONST )
if (i ==1) && (1 == num_im)
    data_r = [];
    data_c = prepData(loaderInternal([dirname,contents(i  ).name]));
    data_f = [];
elseif i == 1;
    data_r = [];
    data_c = prepData(loaderInternal([dirname,contents(i  ).name]));
    data_f = prepData(loaderInternal([dirname,contents(i+1).name]));
elseif (i == num_im)
    data_r = prepData(loaderInternal([dirname,contents(i-1).name]));
    data_c = prepData(loaderInternal([dirname,contents(i  ).name]));
    data_f = [];
else
    data_r = prepData(loaderInternal([dirname,contents(i-1).name]));
    data_c = prepData(loaderInternal([dirname,contents(i  ).name]));
    data_f = prepData(loaderInternal([dirname,contents(i+1).name]));
end

% Calculate overlaps
data_c = trackOptiIntDiskNR( data_c, data_r, data_f, CONST );

if err_flag
    dataname=[dirname,contents(i).name(1:length(contents(i).name)-7),'err.mat_'];
else
    dataname=[dirname,contents(i).name(1:length(contents(i).name)-7),'trk.mat_'];
end
save(dataname,'-STRUCT','data_c');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% java garbage collection
heapTotalMemory = java.lang.Runtime.getRuntime.totalMemory;
heapFreeMemory = java.lang.Runtime.getRuntime.freeMemory;
if(heapFreeMemory < (heapTotalMemory*0.01))
    java.lang.Runtime.getRuntime.gc;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end


function data = prepData( data)
% prepData : extracts region information from data
data.regs.regs_label = bwlabel( data.mask_cell, 4 );
data.regs.props      = regionprops( data.regs.regs_label, {'Area', ...
    'Centroid', 'BoundingBox','Orientation', 'MajorAxisLength',...
    'MinorAxisLength'});
data.regs.num_regs   = max(data.regs.regs_label(:));

end


function data = loaderInternal( filename )
data = load( filename );
end


