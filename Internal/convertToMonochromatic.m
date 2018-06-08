function imMono = convertToMonochromatic(imMultiChannel)
% trackOptiAlignPad : converts images with multiple channels into the
% channel with the maximum value.

% INPUT :
%       imMultiChannel : multiple channel image
% OUTPUT :
%       imMono : monochromatic image
%
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Stylianidou.
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

colors = size(imMultiChannel,3);
maxValue = 0;
for i = 1 : colors
    currentMaxValue = max(max(imMultiChannel(:,:,i)));
    if ( currentMaxValue > maxValue)
        maxValue = currentMaxValue;
        maxChannel = i;
    end
end
if maxValue > 0
    imMono = (imMultiChannel(:,:,maxChannel));
else
    error ('unable to convert images to monochromatic');
end
end