function imMagic = magicContrast( im, radius )
% magicContrast : applies a filter to enhance inter-cellular contrast.
% It is local minimum filter (similar to a median filter) to enhance contrast.
% It is subtracting from each pixel the minimum intensity in its neighborhood.
% It forces the interior of the cells closer to zero intensity. Used to create
% a background mask.
%
% INPUT :
%       im : phase image
%       radius : radius to be used to apply contrast
% OUTPUT :
%       im : phase image with applied contrast
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


si = size( im );

impad = [im(radius:-1:1,radius:-1:1), im(radius:-1:1,:), ...
    im(radius:-1:1,end:-1:(end-radius));...
    im(:, radius:-1:1), im(:, :), im(:,end:-1:(end-radius));...
    im(end:-1:end-radius,radius:-1:1), im(end:-1:end-radius,:), ...
    im(end:-1:end-radius, end:-1:(end-radius))];

xx = (-radius):(radius);

[X,Y] = meshgrid( xx, xx);
mini_mask = ( X.^2+Y.^2 <= radius^2 );

rr = 1:si(1);
cc = 1:si(2);
first_time_flag = 1;

for ii = (-radius):(radius)
    for jj = (-radius):(radius)
        if mini_mask(ii+radius+1,jj+radius+1);            
            if first_time_flag
                minpad = impad(rr+radius+ii,cc+radius+jj);
                first_time_flag = 0;
            else
                minpad = min(minpad,impad(rr+radius+ii,cc+radius+jj));
            end
        end
    end
end

imMagic = im-minpad;
imMagic(imMagic<0) = 0;

end

