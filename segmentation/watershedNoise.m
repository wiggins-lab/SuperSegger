function [ws,num] = watershedNoise( im, minStep )
% watershedNoise : uses watershed on an image and adds noise
%
% INPUT :
%       im : input image.
%       minStep : thershold value.
% OUTPUT :
%       ws : black and white watershed image
%       num : max value in ws image
%
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

ws = watershed( im );
run_flag = true;

while run_flag
    
    run_flag = false;
    num = max(ws(:));    
    mins = zeros(1,num);
    zero_ind = find(ws==0);
    maxs = im(zero_ind);
    
    for ii = 1:num;
        mins(ii) = min(im(ws==ii));
    end
    
    hl = maxs'-mins(1:end-1);    
    indl = find( hl<minStep );
    
    if numel( indl )
        ii = indl(1);
        ws(zero_ind(ii)) = ii;
        ws(ws==(ii+1))=ii;
        run_flag = true;
    else
        
        hr = maxs'-mins(2:end);        
        indr = find( hr<minStep );
        
        if numel( indr )
            ii = indr(1);
            ws(zero_ind(ii)) = ii;
            ws(ws==(ii+1))=ii;
            run_flag = true;
        end 
    end
    ws = bwlabel(ws);   
end

end