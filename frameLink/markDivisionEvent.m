function [data_c, data_r, cell_count] = markDivisionEvent( ...
    data_c, sister1, data_r, regR, time, errorStat, sister2, cell_count, verbose)

if ~data_c.regs.ID(sister1)
    cell_count = cell_count+1;
    
    % set sister 1 - regC
    data_c.regs.death(sister1) = time; % Death/divide time
    data_c.regs.deathF(sister1) = 1; % Divides in this frame
    data_c.regs.birth(sister1) = time; % Birth Time
    data_c.regs.birthF(sister1) = 1; % Division in this frame
    data_c.regs.age(sister1) = 1; % cell age. starts at 1.
    data_c.regs.divide(sister1) = 0; % succesful division in this frame
    data_c.regs.ehist(sister1) = errorStat; % 1 if cell has an unresolved error before this time.
    data_c.regs.stat0(sister1) = ~errorStat; % 1 for successful division.
    data_c.regs.sisterID(sister1) = cell_count+1;   % sister cell ID
    data_c.regs.motherID(sister1) = data_r.regs.ID(regR);   % mother cell ID
    data_c.regs.daughterID{sister1} = [];   % daughter cell ID
    data_c.regs.ID(sister1) = cell_count; % cell ID number
    data_c.regs.ID_{sister1} = cell_count; % cell ID number.
    
    % set the sister 2 : ii_sister
    cell_count = cell_count+1;
    data_c.regs.death(sister2) = time; % Death/division time
    data_c.regs.deathF(sister2) = 1; % Division in this frame
    data_c.regs.birth(sister2) = time; % Birth Time
    data_c.regs.birthF(sister2) = 1; % Division in this frame
    data_c.regs.age(sister2) = 1; % cell age. starts at 1
    data_c.regs.divide(sister2) = 0; % succesful division in this frame
    data_c.regs.ehist(sister2) = errorStat; % True if unresolved error before this time.
    data_c.regs.stat0(sister2) = ~errorStat;  % 1 if successful division
    data_c.regs.sisterID(sister2) = cell_count-1;   % sister cell ID
    data_c.regs.motherID(sister2) = data_r.regs.ID(regR);   % mother cell ID
    data_c.regs.daughterID{sister2} = [];   % daughter cell ID
    data_c.regs.ID(sister2) = cell_count; % cell ID number
    data_c.regs.ID_{sister2} = cell_count; % cell ID number.
    
    if verbose
        disp (['Frame : ',num2str(time),' daughers from regions ', num2str(sister1) ,' ', num2str(sister2) ,'  with IDs', num2str(cell_count-1), ' & ',num2str(cell_count)]);
    end
    % put the daughters' ids at the mother
    data_r.regs.divide(regR)     = ~errorStat;    % succesful divide in this
    data_r.regs.daughterID{regR} = [cell_count-1,cell_count];   % daughter cell ID
    
    if isfield( data_c.regs, 'lyse' )
        data_c.regs.lyse.errorColor1Cum(sister2) = ...
            time*double(logical(data_c.regs.lyse.errorColor1(sister2)));
        data_c.regs.lyse.errorColor2Cum(sister2) = ...
            time*double(logical(data_c.regs.lyse.errorColor2(sister2)));
        data_c.regs.lyse.errorShapeCum(sister2)  = ...
            time*double(logical(data_c.regs.lyse.errorShape(sister2)));
        data_c.regs.lyse.errorColor1Cum(sister1) = ...
            time*double(logical(data_c.regs.lyse.errorColor1(sister1)));
        data_c.regs.lyse.errorColor2Cum(sister1) = ...
            time*double(logical(data_c.regs.lyse.errorColor2(sister1)));
        data_c.regs.lyse.errorShapeCum(sister1)  = ...
            time*double(logical(data_c.regs.lyse.errorShape(sister1)));
        data_c.regs.lyse.errorColor1bCum(sister2) = ...
            time*double(logical(data_c.regs.lyse.errorColor1b(sister2)));
        data_c.regs.lyse.errorColor2bCum(sister2) = ...
            time*double(logical(data_c.regs.lyse.errorColor2b(sister2)));
        data_c.regs.lyse.errorColor1bCum(sister1) = ...
            time*double(logical(data_c.regs.lyse.errorColor1b(sister1)));
        data_c.regs.lyse.errorColor2bCum(sister1) = ...
            time*double(logical(data_c.regs.lyse.errorColor2b(sister1)));
    end
else
    if verbose
        disp (['Frame ', num2str(time), ': ' , num2str(sister1),' already has an ID from division event.']);
    end
end
end