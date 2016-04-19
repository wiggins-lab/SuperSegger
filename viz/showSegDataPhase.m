function showSegDataPhase( data )
% showSegDataPhase draws the outlines for the regions in the data file.
%
% INPUT :
%   data : data (seg.mat) file with permanent, good and bad segments
%
% Copyright (C) 2016 Wiggins Lab
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.


try
    back = double(0.7*ag( data.phase ));
    segs_good = data.segs.segs_good;
    segs_bad  = data.segs.segs_bad;
    mask_bg   = data.mask_bg;
    segs_3n   = data.segs.segs_3n;
    cell_mask = (mask_bg .* ~segs_good .* ~segs_3n);
    outline = imdilate( cell_mask, strel( 'square',3) );
    outline = ag(outline-cell_mask);
    imshow(uint8(cat(3,back + 1.00*double(outline),...
    back + 0.4*double(ag(segs_good)) + 0.1*double(ag(segs_bad)),...
    back + 0.6*double(ag(segs_bad)) + 0.2*double(ag(~cell_mask)-outline) )));
    drawnow; 
end
end
