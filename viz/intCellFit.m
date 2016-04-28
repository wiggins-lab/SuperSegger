function y = intCellFit( x, x1, x2, h )
% intCellFit : function used to fit to the shape of the cell.
%
% INPUT :
%   x : value to be fit
%   x1 : 
%   x2 : 
%   x3 : height or radius to be fit to
% OUTPUT :
%   y : fitted output
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


y = 0*x;

y(and(x >= (h+x1), x <= (-h+x2))) = 2*h;
ind = and(x >= x1, x < (h+x1) );

y(ind) = 2*h*sqrt(1-((x(ind)-x1-h)/h).^2);

ind = and(x <= x2, x > (-h+x2));
y(ind) = 2*h*sqrt(1-((x(ind)-x2+h)/h).^2);


end