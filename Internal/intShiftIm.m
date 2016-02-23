function imOut = intShiftIm( imIn, out )
% intShiftIm: shifts image imIn by the parameters in out.
% out is produced by intAlignIm( imA, imB, precision ).
%
% INPUT :
%   imIn : image 
%   out : output of intAligIm, row_shift in (3) and col_shift (4)
%   array.
%
% OUTPUT :
%   imOut : shifter image
%
% Copyright (C) 2016 Wiggins Lab 
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

fftB = fft2(imIn); % fourier transform

deltar = out(3); % net_row_shift in subpixel
deltac = out(4); % net_col_shift in subpixel

shift = [deltar, deltac];

phase = 0;
[nr,nc] = size(imIn); % nr : num of rows, nc : num of columns
Nr = ifftshift(-fix(nr/2):ceil(nr/2)-1); % swaps the left and right halves
Nc = ifftshift(-fix(nc/2):ceil(nc/2)-1);
[Nc,Nr] = meshgrid(Nc,Nr);

fftB = fftB.*exp(i*2*pi*(deltar*Nr/nr+deltac*Nc/nc));

imOut  = (real(ifft2(fftB).*exp(-i*phase)));

end