function resetingSegmentation(dirname)
dirname = fixDir(dirname);
xydirs = dir([dirname,'xy*']);


removeOptiStrip = 0
removeOptiLink = 0
removeOptiErRes1 = 0
removeOptiSetEr =0
removeOptiSkipMerge = 0
removeOptiLink = 0
removeOptiCellMaker = 0
removeOptiFluor = 0
removeOptiMakeCell =1
removeOptiFindFoci =0
removeOptiClist=0
removeOptiCellFiles=0



for i = 1 : numel(xydirs)
    curXyDir = xydirs(i).name
    dirname_seg = [dirname,curXyDir,filesep,'seg',filesep]
    
    if removeOptiStrip
        delete([dirname_seg,'.trackOptiStripMig.mat']);
    end
    
    if removeOptiLink
%         fileName = 
%         if exist(fileName,')
        delete( [dirname_seg,'.trackOptiLink.mat']);
    end
    
    if removeOptiErRes1
        delete( [dirname_seg,'.trackOptiErRes1.mat']);
    end
    
    if removeOptiSetEr
        delete([dirname_seg,'.trackOptiSetEr.mat']);
    end
    
    if removeOptiSkipMerge
        delete( [dirname_seg,'.trackOptiSkipMerge.mat']);
    end
    
    if removeOptiLink
        delete( [dirname_seg,'.trackOptiLink.mat']);
    end
    
    if removeOptiCellMaker
        delete( [dirname_seg,'.trackOptiCellMarker.mat']);
    end
    
    if removeOptiFluor
        delete( [dirname_seg,'.trackOptiFluor.mat']);
    end
    
    if removeOptiMakeCell
        delete([dirname_seg,'.trackOptiMakeCell.mat']);
    end
    
    if removeOptiFindFoci
        delete( [dirname_seg,'.trackOptiFindFociCyto.mat']);
    end
    if removeOptiClist
        delete( [dirname_seg,'.trackOptiClist.mat']);
    end
    if removeOptiCellFiles
        delete( [dirname_seg,'.trackOptiCellFiles.mat']);
    end
    
    
end
    
end