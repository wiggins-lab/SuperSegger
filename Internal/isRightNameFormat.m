function [rightNames] = isRightNameFormat(dirname)
% isRightNameFormat : returns true if .tif images in the directory have the
% right naming convention.
% INPUT : 
%       dirname : directory name with images
% OUTPUT :
%       rightNames : true if they have the right naming convention
%
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


contents = dir([dirname,filesep,'*.tif*']);
filenames = {contents.name}';

nameWithXy=regexpi(filenames,'t\d+xy\d+c\d+.tif+','once');
nameWithoutXy=regexpi(filenames,'t\d+c\d+.tif+','once');
nameWithoutt=regexpi(filenames,'xy\d+c\d+.tif+','once');

numWithXy =  sum(~cellfun('isempty',nameWithXy));
numWithoutXY = sum(~cellfun('isempty',nameWithoutXy));
numWithoutt = sum(~cellfun('isempty',nameWithoutt));

if numWithXy>0 ||numWithoutXY>0 || numWithoutt>0
    rightNames = true;
else
    rightNames = false;
end


%% fix the padding if required
contents = dir([dirname,filesep,'*.tif*']);

num_im = numel(contents);
pad = [];

for i = 1:num_im;
    nameInfo = ReadFileName( contents(i).name );
    pad = [pad, nameInfo.npos(1,4)];
end

if 1 ~= numel( unique( pad ) )
   
    maxpad = max( pad );
    
    ind = find( pad < maxpad );
    
    for i = ind
        nameInfo  = ReadFileName( contents(i).name );
        
        nameInfo.npos(1,4) = maxpad;
        
        movefile( [dirname,filesep,contents(i).name], ...
            [dirname,filesep,MakeFileName(nameInfo)] );        
    end
end




end

