function error = genError(map,DA,CONST)
% genError : generates error for formed regions.
% if the number of regions mapping to the region are not ~=1 or
% if DA is not within the min and max in the constants.
% INPUT :
%       map: contains region numbers for mapping in the order of amount of overlap 
%       DA :
%       CONST :  Segmentation Constants
% OUTPUT :
%       error : list of 0 if no error or 1 if there is an error
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


if isempty( map )    
    error = [];
else
    num_regs = numel(map);
    nB    = zeros(1,num_regs);
    
    for ii = 1:num_regs;
        nB(ii) = numel( map{ii} );
    end
    DA_MIN            = CONST.trackOpti.DA_MIN;
    DA_MAX            = CONST.trackOpti.DA_MAX;    
    error = or(nB ~= 1, or(DA < DA_MIN, DA > DA_MAX));
end
end


