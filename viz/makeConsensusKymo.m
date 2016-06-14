function [ kymo,kymoMask ] = makeConsensusKymo(...
    imCellS, maskCellS, disp_flag )
%  intMakeConsensusKymo : creates a consensus kymograph
%  To obtain imCellS and maskCellS you can call
%  [dataImArray] = makeConsensusArray( cellDir, CONST, skip, mag, clist )
% and then use  dataImArray.imCellNorm and dataImArray.maskCell
%
% INPUT :
%       imCellS : a cell array of images of towers of cells (need to have the
%       same dimensions)
%       maskCellS : the masks of each tower
%       disp_flag : 1 to display the image
%
% OUTPUT:
%      kymo : Consensus Kymograph
%      kymoMask : Consensus Kymograph Cell mask
%      kymoMax : maximum value kymograph
%      kymoMaskMax : mask of maximum value kymograph
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou, Paul Wiggins.
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



T0 = numel( imCellS );
mag = 4;
kymo = [];
kymoMask = [];

if T0 > 0
    % initialize
    ss    = size( imCellS{T0} );
    ssMax = size( imresize(imCellS{T0}, 1/mag) );
    kymo    = zeros( [ss(2), T0] );
    kymoMax = zeros( [ssMax(2), T0] );
    kymoMask    = kymo;
    kymoMaskMax = kymoMax;
    midpoint = ss(2)/2;
    for ii = 1:T0
        maskCellS{ii}( isnan( maskCellS{ii} ) ) = 0;
        imCellS{ii}( isnan( imCellS{ii} ) )     = 0;
        tmpKymo =  sum(maskCellS{ii}.*imCellS{ii},1);
        imageSize = size(tmpKymo,2);
        md_temp = round(imageSize/2);
        start_ind = midpoint-md_temp+1;
        end_ind =  imageSize + start_ind-1;
        kymo(start_ind:end_ind,ii)= (tmpKymo);
        kymoMask(start_ind:end_ind,ii) = (sum(maskCellS{ii},1));
        
    end
    
    if disp_flag
        figure(2);
        clf;
        ss = size( kymo );
        tt = (0:(ss(2)-1))/(ss(2)-1);
        xx = (0:(ss(1)-1))/(ss(1)-1);
        imagesc( tt,xx -.5, colorize(kymo,kymoMask,[],[0.33,0.33,0.33]) );
        set(gca, 'YDir', 'normal' );
        title ('Consensus Kymograph');
        xlabel( 'Time (Cell Cycle)');
        ylabel( 'Relative Long Axis Position (L_{endCellCycle}))');
    end
    
end

end