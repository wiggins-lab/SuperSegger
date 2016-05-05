function [ poleSign ] = getPoleSign( data )
% getPoleSign : returns the sign of the pole for a cell data structure
% or a data.CellA strcture.
% 
% INPUT :
%       data : region/cell (err/seg) file  with CellA structure.
% OUTPUT :
%       poleSign : 1 if aligned along e1, -1 if in opposite direction.
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


poleSign = 1;

if  isfield(data,'CellA') && isfield(data.CellA{1},'pole') ...
        && isfield(data.CellA{1}.pole,'op_ori')
    poleSign = data.CellA{1}.pole.op_ori;
elseif  isfield(data,'pole') && isfield(data.pole,'op_ori')
    poleSign = data.pole.op_ori;
end

end

