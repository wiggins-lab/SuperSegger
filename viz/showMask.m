function showMask( phase, mask, mask2)
% showMask shows an image of the phase image of the cell 
% masked with the found boundaries.
% INPUT : 
%   phase : phase image of the cell
%   mask : mask
%   mask2 : 
% Copyright (C) 2016 Wiggins Lab 
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.


if ~exist( 'mask2' ) || isempty( mask2 )
    mask2 = 0*mask;
end

imshow( cat(3, 0.1*ag(~mask)+0.8*ag(phase), 0.8*ag(phase), 0.2*ag(~mask2)+0.8*ag(phase)), [] );

end

