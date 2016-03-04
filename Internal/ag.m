function im = ag (im,imin,imax)
% ag : autogain, it increases the contrast of image im, using imin and imax.
% It subtracts the the minimum from of the image, divides by the max and
% then normalizes to 255.
%
% INPUT : 
%       im : image
%       imin : min value used to set autogained image (default : min of image)
%       imax : max value used to set autogained image (default : max of image)
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

% subtract min
im = im - double(im_min);

if exist( 'imax', 'var') && ~isempty(imax)
    im_max = imax-imin;
else
    im_max = max(im(:));
end
    
% autogain and normalization to uint8
im = uint8(255*im/double(im_max));

end