function im = ag( im, imin, imax)
% ag : increases the contrast of image im, using imin to imax.
% The contrast of the image is increased.
%
% INPUT : 
%       im : image
%       imin : min value used to set autogained image
%       imax : max value used to set autogained image
% OUTPUT :
%       im : autogained image with increased contrast.
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


im = double(im);

if exist( 'imin', 'var') && ~isempty(  imin )
    im_min = imin;
else
    im_min = min(im(:));
end

im = im - double(im_min);

if exist( 'imax', 'var') && ~isempty(  imax )
    im_max = imax-imin;
else
    im_max = max(im(:));
end
    
    
im = uint8(255*im/double(im_max));
end