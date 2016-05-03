function cellOutline( data, dots)
% showSegDataPhase draws the outlines for the regions in the data file.
%
% INPUT :
%   data : data (seg.mat) file with permanent, good and bad segments
%
% Copyright (C) 2016 Wiggins Lab
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.

cell_mask = data.mask_cell;
outline = imdilate( cell_mask, strel( 'square',3) );
outline = ag(outline-cell_mask);
backphase =  double(1*ag(data.phase));
backphase(logical(cell_mask)) = 0;
backphase(logical(outline)) = 0;
imshow(uint8(cat(3,2*backphase + double(ag(outline))...
    ,2*backphase + 0.3*double(ag(outline))...
    ,2*backphase +  0.2 * double(ag(~cell_mask)-outline))));

if dots 
% get centroids
hold on;
for i = 1 : data.regs.num_regs
    hold on;
    plot(data.regs.props(i).Centroid(1),data.regs.props(i).Centroid(2),'.', 'MarkerSize',20,'Color',[1,0.3,0]);
end
end

% cell_mask = data.mask_cell;
% back = double(1*ag(cell_mask));
% outline = imdilate( cell_mask, strel( 'square',3) );
% outline = ag(outline-cell_mask);
% 
% imshow(uint8(cat(3,back + 0.9*double(ag(outline))...
%     ,back,...
%     back+ 0.1*double(ag(~cell_mask)-outline))));


% plot dots on centroids
%for i = 1 : data.regs.nu

drawnow;


end
