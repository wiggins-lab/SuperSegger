function [clist0] = gate( clist )
% gate : used to gate the list of cells.
% This is done according to an already made gate field in clist
%
% INPUT :
%   clist : list of cells with time-independent info
% OUTPUT :
%   clist0 : list of cells that passed the gate
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

clist0 = [];
clist0.def = clist.def;


ss = size(clist.data);

inflag = true(ss(1),1);

if isfield( clist, 'gate' ) && ~isempty ('gate.clist')
    
    for ii = 1:numel(clist.gate)
        
        if numel(clist.gate(ii).ind) == 2
            inflag = and(inflag, inpolygon( clist.data(:,clist.gate(ii).ind(1)), ...
                clist.data(:,clist.gate(ii).ind(2)), ...
                clist.gate(ii).xx(:,1), clist.gate(ii).xx(:,2) ));
        else
            x = clist.data(:,clist.gate(ii).ind);
            inflag = and( inflag, and( x > min(clist.gate(ii).x), x < max(clist.gate(ii).x)));
        end
        
    end
end


clist0.data = clist.data(inflag,:);

end