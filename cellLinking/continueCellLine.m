function [data_c, data_r] = continueCellLine( data_c, regNumC, data_r,...
    regNumR, time, errorStat)
    
    disp (['Frame ', num2str(time), ' continue reg ', num2str(regNumC), ' from reg ' , num2str(regNumR),...
        ' with cell ID ', num2str(data_r.regs.ID(regNumR))]); 
    % set the death/deathF to current time. They are reset when cell is
    % visited again.
    data_c.regs.death(regNumC) = time; % Death/divide time
    data_c.regs.deathF(regNumC) = 1; % 1 if cell dies in this frame    
    data_c.regs.birth(regNumC) = data_r.regs.birth(regNumR); % take birth time from previous frame
    data_c.regs.birthF(regNumC) = 0; % Division in this frame    
    data_c.regs.age(regNumC) = data_r.regs.age(regNumR)+1; % cell age. starts at 1.
    data_c.regs.divide(regNumC) = 0; % 1 if succesful division in this frame.        
    data_c.regs.contactHist(regNumC) = data_r.regs.contactHist(regNumR) || data_c.regs.contact(regNumC);
    data_c.regs.ehist(regNumC) = data_r.regs.ehist(regNumR) || errorStat; % 1 if cell has unresolved
    % error before this time.
    data_c.regs.stat0(regNumC) = data_r.regs.stat0(regNumR); % Results from a successful division.    
    data_c.regs.sisterID(regNumC) = data_r.regs.sisterID(regNumR);   % sister cell ID
    data_c.regs.motherID(regNumC) = data_r.regs.motherID(regNumR);   % mother cell ID
    data_c.regs.daughterID{regNumC} = [];   % daughter cell ID
    data_c.regs.ID(regNumC) = data_r.regs.ID(regNumR); % cell ID number  
    
    % reset death and division on previous frame
    data_r.regs.death(regNumR) = time; % reset death/divide time to current
    data_r.regs.deathF(regNumR) = 0; % set to 0 division in previous frame   
    data_r.regs.divide(regNumR) = 0; % set to 0 succesful division in previous frame
        
   if isfield( data_c.regs, 'lyse' )
        if ~data_r.regs.lyse.errorColor1Cum(regNumR)
            data_c.regs.lyse.errorColor1Cum(regNumC) = ...
                time*double(logical(data_c.regs.lyse.errorColor1(regNumC)));
        else
            data_c.regs.lyse.errorColor1Cum(regNumC) = data_r.regs.lyse.errorColor1Cum(regNumR);
        end
        
        if ~data_r.regs.lyse.errorColor2Cum(regNumR)
            data_c.regs.lyse.errorColor2Cum(regNumC) = ...
                time*double(logical(data_c.regs.lyse.errorColor2(regNumC)));
        else
            data_c.regs.lyse.errorColor2Cum(regNumC) = data_r.regs.lyse.errorColor2Cum(regNumR);
        end
        
        if ~data_r.regs.lyse.errorColor1bCum(regNumR)
            data_c.regs.lyse.errorColor1bCum(regNumC) = ...
                time*double(logical(data_c.regs.lyse.errorColor1b(regNumC)));
        else
            data_c.regs.lyse.errorColor1bCum(regNumC) = data_r.regs.lyse.errorColor1bCum(regNumR);
        end
        
        if ~data_r.regs.lyse.errorColor2bCum(regNumR)
            data_c.regs.lyse.errorColor2bCum(regNumC) = ...
                time*double(logical(data_c.regs.lyse.errorColor2b(regNumC)));
        else
            data_c.regs.lyse.errorColor2bCum(regNumC) = data_r.regs.lyse.errorColor2bCum(regNumR);
        end

        if ~data_r.regs.lyse.errorShapeCum(regNumR)
            data_c.regs.lyse.errorShapeCum(regNumC)  = ...
                time*double(logical(data_c.regs.lyse.errorShape(regNumC))); 
        else
            data_c.regs.lyse.errorShapeCum(regNumC) = data_r.regs.lyse.errorShapeCum(regNumR);
        end
    end
end