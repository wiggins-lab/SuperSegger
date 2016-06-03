function resetingSegmentation(dirname, step)
% resetingSegmentation : deletes the stamp files to redo segmentation
% at the points specified by set flags in the function.
% If you want to re-run the whole thing just set the clean_flag in 
% BatchSuperSegger to 1. If you want to re-run specific function 
% set step here to the following numbers:
% 1 : trackOptiStripSmall  & all following
% 2 : trackOptiLinkCell  & all following
% 3 : trackOptiCellMarker  & all following
% 4 : trackOptiFluor & all following
% 5 : trackOptiMakeCell  & all following
% 6 : trackOptiFindFociCyto  & all following
% 7 : trackOptiClist  & all following
% 8 : trackOptiMakeCell & all following
%
% INPUT : 
%       dirname : directory with xy folder
%       step : 1 - 8 for step onwards you want to reset
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
% along with SuperSegger.  If not, see <http://www.gnu.org/licenses/<.


dirname = fixDir(dirname);
xydirs = dir([dirname,'xy*']);

if ~exist('step','var')
    error ('provide the step you want to reset');
    return;
end

% set the flags of parts of supersegger you would like
% these are in order

removeOptiStrip = 0;
removeOptiLink = 0;
removeOptiCellMarker = 0;
removeOptiFluor = 0;
removeOptiMakeCell = 0;
removeOptiFindFoci = 0;
removeOptiClist = 0;
removeOptiCellFiles = 0;

if step <= 1
removeOptiStrip = 1;
end

if step <= 2
removeOptiLink = 1;
end

if step <= 3
removeOptiCellMarker = 1;
end

if step <= 4
removeOptiFluor = 1;
end

if step <= 5
removeOptiMakeCell = 1;
end

if step <= 6
removeOptiFindFoci = 1;
end

if step <= 7
removeOptiClist = 1;
end

if step <= 8
removeOptiCellFiles = 1;
end


for i = 1 : numel(xydirs)
    curXyDir = xydirs(i).name;
    dirname_seg = [dirname,curXyDir,filesep,'seg',filesep];
    dirname_cell  = [dirname,curXyDir,filesep,'cell',filesep];
    intDeleteFile (removeOptiStrip, [dirname_seg,'.trackOptiStripSmall-Step1.mat']);
    intDeleteFile (removeOptiLink, [dirname_seg,'.trackOptiLinkCell-Step2.mat']);
    if removeOptiLink
        delete([dirname_seg,'*err.mat']);
    end
    intDeleteFile (removeOptiCellMarker, [dirname_seg,'.trackOptiCellMarker-Step3.mat']);
    intDeleteFile (removeOptiFluor, [dirname_seg,'.trackOptiFluor-Step4.mat']);
    intDeleteFile (removeOptiMakeCell, [dirname_seg,'.trackOptiMakeCell-Step5.mat']);
    intDeleteFile (removeOptiFindFoci, [dirname_seg,'.trackOptiFindFoci-Step6.mat']);
    intDeleteFile (removeOptiClist, [dirname_seg,'.trackOptiClist-Step7.mat']);
    intDeleteFile (removeOptiCellFiles, [dirname_seg,'.trackOptiMakeCell-Step8.mat']);
     if removeOptiCellFiles
        delete([dirname_cell,'*ell*.mat']);
    end

end

    function intDeleteFile (flag, filename)
        if flag && exist(filename,'file')
            delete(filename);
        end
    end
end
