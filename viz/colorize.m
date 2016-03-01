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
% University of Washington, 2016
% This file is part of SuperSeggerOpti.



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