function im = magicContrastFast2( im, mask, radius )
% magicContrastFast2 : applied a filter to enhance contrast to the image.
% It is local minimum filter (similar to a median filter) to enhance contrast 
%
% INPUT :
%       im : phase image
%       mask : mask for cells
%       radius : to be used to apply contrast
% OUTPUT :
%       im : phase image with applied contrast
%
% Written by Paul Wiggins and Keith Cheveralls 2010
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

si = size( im );

impad = [[im(radius:-1:1,radius:-1:1), im(radius:-1:1,:), im(radius:-1:1,end:-1:(end-radius));...
    im(:, radius:-1:1), im(:, :), im(:,end:-1:(end-radius));...
    im(end:-1:end-radius,radius:-1:1), im(end:-1:end-radius,:), im(end:-1:end-radius, end:-1:(end-radius))]];

xx = (-radius):(radius);

[X,Y] = meshgrid( xx, xx);
mini_mask = ( X.^2+Y.^2 <= radius^2 );

rr = 1:si(1);
cc = 1:si(2);
flag = 1;

for ii = (-radius):(radius)
    for jj = (-radius):(radius)
        if mini_mask(ii+radius+1,jj+radius+1);
          
            if flag
minpad = impad(rr+radius+ii,cc+radius+jj);
flag = 0;
            else
minpad = min(minpad,impad(rr+radius+ii,cc+radius+jj));
            end            
        end
    end
end

im = im-minpad;
im(im<0) = 0;

end
