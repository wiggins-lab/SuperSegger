function [im,imin,imax] = ag (im,imin,imax)
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

im = double(im);



im(isinf(im(:))) = nan;

if ~exist( 'imin', 'var') || isempty( imin ) 
    imin = min( im(:) );
else
    imin = double( imin );
end

    
if ~exist( 'imax', 'var') || isempty( imax )
    imax = max( im(:) );
else
    imax = double( imax );    
end
    
if imin == imax 
    if imin > 0 
        im = im/imax;
    end
else
    im = (im-imin)/(imax-imin);
end
    
% autogain and normalization to uint8
im = uint8(255*im);


end