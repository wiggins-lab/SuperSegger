function  imColorized = colorize( im, mask, colormap_, background )
% colorize : creates an image, with defined mask, colormap, and background
%
% INPUT :
%       im : image
%       mask : image mask
%       colormap : coloramp to be used for image (default jet)
%       background : background color (RGB array), (default gray)
% OUTPUT :
%       imColorized : final image
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins.
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

if ~exist( 'colormap_', 'var' ) || isempty( colormap_ )
    colormap_ = jet(256);
end

if ~exist( 'mask', 'var' ) || isempty( mask )
    mask = ones(size(im));
else
    mask = double( mask );
    mask = mask./(max(mask(:)));
end
    
if ~exist( 'background', 'var' ) || isempty( background )
    background = [0.5,0.5,0.5];
end

imTmp = double(255*doColorMap( ag(im, 0, max(im( mask>.95 )) ), colormap_ ));
mask3 = cat( 3, mask, mask, mask );
onez = ones(size(im));
imColorized = uint8(mask3.*imTmp + 255.0*(1-mask3).*cat(3, ...
    background(1)*onez, background(2)*onez, background(3)*onez ));


end