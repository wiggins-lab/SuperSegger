function cm = hotcoldinv( numC )
% holdcoldinv : inverts hot to cold in colormap.
%
% INPUT : 
%   numC : number of colors
% OUTPUT : 
%   cm : colormap
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

dd = ceil((numC-1)/2);
cc = ((1:numC)-dd-1)'/dd;
cm = [abs(1+cc).*(cc<=0)+(cc>0),(1-cc).*(cc>0)+(cc<=0),1-abs(cc)];

end