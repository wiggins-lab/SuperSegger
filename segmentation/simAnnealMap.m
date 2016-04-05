function [x,regEmin]= simAnnealMap( segs_list, data, ...
    cell_mask, xx, yy, CONST, debug_flag)
% simAnneal: Finds the minimum energy configuration using simulated anneal.
%
% INPUT :
%       segs_list : list of ids of segments to be turned on and off
%       data : seg data file
%       cell_mask : mask of regions of cells to be optimized
%       xx : xx from bounding box of cell_mask
%       yy : yy from bounding box of cell_mask
%       CONST : segmentation constants
%       debug_flag : 1 to display 'diagnose' for simulated anneal
%
% OUTPUT :
%       x : vector of segments to be on for minimum energy found.
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


num_segs = numel(segs_list);

if ~exist('debug_flag', 'var') || isempty( debug_flag )
    debug_flag = 0
end

if debug_flag
    display = 'diagnose';
else
    display = 'off';
end

if isfield( CONST.regionOpti, 'ADJUST_FLAG' ) && CONST.regionOpti.ADJUST_FLAG
    maxiter = floor(CONST.regionOpti.Nt * num_segs/10);
else
    maxiter = CONST.regionOpti.Nt;
end

% interval at which it sets the temperature to T0 and starts annealing again
reannealIter = round(maxiter / 2);
ss = size(data.phase);

% initial state
x0 = ones(num_segs,1);

% a hashmap to find energies of states tried before faster
stateEnergyMap = containers.Map();

% create inital segment mask
seg_mask = cell (1,num_segs);
for ff = 1:num_segs
    seg_mask{ff} = (segs_list(ff)==data.segs.segs_label(yy,xx));
end

% runs simulated anneal
options = saoptimset('Display',display,'ReannealInterval',reannealIter,'DataType','custom', 'AnnealingFcn',@newPoint,'StallIterLimit',num_segs*12,'MaxIter',maxiter);
[x,Emin,exitflag,output] = simulannealbnd(@stateCostFunction,x0,[],[],options);

% compare to the state with the on/off segments by score and keep that one
% if it is smaller
xSegment = data.segs.score(segs_list);
Esegment = stateCostFunction (xSegment);
if Esegment < Emin
    x = xSegment;
    Emin = Esegment;
end

minState = calualteStateEnergies(x);
regEmin = minState.reg_E(minState.reg_vect0); % energy per region

if debug_flag
    displayState(x,segs_list,data)
end


    function displayState(x,segs_list,data)
        % displayState : displays the modified mask given a vector x of 
        % segments that are on and off.
        cell_mask_mod = cell_mask;
        num_segs = numel(segs_list);
        for kk = 1:num_segs
            cell_mask_mod = cell_mask_mod - x(kk)*(segs_list(kk)==data.segs.segs_label(yy,xx));
        end
        imshow(cell_mask_mod);
    end

        
    function vect1 = newPoint ( optimvalues,~ )
        %  newPoint : modifies the previous state to a new state, by
        % switching one of the segments.
        vect0 = optimvalues.x;
        nn = floor(rand*num_segs)+1;
        vect1 = vect0;
        vect1(nn) = ~vect1(nn);
    end

    function state = calualteStateEnergies(vect0)
      % calualteStateEnergies : calculate new state for vect0
            state.seg_E = data.segs.scoreRaw(segs_list)*CONST.regionOpti.DE_norm;
            state.seg_vect0 = logical(vect0);
            state.seg_mask= cell (1, num_segs  );
            state.reg_E= zeros(1, num_segs+3);
            state.reg_vect0= false(1, num_segs+3);
            
            % make the new modified mask based on the seg state vector
            state.mask = cell_mask;
            
            for ff = 1:num_segs
                if vect0(ff)
                    state.mask(seg_mask{ff}) = false;
                end
            end
            
            % label the regs
            state.reg_label = bwlabel( state.mask, 8 );
            state.reg_props = regionprops( state.reg_label,'BoundingBox','Orientation','Area');
            num_regs_mod  = max(state.reg_label(:));
            state.ss = size(state.reg_label);
            
            % loop through the regs and get their scores
            kk_range = 1:num_regs_mod;
            state.reg_vect0(kk_range) = 1;
            
            for ff = kk_range;
                [xx_,yy_] = getBBpad( state.reg_props(ff).BoundingBox, state.ss, 0);
                state.reg_mask{ff} = (state.reg_label==ff);
                info = CONST.regionScoreFun.props(state.reg_mask{ff}(yy_,xx_), state.reg_props(ff));
                state.reg_E(ff) = CONST.regionScoreFun.fun(info,CONST.regionScoreFun.E);
            end      
    end
    
    function E = stateCostFunction (vect0)
        % stateCostFunction : caclulates the cost function of a given state
        % vect0
        
        key = makeKey(vect0);
        
        if isKey(stateEnergyMap, key)
            % state tried before, get energy from the hashmap
            E = stateEnergyMap(key);
        else         
            % calculate total score
            state = calualteStateEnergies(vect0);
            E = calcCost(state.reg_vect0, state.seg_vect0, state);
            stateEnergyMap(key) = E;
        end
    end

    function E = calcCost(reg_vect,seg_vect,state)
        % calcMLL: calculates the cost for a set of vectors and segments
        % seg_E energies are already multiplied by DE_norm       
        E_reg = state.reg_E(reg_vect);
        E_seg = state.seg_E;
        sigma = 1-2*double(seg_vect);
        E = mean (-E_reg) + mean( sigma .* E_seg);        
    end

    function str = makeKey(vect)
        % HashMap function, creates a key from a vector of on/off segments
        % INPUT : vect : logical vector of 1 for segments that are on
        % OUTPUT : str : hashmap key
        str = char(double(vect)'+'a');
    end

end


