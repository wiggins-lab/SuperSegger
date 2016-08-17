function [ind] = grabClistIndex(clist, field_str, time)
% grabClistIndex : grabs the clist index for string
%
% INPUT :
%   clist : table of cells and variables with gate field
%   field_str : field
% OUTPUT :
%   ind : clist index
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou.
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
if ~exist('time','var') || isempty(time)
    time = 0;
end

if ~time
    def = lower(clist.def');
else
    def = lower(clist.def3D');
end

field_str = lower(field_str);
ind = find(~cellfun('isempty',strfind(def,field_str)));


end