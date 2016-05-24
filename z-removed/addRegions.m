function [data_c] = addRegions( data_c, data2, list )
% addRegions : adds regions in list after error resolution
%
% INPUT :
%       data_c: region (cell) data structure from .err file
%       data2 : region (cell) data structure after error fix
%       list : regions labels to be added
% OUTPUT :
%       data_c : updated region (cell) data structure
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

if numel(list);
    mask_new_reg = double(~imdilate(double(data_c.regs.regs_label>0),...
        strel('square',3)));
    new_regs_label = zeros(size(data_c.regs.regs_label));
    counter = 1;
    BB = data2.regs.props(list(1)).BoundingBox;
    list_c = [];
    
    for mm = list % labels of regions to be added
        try
            [xx,yy] = getBB(data2.regs.props(mm).BoundingBox);
        catch ME
            printError(ME)
        end
        new_regs_label(yy,xx) = new_regs_label(yy,xx) + ...
            (data_c.regs.num_regs+counter)*...
            (mm==data2.regs.regs_label(yy,xx)).*mask_new_reg(yy,xx);
              
        list_c = [list_c, data_c.regs.num_regs+counter];      
        counter = counter + 1;
        BB = addBB(BB, data2.regs.props(mm).BoundingBox);
    end
    
    [xx,yy] = getBB(BB);
    
    data_c.regs.regs_label(yy,xx) = data_c.regs.regs_label(yy,xx) + ...
        new_regs_label(yy,xx);
    data_c.mask_cell = double(data_c.regs.regs_label>0);
end
end