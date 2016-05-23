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


phase = data.segs.phaseMagic;
segs_3n = data.segs.segs_3n;
segs_good = data.segs.segs_good;
segs_bad = data.segs.segs_bad;
mask_bg = data.mask_bg;

if ~exist('im_flag')
    im_flag = 1;
end

backer = ag(phase);
cell_mask = (mask_bg .* ~segs_good .* ~segs_3n);

axes(gui_fig);
if im_flag == 1 % displays good, 3n and bad segments
      imshow( cat(3,...
        0.4*backer+0.6*ag(segs_good+segs_3n), ...
          0.4*backer+0.4*ag(segs_good), ...
          0.4*backer+0.6*ag(segs_bad )),[], 'InitialMagnification', 'fit');
   
elseif im_flag == 2 % displays cell mask on top of phase
    imshow( cat(3,ag(cell_mask)*.3+backer,backer,backer) );
    
elseif im_flag == 3 % displays phase
    imshow( cat(3,backer,backer,backer) );
end

end
