function im = doColorMap( im_, colormap_ , caxis_ )
% doColorMap : ?
%
% INPUT :
%       im : image
%       colormap : coloramp to be used for image (default jet)
%
% OUTPUT :
%       im_ : 
%
% Copyright (C) 2016 Wiggins Lab 
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


if ~exist( 'caxis_', 'var' ) || isempty( caxis_ )
    caxis_ = [min(im_(:)),max(im_(:))];
end

im = double((im_-caxis_(1)))/double((caxis_(2)-caxis_(1)));
im(im<0)=0;
ss_c = size(colormap_);

im = floor( ss_c(1)*im)+1;
im(im>ss_c(1))=ss_c(1);


ss  = size( im );
im = im(:);
im = colormap_(im,:);
im = reshape( im, [ss,3]);

end