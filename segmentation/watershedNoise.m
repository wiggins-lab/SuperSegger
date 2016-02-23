function [ws,num] = watershedNoise( im, minStep )
% watershedNoise uses watershed on an image and adds noise
%
% INPUT :
%       im : image
%       minStep : 
% OUTPUT :
%       ws : black and white watershed image
%       num : max value if ws
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

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