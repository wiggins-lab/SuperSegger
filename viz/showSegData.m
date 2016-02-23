function showSegData( data, im_flag )
% showSegData draws the outlines for a region
%
% INPUT :
%   data : data (region/cell) file
%   im_flag : value from 1 to 3 for different plot styles
%
% Copyright (C) 2016 Wiggins Lab
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.

phase = data.segs.phaseMagic;
segs_3n = data.segs.segs_3n;
segs_good = data.segs.segs_good;
segs_bad = data.segs.segs_bad;
mask_bg = data.mask_bg;

figure(1)
if ~exist('im_flag')
    im_flag = 1;
end

backer = autogain(phase);
cell_mask = (mask_bg .* ~segs_good .* ~segs_3n);

if im_flag == 1;
    imshow( cat(3,...
        backer+0.3*autogain(segs_good), ...
        backer+0.3*autogain(segs_3n  ), ...
        backer+0.3*autogain(segs_bad )),[], 'InitialMagnification', 'fit');
    
elseif im_flag == 2;
    imshow( cat(3,autogain(cell_mask)*.3+backer,backer,backer) );
    
elseif im_flag == 3;
    imshow( cat(3,backer,backer,backer) );
    
else
    backer = autogain(data.phase);
    imshow( cat(3,backer,backer,backer) );
    
end
end
