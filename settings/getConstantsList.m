function [possibleConstants, resFlagList, filepath] = getConstantsList()
% getConstantsList : gets all constants files from the settings directory.
% 
% OUTPUT : 
%   possibleConstants.names : names of the constants files
%   possibleConstants.resFlags : res flags with string to load constants from loadConstants 
%   resFlagList : list of all res flags.
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Styliandou.
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


FulllocationOfFile = mfilename('fullpath');
fileSepPosition = find(FulllocationOfFile==filesep,1,'last');
filepath = FulllocationOfFile ( 1 :fileSepPosition-1);
filepath = [filepath,filesep];
possibleConstants = dir([filepath,'*.mat']);

resFlagList = {};

for i = 1 : numel (possibleConstants)
    cName = possibleConstants (i).name;
    possibleConstants(i).resFlag =cName (1:end-4);
    resFlagList{i} = possibleConstants(i).resFlag;
end

end

