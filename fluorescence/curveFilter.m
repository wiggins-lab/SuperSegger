function [M_, G_, C1_, C2_, M, G, C1, C2, im_xx, im_yy, im_xy] = curveFilter( im, filterWidth )
% curveFilter : calculates the curvatures of an image.
%
% INPUT : 
%       im : image to be filtered
%       filterWidth : filter width
% OUTPUT : 
%       M_ : Mean curvature of the image without negative values
%       G_ : Gaussian curvature of the image without negative values
%       C1_ : Principal curvature 1 of the image without negative values
%       C2_ : Principal curvature 2 of the image without negative values
%       M : Mean curvature of the image
%       G : Gaussian curvature of the image
%       C1 : Principal curvature 1 of the image
%       C2 : Principal curvature 2 of the image
%       im_xx :
%       im_yy :
%       im_xy :
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Connor Brennan & Paul Wiggins.
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


oldflag = true;

im = double(im);

% filter width
if ~exist( 'filterWidth', 'var' ) || isempty( filterWidth )
    filterWidth = 1.5;
end


% Make filter 
x = -floor(7*filterWidth):floor(7*filterWidth);
%x = -10:10;
[X,Y] = meshgrid( x, x);
R2 = X.^2+Y.^2;

v = filterWidth^2;

gau = 1/(2*pi*v) * exp( -R2/(2*v) );

if oldflag
    f_xx = (2*pi*v^2)*((X/v).^2-1/v).*gau;
    f_yy = (2*pi*v^2)*((Y/v).^2-1/v).*gau;
    f_xy = (2*pi*v^2)*X.*Y.*gau/v^2;
else
    f_xx = ((X/v).^2-1/v).*gau;
    f_yy = ((Y/v).^2-1/v).*gau;
    f_xy = X.*Y.*gau/v^2;
end
% Do filtering
im_xx = imfilter( im, f_xx, 'replicate' );
im_yy = imfilter( im, f_yy, 'replicate' );
im_xy = imfilter( im, f_xy, 'replicate' );

% gaussian curvature
G = im_xx.*im_yy-im_xy.^2;

% mean curvature
M = -(im_xx+im_yy)/2;

% compute principal curvatures
C1 = (M-sqrt(abs(M.^2-G)));
C2 = (M+sqrt(abs(M.^2-G)));

% remove negative values
G_ = G;
G_(G<0) = 0;

M_ = M;
M_(M<0) = 0;

C1_ = C1;
C1_(C1<0) = 0;

C2_ = C2;
C2_(C2<0) = 0;

end