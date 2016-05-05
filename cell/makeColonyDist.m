function dist_mask = makeColonyDist(mask)
% makeColonyDist : returns the distance mask for the colony
% It dilates, the image, fills the holes, and then returns for each pixel 
% the distance from the nearest non zero pixel. 
%
% INPUT : 
%   mask : image of mask of cells
% OUTPUT :
%   dist_mask : distance between that pixel and nearest non zero pixel.
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


dist_mask = imdilate(mask, strel('disk',5)); % dilates image
dist_mask = imfill( dist_mask, 'holes' ); % fills holes
dist_mask = ~imerode(dist_mask, strel('disk',5)); % opposite of erode
dist_mask = bwdist(dist_mask); % distance to nearest non-zero pixel 

%imshow( dist_mask, [] );


end

