function focusNum = isFocus( image )
% focusNum : Computes how in focus an image.
% It multiplies the fourier transform with the complex conjugate.
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

ss = size(image);
pp1 = image.*conj(image);
mean_pp1 = mean(pp1(1:10,1:floor(0.5*ss(2))));
k = (1:numel(mean_pp1))/ss(2);

lam  = 1./k;
mm1 = mean( mean_pp1( lam<3 ));
mm2 = mean( mean_pp1( and(lam>8,lam<12)));

focusNum = mm2/mm1-1;

end