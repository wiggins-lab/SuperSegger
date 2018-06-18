function doDrawCellOutlinePAW( data, ids1, ids2)
% Description :
%
% Opens fig with outlines of cells drawn. The script currently allows
% you to input two sets of cell IDs to be colored in blue (ids1) and red
% (ids2). Currently any cells with IDs not listed in ids1 or ids2 will be
% outlined in yellow. This is all customizable. If you wish to
% change the colors, replace 'b' etc with the color of your choice. If you
% do not want cells whose IDs are missing from the ID lists to be outlined,
% remove code in 'else' block. If you wish to send in additional id lists,
% add ids3, etc to the line above, and ammend the if/else block.
%
% List of inputs:
%
% data: A loaded err.mat file for the image you want outlines drawn on
% channel: The channel to draw outline on (1-phase, 2-fluor1)
% ids1: IDs of cells you want outlined in one color (default: blue)
% ids2: IDs of cells you want outlined in a second color (default: red)
%
%
% Copyright (C) 2016 Wiggins Lab
% Written by Silas Boye Nissen, Connor Brennan, Stella Stylianidou.
% University of Washington, 2016. Modified in 2018 by S Mangiameli and
% P. Wiggins.
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

% Fill unset inputs
if ~exist('ids1','var') || isempty( ids1 )
    ids1 = [];
end

if ~exist('ids2','var') || isempty( ids2 )
    ids2 = [];
end







% Draw outlines

rl = data.regs.regs_label;
ids = data.regs.ID;
nc = max( rl(:) );

props = regionprops( rl, 'PixelList' );

% Sets color depending on cell ID
for ii = 1:nc
    
    id = ids(ii);
    
    draw_flag = true;
    if ismember(id,ids1)
        cc = 'w';
    elseif ismember(id, ids2)
        cc = 'y';
    else
        cc = 'r';
        draw_flag = false;
    end
    
    if draw_flag
        % Mask for current region
        tmp = rl;
        tmp(tmp ~= ii) = 0;
        
        % Increase size of mask by 1 px and find boundary
        se = strel('disk',1);
        tmp2 = logical(imdilate(tmp,se));
        [y,x] = find(tmp2 == 1);
        k = boundary(x,y,1);
        
        
        hold on;
        skip = 1;
        kk = k([1:skip:end]);
        kk = kk([end-3:end,1:end,1:4]);
        
        n = 1:numel(kk);
        nn = 5:1:(numel(kk)-1);
        
        % Interprets from pixel outline to smooth drawn outline
        % xx = interp1( n, x(kk), nn,'spline' );
        % yy = interp1( n, y(kk), nn,'spline' );
        
        p = 0.1; %smaller value of p gives more smoothing
        xx = fnval(csaps( n, x(kk),p), nn);
        yy = fnval(csaps( n, y(kk),p), nn);
        
        
        % Plots outline on phase image
        plot( xx, yy, 'LineStyle','-','Color',cc,'LineWidth', .5 );
    end
    
end

end