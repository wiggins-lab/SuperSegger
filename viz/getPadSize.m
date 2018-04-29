function padStr = getPadSize( dirname, handles )
% getPadSize : returns how many numbers there are in each cell .mat file.
%
%   INPUT :
%       dirname : directory name
%       handles : used to display the message in the gui. empty for non gui
%       version.
%   OUTPUT : 
%       padStr : String of digits in the cell.mat files eg. '%07d'
% 
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins, Stella Stylianidou, Connor Brennan.
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

contents = dir([dirname,'*ell*.mat']);
if numel(contents) == 0
    if isempty(handles)
        disp('No cell files' );
    else
        handles.message.String = 'No cell files';
    end
    padStr = [];
else
    num_num = sum(ismember(contents(1).name,'1234567890'));
    padStr = ['%0',num2str(num_num),'d'];
end