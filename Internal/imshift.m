function maskShifted = imshift(mask, offset)
% imshift : shifts an array by 'offest' and pads the offset with zeros.
% Used to shift masks upwards, downwards, right and left.
%
% INPUT :
%    mask : input binary mask
%    offset : [x,y] offset. Negative signifies shift upwards/ left.
%
% OUTPUT :
%   maskShifted : shifted binary mask
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou
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


maskShifted = mask;
maskSS = size(mask);

% y direction
if offset(2) < 0 % upwards
    shiftInY = abs(offset(2));
    zeroPad = zeros(min(maskSS(1),shiftInY),maskSS(2));
    maskShifted = [maskShifted(shiftInY+1:end,:);zeroPad];

else % downwards
    shiftInY = abs(offset(2));
    zeroPad = zeros(min(maskSS(1),shiftInY),maskSS(2));
    maskShifted = [zeroPad;maskShifted(1:end-shiftInY,:)];

end

if offset(1) < 0 % left
    shiftInX = abs(offset(1));
    zeroPad = zeros(maskSS(1),min(maskSS(2),shiftInX));
    maskShifted = [maskShifted(:,shiftInX+1:end),zeroPad];

else % right
    shiftInX = abs(offset(1));
    zeroPad = zeros(maskSS(1),min(maskSS(2),shiftInX));
    maskShifted = [zeroPad,maskShifted(:,1:end-shiftInX)];

end


end
