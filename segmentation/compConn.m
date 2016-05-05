function im = compConn( imInput, conn )
% compConn : calculates the connectivity of each pixel
%
% INPUT :
%       imInput : input image
%       conn : values accepted are 4 and 8
%              4 two-dimensional four-connected neighborhood
%              8 two-dimensional eight-connected neighborhood (default)
% OUTPUT :
%       im : output image
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Stylianidou, Paul Wiggins.
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


if ~exist( 'conn' );
    conn = 8;
end

im = uint8(imInput>0);
ss = size(im);
imPadded = zeros(2+ss(1),2+ss(2));
imPadded(2:ss(1)+1,2:ss(2)+1) = im;

if conn == 8
    im = (imPadded(1:ss(1),1:ss(2)) + imPadded(2:ss(1)+1,1:ss(2)) + imPadded(3:ss(1)+2,1:ss(2))...
        +imPadded(1:ss(1),2:ss(2)+1)                       + imPadded(3:ss(1)+2,2:ss(2)+1)...
        +imPadded(1:ss(1),3:ss(2)+2) + imPadded(2:ss(1)+1,3:ss(2)+2) + imPadded(3:ss(1)+2,3:ss(2)+2) );
elseif conn == 4;
    im = (imPadded(2:ss(1)+1,1:ss(2))...
        +imPadded(1:ss(1),2:ss(2)+1) + imPadded(3:ss(1)+2,2:ss(2)+1)...
        +imPadded(2:ss(1)+1,3:ss(2)+2));
else
    disp('error in function CompConn')
end

im = double(im).*double(imInput);


end

