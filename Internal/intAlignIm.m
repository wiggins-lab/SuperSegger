function  [out, errNum, focusNum] = intAlignIm( imA, imB, precision )
% intAlignIm : aligning image A to image B with given precision
%
% INPUT :
%      imA : image A
%      imB : image B
%      precision :  Upsampling factor (integer). Images will be registered to 
%           within 1/precision of a pixel. 
%
% OUTPUT :
%       out :  [error,diffphase,net_row_shift,net_col_shift]
%           error : Translation invariant normalized RMS error between f and g
%           diffphase : Global phase difference between the two images (should be
%           zero if images are non-negative).
%           net_row_shift, net_col_shift : Pixel shifts between images
%       errNum : error value of alignment
%       focusNum : score of how focused the images are
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



% fourier transform images
fftA = fft2(imA);
fftB = fft2(imB);

% subpixel image registration by crosscorrelation
try
    out = dftregistration(fftA,fftB,precision);
catch ME
   printError( ME )
end

% calculate error
lamMin = 5;
lamMax = 100;
errNum = compErrInt( fftA, fftB, lamMin, lamMax );

% calculates how in focus image A is
focusNum = isFocus( fftA );

end