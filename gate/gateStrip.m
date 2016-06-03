function [clist] = gateStrip( clist, ind )
% gateStrip : removes the gate field from clist, or the gate for index ind.
%
% INPUT :
%       clist : table of cells with time-independent variables
%       ind : index to be removed from gate, if none given strips the whole gate
%
% OUTPUT :
%       clist : updated clist with stripped gate
%
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

if ~exist('ind','var') || isempty(ind) || isempty(clist.gate)
    clist.gate = [];
else      
   loc = find( cellfun(@(x)isequal(x,ind),{clist.gate.ind}) ); 
   if isempty (loc)
%       disp (['index : ', num2str(ind), ' not found in the gate']);
   else
%        disp (['removing : ', num2str(ind), ' from gate']);
        clist.gate(loc) = [];
   end
end
end