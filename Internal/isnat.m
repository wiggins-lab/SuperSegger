function [naturalNum] = isnat( list )
% isnat : finds if numbers in an array are natural (ie positive and 
% non-zero integers)
%
% INPUT : 
%        list : array of numbers
% OUTPUT : 
%        naturalNumb : array of 1 and 0, with 1 where
%        natural numbers are found in the list
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


naturalNum = ~isnan( list );
naturalNum(naturalNum) = and((list(naturalNum)>0),...
    list(naturalNum)==floor(list(naturalNum)));


end

