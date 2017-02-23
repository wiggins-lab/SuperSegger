function cleanSuperSegger (dirname_xy, startEnd, skip)
% cleanSuperSegger : used to clean up the flag files created during
% superSegger.
%
% INPUT : 
%   dirname_xy : xy directory 
%   startEnd : superSegger step to start on adn step to end on.
%   skip : number of frames to skip.
%
% Copyright (C) 2016 Wiggins Lab
% Written by Paul Wiggins & Stella Stylianidou.
% University of Washington, 2016
% This file is part of SuperSegger.

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


dirname_xy = fixDir(dirname_xy);
dirname_full  = [dirname_xy,'seg_full',filesep];
dirname_seg = [dirname_xy,'seg',filesep];
dirname_cell = [dirname_xy,'cell',filesep];
warning('off','MATLAB:DELETE:Permission')

if startEnd(1) <= 2 && startEnd(2) >=2     
    stamp_name = [dirname_seg,'.doSegFull'];
    if exist(stamp_name,'file')
        delete(stamp_name)
    end
    delete([dirname_seg,'*seg.mat*']);
end


if startEnd(1) <= 3 && startEnd(2) >=3     
    stamp_name = [dirname_seg,'.trackOptiStripSmall-Step1.mat'];
    delete(stamp_name);
end

if startEnd(1) <= 4 && startEnd(2) >=4     
    stamp_name = [dirname_seg,'.trackOptiLinkCell-Step2.mat'];
    delete([dirname_seg,'*err.mat']);
    delete(stamp_name);
    if skip>1
        stamp_name =  [dirname_seg,'.trackOptiSkipMerge-Step2merge.mat'];
        delete(stamp_name);
        stamp_name = [dirname_seg,'.trackOptiLinkCell-Step2merge.mat'];
        delete(stamp_name);
    end
end


if startEnd(1) <= 5 && startEnd(2) >=5    
    stamp_name = [dirname_seg,'.trackOptiCellMarker-Step3.mat'];
    delete(stamp_name);
end

if startEnd(1) <= 6 && startEnd(2) >=6    
    stamp_name = [dirname_seg,'.trackOptiFluor-Step4.mat'];
    delete(stamp_name);
end


if startEnd(1) <= 7 && startEnd(2) >=7    
    stamp_name = [dirname_seg,'.trackOptiMakeCell-Step5.mat'];
    delete(stamp_name);
end


if startEnd(1) <= 8 && startEnd(2) >=8    
    stamp_name = [dirname_seg,'.trackOptiFindFoci-Step6.mat'];
    delete(stamp_name);
end


if startEnd(1) <= 9 && startEnd(2) >=9    
    stamp_name = [dirname_seg,'.trackOptiClist-Step7.mat'];
    delete(stamp_name);
    delete ([dirname_xy,'clist.mat']); % clist
end


if startEnd(1) <= 10 && startEnd(2) >=10    
    stamp_name = [dirname_seg,'.trackOptiCellFiles-Step8.mat'];
    delete(stamp_name);
    delete ([dirname_cell,'*.mat']); % cell files
end

warning('on','MATLAB:DELETE:Permission')

end