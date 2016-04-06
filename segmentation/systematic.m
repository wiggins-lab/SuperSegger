function [minVect,regEmin] = systematic( segs_list, data, cell_mask, xx, yy, CONST)

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
    imshow( cat(3,autogain(cell_mask),...
        autogain(cell_mask_mod),...
        0*autogain(cell_mask)),'InitialMagnification','fit');
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