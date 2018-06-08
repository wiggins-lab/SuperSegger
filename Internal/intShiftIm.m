function imOut = intShiftIm( imIn, out )
% intShiftIm: shifts image 'imIn' by the parameters in 'out'
% out is produced by intAlignIm( imA, imB, precision ).
%
% INPUT :
%   imIn : input image
%   out : output of intAlignIm,
%       where the 3rd element is the row_shift and 4th and col_shift
%
% OUTPUT :
%   imOut : shifted image
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


fftB = fft2(imIn); % fourier transform

deltar = out(3); % net_row_shift in subpixel
deltac = out(4); % net_col_shift in subpixel

phase = 0;
[nr,nc] = size(imIn); % nr : num of rows, nc : num of columns
Nr = ifftshift(-fix(nr/2):ceil(nr/2)-1); % swaps the left and right halves
Nc = ifftshift(-fix(nc/2):ceil(nc/2)-1);
[Nc,Nr] = meshgrid(Nc,Nr);

fftB = fftB.*exp(1i*2*pi*(deltar*Nr/nr+deltac*Nc/nc));

imOut  = (real(ifft2(fftB).*exp(-1i*phase)));

%imOut2 = imtranslate( imIn, -out([4,3]),'FillValues', mean(imIn(:)));

end