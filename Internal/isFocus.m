function focusNum = isFocus( image )
% focusNum : Computes how in focus an image is.
% It multiplies the fourier transform with the complex conjugate.
%
% INPUT :
%      image : fourier transform of image
%
% OUTPUT :
%       focusNum : error value
%
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


ss = size(image);
pp1 = image.*conj(image);
mean_pp1 = mean(pp1(1:10,1:floor(0.5*ss(2))));
k = (1:numel(mean_pp1))/ss(2);

lam  = 1./k;
mm1 = mean( mean_pp1( lam<3 ));
mm2 = mean( mean_pp1( and(lam>8,lam<12)));

focusNum = mm2/mm1-1;

end