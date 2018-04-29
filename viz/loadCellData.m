function [data_cell,cell_name] = loadCellData(num, dirname_cell, handles)
% loadCellData : used to load a cell file given it's number
%
% INPUT : 
%       num : number of cell
%       dirname_cell : directory with cell files
%       handles : used for the gui version
% OUTPUT : 
%       data_cell : loaded cell file
%       cell_name : name of file loaded
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou, Paul Wiggins.
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

data_cell = [];
cell_name = [];

padStr = getPadSize(dirname_cell, handles);

if ~isempty( padStr )
    data_cell = [];
    filename_cell_C = [dirname_cell,'Cell',num2str(num,padStr),'.mat'];
    filename_cell_c = [dirname_cell,'cell',num2str(num,padStr),'.mat'];
else
    return;
end
if exist(filename_cell_C, 'file' )
    filename_cell = filename_cell_C;
    cell_name = ['Cell',num2str(num,padStr),'.mat'];
elseif exist(filename_cell_c, 'file' )
    filename_cell = filename_cell_c;
    cell_name = ['cell',num2str(num,padStr),'.mat'];
else
    if isempty(handles)
        disp(['Files: ',filename_cell_C,' and ',filename_cell_c,' do not exist.']);
    else
        handles.message.String = ['Files: ',filename_cell_C,' and ',filename_cell_c,' do not exist.'];
    end
    return;
end
try
    data_cell = load( filename_cell );
catch
    if isempty(handles)
        disp(['Error loading: ', filename_cell]);
    else
        handles.message.String = ['Error loading: ', filename_cell];
    end
end