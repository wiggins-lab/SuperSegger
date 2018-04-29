function errNum = compErrInt( fftA, fftB, lamMin, lamMax )
% compErrInt : Computes the error of alignment between two fourier
% transformed images using lamMin and lamMax to calculate the masks.
%
% INPUT :
%      fftA : fourier transform of image A
%      fftB : fourier transform of image B
%      lamMin : minimum lambda to calculate mask
%      lamMax : maximum lambda to calculate mask
% OUTPUT :
%       errNum : error value
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


persistent mask;
persistent mask0;

ss = size(fftA);

if isempty(mask) || ~all( size(mask) == ss )
    kx  = (1:ss(2))/ss(2); % array of incremental values up to 1
    ky  = (1:ss(1))/ss(1);
    [kX,kY] = meshgrid(kx,ky);
    k = sqrt(kX.^2+kY.^2);
    mask = and(k<lamMin^-1,k>lamMax^-1);
    mask0 = k>lamMax^-1;
end

% mean of the values of the fourier transformed image include in mask
mfftA =  mean(abs(fftA(mask)));
mfftB =  mean(abs(fftB(mask)));

% mean of the values of the fourier transformed image include in mask0
m0fftA =  mean(abs(fftA(mask0)));
m0fftB =  mean(abs(fftB(mask0)));

% error calculation
errNum = abs(mfftA-mfftB)/abs(mfftA+mfftB) + ...
    abs(m0fftA-m0fftB)/abs(m0fftA+m0fftB);

end
