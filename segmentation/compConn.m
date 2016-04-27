function im = compConn( im_, conn )
% compConn : calculates the connectivity of each pixel
%
% INPUT :
%       im_ : input image
%       conn : values accepted are 4 and 8
%              4 two-dimensional four-connected neighborhood
%              8 two-dimensional eight-connected neighborhood (default)
% OUTPUT :
%       im : output image
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

if ~exist( 'conn' );
    conn = 8;
end

im = uint8(im_>0);
ss = size( im );
im__ = zeros(2+ss(1),2+ss(2));
im__(2:ss(1)+1,2:ss(2)+1) = im;

if conn == 8
    im = ( im__(1:ss(1),1:ss(2)) + im__(2:ss(1)+1,1:ss(2)) + im__(3:ss(1)+2,1:ss(2))...
        +im__(1:ss(1),2:ss(2)+1)                       + im__(3:ss(1)+2,2:ss(2)+1)...
        +im__(1:ss(1),3:ss(2)+2) + im__(2:ss(1)+1,3:ss(2)+2) + im__(3:ss(1)+2,3:ss(2)+2) );
elseif conn == 4;
    im = ( im__(2:ss(1)+1,1:ss(2))...
        +im__(1:ss(1),2:ss(2)+1) + im__(3:ss(1)+2,2:ss(2)+1)...
        +im__(2:ss(1)+1,3:ss(2)+2));
else
    'error in function CompConn'
end

im = double(im).*double(im_);


end

