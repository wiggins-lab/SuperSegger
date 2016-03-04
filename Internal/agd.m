function im = agd( im, HOT_PX)
% agd : autogains the image setting hot pixels to min value
% it sets pixels > hot pixels * Std.Dev to the min value
%
% INPUT : 
%       im : image
%       HOT_PX : hot pixel value
% OUTPUT :
%       im : autogained image with increased contrast.
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

if ~exist('HOT_PX')
    HOT_PX = 50;
end

sz = size(im);
im = reshape(double(im),1,[]);

s = std(im);

im_min = min(im(:));
im(im > HOT_PX*s) = im_min;
im_max = max(im(:));

im = im - im_min;
im = double(255*im/im_max);

im = reshape(im, sz);

end