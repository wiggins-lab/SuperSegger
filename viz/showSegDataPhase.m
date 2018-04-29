function showSegDataPhase( data, viewport )
% showSegDataPhase : draws the outlines for the regions in the data file.
% Displays in red the fixed segments, in orange the good/true segments
% and in blue the bad/false segments.
%
% INPUT :
%   data : data (seg.mat) file with permanent, good and bad segments
%   viewport : used for viewing in the gui
%
% Copyright (C) 2016 Wiggins Lab
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.

if isempty(data)
    return;
end

if exist('viewport','var') && ~isempty(viewport)
    axes(viewport);
end

back = double(ag( data.phase ));
segs_good = data.segs.segs_good;
segs_bad  = data.segs.segs_bad;
mask_bg   = data.mask_bg;
segs_3n   = data.segs.segs_3n;
cell_mask = (mask_bg .* ~segs_good .* ~segs_3n);
outline = imdilate( cell_mask, strel( 'square',3) );
outline = ag(outline-cell_mask);
image(uint8(cat(3,back + 1.00*double(outline),...
    back + 0.4*double(ag(segs_good)) + 0.3*double(ag(segs_bad)),...
    back + 0.7*double(ag(segs_bad)) + 0.2*double(ag(~cell_mask)-outline) )));
drawnow;
axis image;
end
