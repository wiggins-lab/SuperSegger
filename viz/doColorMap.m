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
% Copyright (C) 2016 Wiggins Lab 
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


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