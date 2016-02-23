function name = MakeFileName( nameInfo )
% MakeFileName converts from nameInfo to original file name
%
%   INPUT : 
%       nameInfo : contains information about where numbers are found
% after strings in strD, for more info look at ReadFileName
%           npos: [4x4 double]
%           strD: {'t'  'c'  'xy'  'z'}
%           basename: before first found strD, eg. 'tsyfp-p-'
%           suffix: after last found number of strD, eg. '.tif'
%   OUTPUT : 
%       name : string of format *t*c*xy*z*
%
% Copyright (C) 2016 Wiggins Lab 
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.


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

