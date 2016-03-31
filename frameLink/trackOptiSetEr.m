function trackOptiSetEr(dirname,CONST, header)
% trackOptiSetEr: Since errors are corrected twice, this resets all the error flags 
% such that errors are not corrected twice.
%
% INPUT :
%       dirname : seg folder eg. maindirectory/xy1/seg
%       CONST : Constants file
%       header : information string.
%
% Copyright (C) 2016 Wiggins Lab 
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

if ~exist('header')
    header = [];
end

if ~exist('disp_flag') || isempty( disp_flag );
    disp_flag = 0;
end

if(nargin<1 || isempty(dirname)) 
    dirname=uigetdir()
end
dirname = fixDir(dirname);


if ~exist('err_flag') || isempty(err_flag)
    err_flag = 0;
end


contents=dir([dirname '*_err.mat']);
num_im = length(contents);
num_loop = num_im;


if CONST.parallel.show_status
    h = waitbar( 0, 'Reset Errors');
else
    h = [];
end
%parfor i = 1:num_loop
for i = 1:num_loop
    
    trackOptiIntSetEr( [dirname,contents(i  ).name], CONST, i );
    if CONST.parallel.show_status
        waitbar(i/num_loop,h,['Reset Errors--Frame: ',num2str(i),'/',num2str(num_im)]);
    else
        disp( [header, 'SetEr: No status bar. Frame ',num2str(i), ...
            ' of ', num2str(num_im),'.']);
    end
end
if CONST.parallel.show_status
    close(h);
end

end


function data = loaderInternal( filename );
data = load( filename );
end


