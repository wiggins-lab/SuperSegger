function errNum = compErrInt( fftA, fftB, lamMin, lamMax );
% Computes the error of alignment between two fourier transformed images
% using lamMin and lamMax to calculate the masks
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
% University of Washington, 2016
% This file is part of SuperSeggerOpti.



persistent mask;
persistent mask0;

ss = size( fftA );

if isempty(mask) || ~all( size(mask) == ss )
    kx  = (1:ss(2))/ss(2);
    ky  = (1:ss(1))/ss(1); 
    [kX,kY] = meshgrid(kx,ky);
    k = sqrt(kX.^2+kY.^2);    
    mask = and(k<lamMin^-1,k>lamMax^-1);   
    mask0 = k>lamMax^-1;
end
    
mfftA =  mean( abs(fftA(mask)) ); 
mfftB =  mean( abs(fftB(mask)) ); 

m0fftA =  mean( abs(fftA(mask0)) ); 
m0fftB =  mean( abs(fftB(mask0)) );

errNum = abs(mfftA-mfftB)/abs(mfftA+mfftB) + abs(m0fftA-m0fftB)/abs(m0fftA+m0fftB);

end