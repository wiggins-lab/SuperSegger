function im_ = doColorMap( im, colormap_ )
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


ss  = size( im );
im_ = im;
im_ = im_(:);
im_ = colormap_(im_+1,:);
im_ = reshape( im_, [ss,3]);

end