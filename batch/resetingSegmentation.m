function resetingSegmentation(dirname)
% resetingSegmentation : deletes the stamp files to redo segmentation
% at the points specified by set flags in the function.
% If you want to re-run the whole thing just set the clean_flag in 
% BatchSuperSegger to 1. If you want to re-run specific function 
% set from the following the wanted flags to 1:
% removeOptiStrip 
% removeOptiLink
% removeOptiErRes1 
% removeOptiSetEr 
% removeOptiSkipMerge 
% removeOptiLink 
% removeOptiCellMaker
% removeOptiFluor 
% removeOptiMakeCell 
% removeOptiFindFoci 
% removeOptiClist
% removeOptiCellFiles
% You may need to set all the flags to 1 following a flag for the results
% to propagate to the cell files. 
%
% INPUT : 
%       dirname : directory with xy folder
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

dirname = fixDir(dirname);
xydirs = dir([dirname,'xy*']);

% set the flags of parts of supersegger you would like
% these are in order
removeOptiStrip = 0;
removeOptiLink = 0;
removeOptiErRes1 = 0;
removeOptiSetEr = 0;
removeOptiErRes2 = 0;
removeOptiSkipMerge = 0;
removeOptiCellMaker = 0;
removeOptiFluor = 0;
removeOptiMakeCell = 0;
removeOptiFindFoci = 0;
removeOptiClist = 0;
removeOptiCellFiles = 0;

for i = 1 : numel(xydirs)
    
    curXyDir = xydirs(i).name;
    dirname_seg = [dirname,curXyDir,filesep,'seg',filesep];
    intDeleteFile (removeOptiStrip, [dirname_seg,'.trackOptiStripSmall.mat']);
    intDeleteFile (removeOptiLink, [dirname_seg,'.trackOptiLink.mat']);
    intDeleteFile (removeOptiErRes1, [dirname_seg,'.trackOptiErRes1.mat']);
    intDeleteFile (removeOptiSetEr, [dirname_seg,'.trackOptiSetEr.mat']);
    intDeleteFile (removeOptiErRes2, [dirname_seg,'.trackOptiErRes2.mat']);
    intDeleteFile (removeOptiSkipMerge, [dirname_seg,'.trackOptiSkipMerge.mat']);
    intDeleteFile (removeOptiCellMaker, [dirname_seg,'.trackOptiCellMarker.mat']);
    intDeleteFile (removeOptiFluor, [dirname_seg,'.trackOptiFluor.mat']);
    intDeleteFile (removeOptiMakeCell, [dirname_seg,'.trackOptiMakeCell.mat']);
    intDeleteFile (removeOptiFindFoci, [dirname_seg,'.trackOptiFindFociCyto.mat']);
    intDeleteFile (removeOptiClist, [dirname_seg,'.trackOptiClist.mat']);
    intDeleteFile (removeOptiCellFiles, [dirname_seg,'.trackOptiCellFiles.mat']);
    
end

    function intDeleteFile (flag, filename)
        if flag && exist(filename,'file')
            delete(filename);
        end
    end
end
