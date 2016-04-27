function [data ] = deleteRegions( data, list_c )
% deleteRegions : deletes regions from error resolution
%
% INPUT :
%       data: region (cell) data structure from .err file
%       list :  regions labels to be deleted
% OUTPUT :
%       data : updated region (cell) data structure
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

try
    for mm = list_c        
        [xx,yy] = getBB( data.regs.props(mm).BoundingBox);
        tmp = (data.regs.regs_label(yy,xx) == mm);
        data.regs.regs_label(yy,xx) = data.regs.regs_label(yy,xx)-mm*tmp;
    end
catch ME
   printError(ME);
end
data.mask_cell = (data.regs.regs_label > 0);

end