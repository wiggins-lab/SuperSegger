function dist_mask = makeColonyDist( mask )
% makeColonyDist : returns the distance mask for the colony
% It dilates, the image, fills the holes, and then returns for each pixel 
% the distance between that pixel and nearest non zero pixel. 
%
% INPUT : 
%   mask : mask of image
% OUTPUT :
%   dist_mask : distance between that pixel and nearest non zero pixel.
%
% Copyright (C) 2016 Wiggins Lab 
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.




dist_mask = imdilate(mask, strel('disk',5)); % dilates image
dist_mask = imfill( dist_mask, 'holes' ); % fills holes
dist_mask = ~imerode(dist_mask, strel('disk',5)); % opposite of erode
dist_mask = bwdist( dist_mask ); % distance to nearest non-zero pixel 

%imshow( dist_mask, [] );


end

