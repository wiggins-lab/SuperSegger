function [ v ] = col( v )
% row :  makes v into a col vector.
% INPUT : 
%   v: array or row vector.
% OUTPUT : 
%   v: vector converted to row vector.
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

ss = size(v);

if ~any( ss==1 )
    v = v(:);
elseif ss(1) == 1
    v = v';
end

end


