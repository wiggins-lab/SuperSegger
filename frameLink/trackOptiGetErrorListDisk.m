function error_list  = trackOptiGetErrorListDisk(dirname,file_filter)
% trackOptiGetErrorListDisk : creates a list of errors
%
% INPUT :
%       dirname    : seg folder eg. maindirectory/xy1/seg
%       file_filter : regular expression of files default is '*err.mat';
% OUTPUT :
%       error_list : list of errors [fromFrame, toFrame, 1 if error]
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins.
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


if ~exist('file_filter') || isempty(file_filter);
    file_filter = '*err.mat';
end

if(nargin<1 || isempty(dirname))
    dirname=uigetdir()
end
dirname = fixDir(dirname);

contents=dir([dirname, file_filter]);
num_im = length(contents);
error_list = [];

for i = 1:num_im;
    data_c = loaderInternal([dirname,contents(i  ).name]);    
    for ii = 1: data_c.num_regs
        if data_c.errorr(ii)            
            list = data_c.mr{ii};
            try
                skip = data_c.errorf(ii) || data_c.errorr(ii);              
            catch
                keyboard
            end
            error_list = [error_list; [i, ii, skip]];
            
        end
    end
end
error_list = error_list';
end

function data = loaderInternal( filename )
data = load( filename );
end