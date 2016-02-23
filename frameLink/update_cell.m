function  [data_c, data_r, cell_count] = update_cell( ...
    data_c, ii, data_r, jj, time, errorStat, ii_sister, cell_count);
% update_cell : updates the data structures
%
% INPUT :
%       data_c   : region (cell) data structure
%       ii      :
%       data_r  : linked reverse region (cell) data structure
%       jj      :      
%       time :
%       errorStat :
%       ii_sister :
%       cell_count :
%

% if jj is empty this is a new cell
if isempty(jj)
    cell_count = cell_count+1;
    
    % set the death/deathF to current time. If we come back,
    % we will reset them!
    data_c.regs.death(ii)      = time; % Death/divide time
    data_c.regs.deathF(ii)     = 1;    % Divides in this frame
    
    data_c.regs.birth(ii)      = time; % Birth Time: either
    % Division or appearance
    data_c.regs.birthF(ii)     = 1;    % Divide in this frame
    
    data_c.regs.age(ii)        = 1;    % cell age. starts at 1.
    data_c.regs.divide(ii)     = 0;    % succesful divide in this
    % this frame.
    
    data_c.regs.ehist(ii)      = 0;    % True if cell has an unresolved
    % error before this time.
    data_c.regs.stat0(ii)      = 0;    % Results from a successful
    % division.
    
    if isfield( data_c.regs, 'lyse' )
        data_c.regs.lyse.errorColor1Cum(ii) = time*double(logical(data_c.regs.lyse.errorColor1(ii)));    
        data_c.regs.lyse.errorColor2Cum(ii) = time*double(logical(data_c.regs.lyse.errorColor2(ii)));

        data_c.regs.lyse.errorColor1bCum(ii) = time*double(logical(data_c.regs.lyse.errorColor1b(ii)));    
        data_c.regs.lyse.errorColor2bCum(ii) = time*double(logical(data_c.regs.lyse.errorColor2b(ii)));

        data_c.regs.lyse.errorShapeCum(ii)  = time*double(logical(data_c.regs.lyse.errorShape(ii))); 
    end
    
    data_c.regs.sisterID(ii)   = 0;   % sister cell ID
    data_c.regs.motherID(ii)   = 0;   % mother cell ID
    data_c.regs.daughterID{ii} = [];   % daughter cell ID
    data_c.regs.ID(ii)         = cell_count; % cell ID number
    data_c.regs.ID_{ii}        = cell_count; % cell ID number.
    % this can hold a vector
    % can be resolved later
    
elseif ii_sister;
    ii_sister = ii_sister(1);
    
    if ~data_c.regs.sisterID(ii)
        
        cell_count = cell_count+1;
        
        % set the death/deathF to current time. If we come back,
        % we will reset them!
        data_c.regs.death(ii)      = time; % Death/divide time
        data_c.regs.deathF(ii)     = 1;    % Divides in this frame
        
        data_c.regs.birth(ii)      = time; % Birth Time: either
        % Division or appearance
        data_c.regs.birthF(ii)     = 1;    % Divide in this frame
        
        data_c.regs.age(ii)        = 1;    % cell age. starts at 1.
        data_c.regs.divide(ii)     = 0;    % succesful divide in this
        % this frame.
        
        data_c.regs.ehist(ii)      = errorStat;    % True if cell has an unresolved
        % error before this time.
        
        data_c.regs.stat0(ii)      = ~errorStat;    % Results from a successful
        % division.
        
        
        if isfield( data_c.regs, 'lyse' )
            data_c.regs.lyse.errorColor1Cum(ii_sister) = ...
                time*double(logical(data_c.regs.lyse.errorColor1(ii_sister)));    
            data_c.regs.lyse.errorColor2Cum(ii_sister) = ...
                time*double(logical(data_c.regs.lyse.errorColor2(ii_sister)));
            data_c.regs.lyse.errorShapeCum(ii_sister)  = ...
                time*double(logical(data_c.regs.lyse.errorShape(ii_sister))); 
            
            data_c.regs.lyse.errorColor1Cum(ii) = ... 
                time*double(logical(data_c.regs.lyse.errorColor1(ii)));    
            data_c.regs.lyse.errorColor2Cum(ii) = ... 
                time*double(logical(data_c.regs.lyse.errorColor2(ii)));
            data_c.regs.lyse.errorShapeCum(ii)  = ... 
                time*double(logical(data_c.regs.lyse.errorShape(ii))); 

            data_c.regs.lyse.errorColor1bCum(ii_sister) = ...
                time*double(logical(data_c.regs.lyse.errorColor1b(ii_sister)));    
            data_c.regs.lyse.errorColor2bCum(ii_sister) = ...
                time*double(logical(data_c.regs.lyse.errorColor2b(ii_sister)));
                        
            data_c.regs.lyse.errorColor1bCum(ii) = ... 
                time*double(logical(data_c.regs.lyse.errorColor1b(ii)));    
            data_c.regs.lyse.errorColor2bCum(ii) = ... 
                time*double(logical(data_c.regs.lyse.errorColor2b(ii)));
            

        end
        
        data_c.regs.sisterID(ii)   = cell_count+1;   % sister cell ID
        data_c.regs.motherID(ii)   = data_r.regs.ID(jj);   % mother cell ID
        data_c.regs.daughterID{ii} = [];   % daughter cell ID
        data_c.regs.ID(ii)         = cell_count; % cell ID number
        data_c.regs.ID_{ii}        = cell_count; % cell ID number.
        % this can hold a vector
        % can be resolved later

        cell_count = cell_count+1;
        
        % set the death/deathF to current time. If we come back,
        % we will reset them!
        data_c.regs.death(ii_sister)      = time; % Death/divide time
        data_c.regs.deathF(ii_sister)     = 1;    % Divides in this frame
        
        data_c.regs.birth(ii_sister)      = time; % Birth Time: either
        % Division or appearance
        data_c.regs.birthF(ii_sister)     = 1;    % Divide in this frame
        
        data_c.regs.age(ii_sister)        = 1;    % cell age. starts at 1.
        data_c.regs.divide(ii_sister)     = 0;    % succesful divide in this
        % this frame.
        
        data_c.regs.ehist(ii_sister)      = errorStat;    % True if cell has an unresolved
        % error before this time.
        
        data_c.regs.stat0(ii_sister)      = ~errorStat;    % Results from a successful
        % division.
        
        data_c.regs.sisterID(ii_sister)   = cell_count-1;   % sister cell ID
        data_c.regs.motherID(ii_sister)   = data_r.regs.ID(jj);   % mother cell ID
        data_c.regs.daughterID{ii_sister} = [];   % daughter cell ID
        data_c.regs.ID(ii_sister)         = cell_count; % cell ID number
        data_c.regs.ID_{ii_sister}        = cell_count; % cell ID number.
        % this can hold a vector
        % can be resolved later
        
        % set the death/deathF to current time. If we come back,
        % we will reset them!
        data_r.regs.divide(jj)     = ~errorStat;    % succesful divide in this
        data_r.regs.daughterID{jj} = [cell_count-1,cell_count];   % daughter cell ID
        
    end
else
    % set the death/deathF to current time. If we come back,
    % we will reset them!
    data_c.regs.death(ii)      = time; % Death/divide time
    data_c.regs.deathF(ii)     = 1;    % Divides in this frame
    
    data_c.regs.birth(ii)      = data_r.regs.birth(jj); % Birth Time: either
    % Division or appearance
    data_c.regs.birthF(ii)     = 0;    % Divide in this frame
    
    data_c.regs.age(ii)        = data_r.regs.age(jj)+1;    % cell age. starts at 1.
    data_c.regs.divide(ii)     = 0;    % succesful divide in this
    % this frame.
    
    
    data_c.regs.contactHist(ii) = data_r.regs.contactHist(jj) || data_c.regs.contact(ii);
    data_c.regs.ehist(ii)       = data_r.regs.ehist(jj) || errorStat;    % True if cell has an unresolved
    % error before this time.
    
   if isfield( data_c.regs, 'lyse' )
        if ~data_r.regs.lyse.errorColor1Cum(jj)
            data_c.regs.lyse.errorColor1Cum(ii) = ...
                time*double(logical(data_c.regs.lyse.errorColor1(ii)));
        else
            data_c.regs.lyse.errorColor1Cum(ii) = data_r.regs.lyse.errorColor1Cum(jj);
        end
        
        if ~data_r.regs.lyse.errorColor2Cum(jj)
            data_c.regs.lyse.errorColor2Cum(ii) = ...
                time*double(logical(data_c.regs.lyse.errorColor2(ii)));
        else
            data_c.regs.lyse.errorColor2Cum(ii) = data_r.regs.lyse.errorColor2Cum(jj);
        end
        
        if ~data_r.regs.lyse.errorColor1bCum(jj)
            data_c.regs.lyse.errorColor1bCum(ii) = ...
                time*double(logical(data_c.regs.lyse.errorColor1b(ii)));
        else
            data_c.regs.lyse.errorColor1bCum(ii) = data_r.regs.lyse.errorColor1bCum(jj);
        end
        
        if ~data_r.regs.lyse.errorColor2bCum(jj)
            data_c.regs.lyse.errorColor2bCum(ii) = ...
                time*double(logical(data_c.regs.lyse.errorColor2b(ii)));
        else
            data_c.regs.lyse.errorColor2bCum(ii) = data_r.regs.lyse.errorColor2bCum(jj);
        end

        if ~data_r.regs.lyse.errorShapeCum(jj)
            data_c.regs.lyse.errorShapeCum(ii)  = ...
                time*double(logical(data_c.regs.lyse.errorShape(ii))); 
        else
            data_c.regs.lyse.errorShapeCum(ii) = data_r.regs.lyse.errorShapeCum(jj);
        end
        
    end
       
    data_c.regs.stat0(ii)      = data_r.regs.stat0(jj);    % Results from a successful
    % division.    
    data_c.regs.sisterID(ii)   = data_r.regs.sisterID(jj);   % sister cell ID
    data_c.regs.motherID(ii)   = data_r.regs.motherID(jj);   % mother cell ID
    data_c.regs.daughterID{ii} = [];   % daughter cell ID
    data_c.regs.ID(ii)         = data_r.regs.ID(jj); % cell ID number
    
    % this can hold a vector can be resolved later 
    % set the death/deathF to current time. If we come back,
    % we will reset them!
    data_r.regs.death(jj)      = time; % Death/divide time
    data_r.regs.deathF(jj)     = 0;    % Divides in this frame   
    data_r.regs.divide(jj)     = 0;    % succesful divide in this
end
end
