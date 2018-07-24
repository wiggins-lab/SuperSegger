function showSegData( data, im_flag, gui_fig )
% showSegData : draws the outlines for the regions in the data file.
%
% INPUT :
%   data : data (region/cell) file
%   im_flag : value from 1 to 3 for different plot styles
%
% Copyright (C) 2016 Wiggins Lab
% Written by Paul Wiggins, Stella Stylianidou.
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
% along with SuperSegger.  If not, see <http://www.gnu.org/licenses/>.


phase = data.phase;
segs_3n = data.segs.segs_3n;
segs_good = data.segs.segs_good;
segs_bad = data.segs.segs_bad;
mask_bg = data.mask_bg;
ss = size(mask_bg);


if ~exist('im_flag','var')
    im_flag = 1;
end

backer = ag(phase);
cell_mask = (mask_bg .* ~segs_good .* ~segs_3n);

if  ~exist('gui_fig','var') || isempty(gui_fig)
    figure(1);
    tmp = [1 1 1 1];
else
    axes(gui_fig); % new, ie. used in the GUI version
    tmp = axis;
end

if im_flag == 1 % displays good, 3n and bad segments
    phaseBackag = (ag((~data.mask_cell)));
     imshow( cat(3, 0.2*(phaseBackag) + 0.3*ag(segs_3n) + ag(segs_good), ...
         0.2*(phaseBackag) + 0.3*ag(segs_3n)  , ...
         0.2*(phaseBackag) + 0.3*ag(segs_3n) + ag(segs_bad) ), ...
         'InitialMagnification', 'fit',...
         'Parent', gui_fig);
    
axes(  gui_fig );   

if all( tmp == [0 1 0 1] );
axis( [1,ss(2),1,ss(1)] );
else
    axis(tmp )
end
    
    
   % 'hi'
elseif im_flag == 2 % displays cell mask
    cc = bwconncomp(cell_mask, 4);
    labeled = labelmatrix(cc);
    RGB_label = label2rgb(labeled,'lines',[.7 .7 .7]);%,'shuffle');
    imshow(RGB_label);
    
elseif im_flag == 3 % displays phase
    imshow( cat(3,backer,backer,backer) );
    
end

end
