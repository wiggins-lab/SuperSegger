function fl = trackOptiCellFluor( fluor, mask, r_offset )
% trackOptiCellFluor : Computes fluorescence statistics
%
% INPUT :
%       fluor: fluorescence image
%       mask : cell mask
%       r_offset : offset in global coordinates
% OUTPUT :
%       fl.sum : sum of fluorescence of all pixels within cell mask
%       fl.r : the coordinates of the center of mass of the fluorescence
%       fl.Ixx : second moment of fluorescence along X 
%       fl.Iyy : second moment of fluorescence along Y
%       fl.Ixy : second moment of fluorescence along YX
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou & Paul Wiggins.
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

fl = [];
fl.sum = sum(double(fluor(mask(:))));
im_size   = size(mask);
im_size_x = im_size(2);
im_size_y = im_size(1);

xx = (1:im_size_x)+r_offset(1)-1;
yy = (1:im_size_y)+r_offset(2)-1;
[X,Y] = meshgrid( xx, yy );

Xcm = sum(X(mask(:)).*double(fluor(mask(:))))/fl.sum;
Ycm = sum(Y(mask(:)).*double(fluor(mask(:))))/fl.sum;

fl.r = [Xcm,Ycm];
fl.Ixx = sum(double(fluor(mask(:))).*(X(mask(:))-Xcm).^2)/fl.sum;
fl.Iyy = sum(double(fluor(mask(:))).*(Y(mask(:))-Ycm).^2)/fl.sum;
fl.Ixy = sum(double(fluor(mask(:))).*(Y(mask(:))-Ycm).*(X(mask(:))-Xcm))/fl.sum;

end
