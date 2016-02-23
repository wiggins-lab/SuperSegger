function data = getNeighborPole( data )
% getNeighborPole : flags cell with one neighbor.
% It flags cells with one neighbor that share a pole with that neighbor to 
% determine old and new pole in snapshot data.
%
% INPUT :
%       data : cell file
% OUTPUT :
%       data : updated cell file with new and old pole
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

for ii = 1:data.regs.num_regs    
    % Find and record pole location (not in any order)
    tmp = data.CellA{ii};
    r = tmp.coord.r_center;
    un1_pole = r + tmp.length(1)*tmp.coord.e1/2;
    un2_pole = r - tmp.length(1)*tmp.coord.e1/2;
    
    data.CellA{ii}.pole.r1 = un1_pole ;
    data.CellA{ii}.pole.r2 = un2_pole ;
    
    nei{ii} = trackOptiNeighbors(data,ii);       
end
    
    % LOOP THROUGH NEIGHBOR LIST TO FIND CLOSE GUYS   
    for ii = 1:data.regs.num_regs
                
        if numel(nei{ii}) == 1
            
            ID = ii;
            ID_nei = nei{ii};
            try
            dist(1) = norm(data.CellA{ID}.pole.r1 - data.CellA{ID_nei}.pole.r1) ;
            dist(2) = norm(data.CellA{ID}.pole.r2 - data.CellA{ID_nei}.pole.r2) ;
            dist(3) = norm(data.CellA{ID}.pole.r1 - data.CellA{ID_nei}.pole.r2) ;
            dist(4) = norm(data.CellA{ID}.pole.r2 - data.CellA{ID_nei}.pole.r1) ;
            catch
                keyboard
            end
            
            [Y,I] = min(dist);
            
            if I == 1
                data.CellA{ID}.pole.oldpole = data.CellA{ID}.pole.r2 ;
                data.CellA{ID}.pole.newpole = data.CellA{ID}.pole.r1 ;
                data.CellA{ID_nei}.pole.oldpole = data.CellA{ID_nei}.pole.r2 ;
                data.CellA{ID_nei}.pole.newpole = data.CellA{ID_nei}.pole.r1 ;
                
            elseif I == 2
                data.CellA{ID}.pole.oldpole = data.CellA{ID}.pole.r1 ;
                data.CellA{ID}.pole.newpole = data.CellA{ID}.pole.r2 ;
                data.CellA{ID_nei}.pole.oldpole = data.CellA{ID_nei}.pole.r1 ;
                data.CellA{ID_nei}.pole.newpole = data.CellA{ID_nei}.pole.r2 ;
                
            elseif I == 3
                data.CellA{ID}.pole.oldpole = data.CellA{ID}.pole.r2 ;
                data.CellA{ID}.pole.newpole = data.CellA{ID}.pole.r1 ;
                data.CellA{ID_nei}.pole.oldpole = data.CellA{ID_nei}.pole.r1 ;
                data.CellA{ID_nei}.pole.newpole = data.CellA{ID_nei}.pole.r2 ;
                
            elseif I == 4
                data.CellA{ID}.pole.oldpole = data.CellA{ID}.pole.r1 ;
                data.CellA{ID}.pole.newpole = data.CellA{ID}.pole.r2 ;
                data.CellA{ID_nei}.pole.oldpole = data.CellA{ID_nei}.pole.r2 ;
                data.CellA{ID_nei}.pole.newpole = data.CellA{ID_nei}.pole.r1 ;
                
            end
               
            dist = sort(dist);
            
            data.CellA{ID}.neighbor_pole = dist(1);
            data.CellA{ID_nei}.neighbor_pole = dist(1);
 
        end
    end
    
end
