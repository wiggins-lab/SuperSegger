function  [data_c,data_r] = intRepairErr( data_c,data_r)
% intRepairErr repairs the error fields of current and reverse data 
% after error resolution.
%
% INPUT :
%       data_c : data / region files for current frame
%       data_r : data/ region files for reverse frame
% OUTPUT :
%       data_c : data/ region files for current frame with errors fixed
%       data_r : data/ region files for reverse frame with errors fixed
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

if ~isempty(data_r)
    ind_double = cell(1,1000);
    count = 0;    
    ID = unique(data_c.regs.ID);
    if numel(data_c.regs.ID) > numel(ID)
        num = numel(ID);
        
        for kk = 1:num
            
            ind = find(ID(kk)==data_c.regs.ID);
            if numel(ind)> 1
                count = count + 1;
                ind_double{count} = ind;
            end
        end
    end
    
    ind_double = ind_double(1:count);    
    
    for kk = 1:count
        data_c.regs.ID(ind_double{kk})      = 0*data_c.regs.ID(ind_double{kk});
        data_c.regs.error.r(ind_double{kk}) = 1+0*data_c.regs.error.r(ind_double{kk});
        data_c.regs.ehist(ind_double{kk})   = 1+0*data_c.regs.error.r(ind_double{kk});  
        ID = data_c.regs.ID(ind_double{kk});
        
        for ll = reshape( ID, 1, numel(ID) )
            ind= find(ll == data_r.regs.ID);
            data_r.regs.deathF(ind) = 1;
            data_r.regs.divide(ind) = 0;
            data_r.regs.birth(ind) = 0;
            data_r.regs.birthF(ind) = 0;
            data_r.regs.motherID(ind) = 0;
            data_r.regs.sisterID(ind) = 0;
            for jj = reshape(ind,1,numel(ind))
                data_r.regs.daughterID{jj} = [];
                
            end
        end
    end
    
end

end