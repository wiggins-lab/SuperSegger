function bw_filled = fillHolesAround(magicPhase,CONST, crop_box)
% fillHolesAround : creates an image of the regions that have halos.
% It blurs the image, then takes things above the cut off intensity, and
% fills the holes in the middle and edges.
% INPUT : 
%       magicPhase : phase image after magic contrast is applied
% OUTPUT : 
%       bw_filled : image with halo-regions filled.
%
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Stylianidou.
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



blurFilter = fspecial( 'gaussian',15, 1 );
phaseFilt = imfilter(magicPhase,blurFilter, 'replicate');

if ~isempty(crop_box)
crop_box = round(crop_box);
    phaseFilt(:,1:crop_box(2))   = 255;
    phaseFilt(:,crop_box(4):end) = 255;
    phaseFilt(1:crop_box(1),:)   = 255;
    phaseFilt(crop_box(3):end,:) = 255;
    
    phaseFilt(:,1:crop_box(2))   = 255;
    phaseFilt(:,crop_box(4):end) = 255;
    phaseFilt(1:crop_box(1),:)   = 255;
    phaseFilt(crop_box(3):end,:) = 255;
end

CUT_INT_LOW = CONST.superSeggerOpti.CUT_INT/1.5;
halos = (phaseFilt>CUT_INT_LOW);
halos_filled = imfill(halos,'holes');

bw_a = padarray(halos_filled,[1 1],1,'pre');
bw_a_filled = imfill(bw_a,'holes');
bw_a_filled = bw_a_filled(2:end,2:end);

bw_b = padarray(padarray(halos_filled,[1 0],1,'pre'),[0 1],1,'post');
bw_b_filled = imfill(bw_b,'holes');
bw_b_filled = bw_b_filled(2:end,1:end-1);

bw_c = padarray(halos_filled,[1 1],1,'post');
bw_c_filled = imfill(bw_c,'holes');
bw_c_filled = bw_c_filled(1:end-1,1:end-1);

bw_d = padarray(padarray(halos_filled,[1 0],1,'post'),[0 1],1,'pre');
bw_d_filled = imfill(bw_d,'holes');
bw_d_filled = bw_d_filled(1:end-1,2:end);

bw_filled = bw_a_filled | bw_b_filled | bw_c_filled | bw_d_filled;

end

