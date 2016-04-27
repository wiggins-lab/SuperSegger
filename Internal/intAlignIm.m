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
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


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