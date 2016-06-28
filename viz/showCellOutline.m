function im = showCellOutline( data )
% showCellOutline : draws the outlines for the regions in the data file.
%
% INPUT :
%   data : data (seg.mat) file with permanent, good and bad segments
%
% Copyright (C) 2016 Wiggins Lab
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.

if isempty(data)
    return;
end

back = double(ag( data.phase ));
segs_good = data.segs.segs_good;
mask_bg   = data.mask_bg;
segs_3n   = data.segs.segs_3n;
cell_mask = (mask_bg .* ~segs_good .* ~segs_3n);
outline = imdilate( cell_mask, strel( 'square',3) );
outline = ag(outline-cell_mask);
im = uint8(cat(3,back + 1.00*double(outline),...
    back ,...
    back + 0.2*double(ag(~cell_mask)-outline) ));
imshow(im);
drawnow;

end