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