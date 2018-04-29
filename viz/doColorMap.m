function im_new = doColorMap( imOriginal, colormap_ , caxis_ )
% doColorMap : Applies colormap to an image.
%
% INPUT :
%       im_ : image
%       colormap_ : coloramp to be used for image (default jet)
%       caxis_ : 
%
% OUTPUT :
%       im_new : image with the colormap applied
%
% holdcoldinv : inverts hot to cold in colormap.
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

if ~exist( 'caxis_', 'var' ) || isempty( caxis_ )
    caxis_ = [min(imOriginal(:)),max(imOriginal(:))];
end

im = double((imOriginal-caxis_(1)))/double((caxis_(2)-caxis_(1)));
im(im<0)=0;
im(isnan(im)) = 0;
ss_c = size(colormap_);

im = floor( ss_c(1)*im)+1;
im(im>ss_c(1))=ss_c(1);

ss  = size( im );
im_new = im(:);
im_new = colormap_(im_new,:);
im_new = reshape( im_new, [ss,3]);

end