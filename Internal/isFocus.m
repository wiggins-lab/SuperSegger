function focusNum = isFocus( p1 )
% focusNum : Computes how in focus an image is
% by multiplying the fourier transform with the complex conjugate.
%
% INPUT :
%      p1 : fourier transform of image
%
% OUTPUT :
%       focusNum : error value
%
% Copyright (C) 2016 Wiggins Lab 
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

ss = size( p1);
pp1 = p1.*conj(p1);
mpp1 = mean(pp1(1:10,1:floor(0.5*ss(2))));
k = (1:numel(mpp1))/ss(2);

lam  = 1./k;
mm1 = mean( mpp1( lam<3 ));
mm2 = mean( mpp1( and(lam>8,lam<12)));

focusNum = mm2/mm1-1;

end