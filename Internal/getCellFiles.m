function rightCellNames = getCellFiles (cellDir,CONST)

if ~isfield( CONST, 'view') || CONST.view.showFullCellCycleOnly
    contents = dir([cellDir,filesep,'Cell*.mat']);
else
    contents = dir([cellDir,filesep,'*ell*.mat']);
end

cellNames = {contents.name}';
rightCells=regexpi(cellNames,'[cC]ell\d+.mat','once');
rightCellNames = cellNames(cell2mat(rightCells));

end