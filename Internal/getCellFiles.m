function rightCellNames = getCellFiles (cellDir,CONST)
% getCellFiles : returns a cell array with the names of the cell files in cellDir
% If CONST.view.showFullCellCycleOnly is set to 1 it returns only the names of full cell cycle
% cells.
%
% INPUT :
%       cellDir : directory with cell files eg. xy1/cell
%       CONST : segmentation parameters.
% OUTPUT :
%       rightCellNames a cell array with the names of the cell files in cellDir
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

if ~exist('CONST','var') || isempty(CONST)
    CONST.view.showFullCellCycleOnly = 0;
end

if ~isfield( CONST, 'view') || CONST.view.showFullCellCycleOnly
    contents = dir([cellDir,filesep,'Cell*.mat']);
else
    contents = dir([cellDir,filesep,'*ell*.mat']);
end


cellNames = {contents.name}';
rightCells=regexpi(cellNames,'[cC]ell\d+.mat','once');
ids = find(cell2mat(rightCells));

rightCellNames = {cellNames{ids}};

if numel(rightCellNames) == 0
    error('No cell files found')
end

end