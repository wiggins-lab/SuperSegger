function [minVect,regEmin] = systematic( segs_list, data, cell_mask, xx, yy, CONST)
% systematic: Finds the minimum energy configuration by trying all segment 
% combinations.
%
% INPUT :
%       segs_list : list of ids of segments to be turned on and off
%       data : seg data file
%       cell_mask : mask of regions of cells to be optimized
%       xx : xx from bounding box of cell_mask
%       yy : yy from bounding box of cell_mask
%       CONST : segmentation constants
%
% OUTPUT :
%       minVect : vector of segments to be on for minimum energy found.
%       regEmin : energy of every region for the minimum state
%
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Stylianidou, Paul Wiggins.
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

debug_flag = 0;

num_segs = numel(segs_list);
num_comb = 2^num_segs;
state = cell( 1, num_comb );
regionScore = zeros( 1, num_comb );

for jj = 1:num_comb;
    
    % goes through all combinations and turns on segments
    vect = makeVector(jj-1,num_segs)';
    
    % calculates state energy
    [regionScore(jj),state{jj}] = calculateStateEnergy(cell_mask,vect,segs_list,data,xx,yy,CONST);
    
end

% get the minimum score
[Emin, jj_min] = min(regionScore);
minVect = makeVector(jj_min-1,num_segs)';
minState = state{jj_min};
regEmin = minState.reg_E;

if debug_flag
    % shows the minimum score found from systematic
    cell_mask_mod = cell_mask;    
    for kk = 1:num_segs
        cell_mask_mod = cell_mask_mod - minVect(kk)*(segs_list(kk)==data.segs.segs_label(yy,xx));
    end
    figure(1);
    clf;
    imshow( cat(3,ag(cell_mask),...
        ag(cell_mask_mod),...
        0*ag(cell_mask)),'InitialMagnification','fit');
    disp(['Total Region Score : ',num2str(Emin)]);
end

end

function vect = makeVector( nn, n )
vect = zeros(1,n);
for i=n-1:-1:0;
    vect(i+1) = floor(nn/2^i);
    nn = nn - vect(i+1)*2^i;
end
end