function [data] = poleDirection( data )
% pole_direction switches the locus position so that it is aligned 
% to the old and new pole. The new pole is in the positive direction.
%
% INPUT : 
%       data :  cell file
%
% OUTPUT : 
%       data : cell file with the aligned locus positions
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

for ii = 1:data.regs.num_regs
    tmp = data.CellA{ii};
    if isfield(tmp.pole,'newpole')
        newPole = tmp.pole.newpole;
        rcm = tmp.coord.r_center;
        if isfield(tmp,'locus1')
            ss = size(tmp.locus1);
            for jj = 1:ss(2)             
                rs  = tmp.locus1(jj).r' ;
                try
                    dif_pole = norm(newPole - rcm);
                    dif_spot = norm(newPole - rs);
                catch
                    keyboard
                end
                if dif_spot > dif_pole
                    tmp.locus1(jj).longaxis = -abs(tmp.locus1(jj).longaxis);
                else
                    tmp.locus1(jj).longaxis = abs(tmp.locus1(jj).longaxis);
                end
            end
        end
    end
    data.CellA{ii} = tmp;    
end

end
