function name = MakeFileName( nameInfo )
% MakeFileName : converts from nameInfo structure to the image filename.
%
% INPUT : 
%       nameInfo : contains information about where numbers are found
% after strings in strD, for more info look at ReadFileName
%           npos: [4x4 double]
%           strD: {'t'  'c'  'xy'  'z'}
%           basename: before first found strD, eg. 'tsyfp-p-'
%           suffix: after last found number of strD, eg. '.tif'
% OUTPUT : 
%       name : string of format *t*c*xy*z*
%
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins & Stella Stylianidou.
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


npos = nameInfo.npos;
strD = nameInfo.strD;
basename = nameInfo.basename;
suffix = nameInfo.suffix;
numD = numel(strD);
[tmp,ord] = sort(npos(:,2));
npos_sort = npos( ord, :);
strD_sort = strD(ord);

name = basename;
    for i = 1:numD        
        if npos_sort(i,2)
            str_tmp = ['%0',num2str(npos_sort(i,4)),'d'];
            name = [name, strD_sort{i}, sprintf( str_tmp, npos_sort(i,1))];            
        end
    end    
    name = [name,suffix];
end

