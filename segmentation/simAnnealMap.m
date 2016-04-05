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
    debug_flag = 1;
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
x0 = zeros(num_segs,1);

% a hashmap to find energies of states tried before faster
stateEnergyMap = containers.Map();

% runs simulated anneal
options = saoptimset('Display',display,'ReannealInterval',reannealIter,'DataType','custom', 'AnnealingFcn',@newPoint,'StallIterLimit',num_segs*12,'MaxIter',maxiter);
[x,Emin,exitflag,output] = simulannealbnd(@stateCostFunction,x0,[],[],options);

% compare to the state with the on/off segments by score and keep that one
% if it is smaller
xSegment = data.segs.score(segs_list);
Esegment = stateCostFunction (xSegment);
if Esegment < Emin
    x = xSegment;
end

[Emin,minState] = calculateStateEnergy(cell_mask,vect0,segs_list,data,xx,yy,CONST);
regEmin = minState.reg_E; % energy per region

if debug_flag
    disp (['minimum energy is ', num2str(Emin)]);
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


    function E = stateCostFunction (vect0)
        % stateCostFunction : caclulates the cost function of a given state
        % vect0
        
        key = makeKey(vect0);
        
        if isKey(stateEnergyMap, key)
            % state tried before, get energy from the hashmap
            E = stateEnergyMap(key);
        else
            % calculate total score
            [E,~] = calculateStateEnergy(cell_mask,vect0,segs_list,data,xx,yy,CONST);
            stateEnergyMap(key) = E;
        end
        
    end

    function str = makeKey(vect)
        % HashMap function, creates a key from a vector of on/off segments
        % INPUT : vect : logical vector of 1 for segments that are on
        % OUTPUT : str : hashmap key
        str = char(double(vect)'+'a');
    end

end


