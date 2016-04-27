function im = autogain( im0 );
% autogain : increases the contrast of image im0.
%
% INPUT : 
%       im0 : image
% OUTPUT :
%       im : autogained image with increased contrast.
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

immin = min(im0(:));
im0 = im0-immin;

im = uint8(255*double(im0)/double(max(im0(:))));

end