function colorRBG = getRGBColor( color_name )
% getRGBColor : returns rgb value of color name.
%
% INPUT :
%   color_name : string with initial for color name {'r','g','b','o','c','y'}
% OUTPUT :
%   colorRBG : color rgb value
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


if ischar( color_name )
    cyan_col = [0,255,255]/255;
    orange_col = [255,165,0]/255;
    red_col = [255,0,0]/255;
    green_col = [0,255,0]/255;
    blue_col = [0,0,255]/255;
    yellow_col = [255,255,0]/255;
    
    
    if color_name == 'r'
        colorRBG = red_col;
    elseif color_name == 'c'
        colorRBG = cyan_col;
    elseif color_name == 'y'
        colorRBG = yellow_col;
    elseif color_name == 'b'
        colorRBG = blue_col;
    elseif color_name == 'o'
        colorRBG = orange_col;
    elseif color_name == 'g'
        colorRBG = green_col;
    else
        disp ('color not found');
    end
    
else
    
    colorRBG = color_name;
end

end


