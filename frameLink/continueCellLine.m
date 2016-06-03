function [data_c, data_r] = continueCellLine( data_c, regNumC, data_r,...
    regNumR, time, errorStat)
% continueCellLine : continues a cell line with the same id.
% The cell with region number regNumC in data_c gets the same id as the
% cell with region number regNumR in data_r.
%
% INPUT :
%       data_c : data file (err/seg file) in current frame
%       regNumC : region number in current frame
%       data_r : data file (err/seg file) in reverse frame
%       regNumR : region number in reverse frame
%       time : current time frame
%       errorStat : error flag
%
% OUTPUT :
%       data_c : updated data file (err/seg file
%       data_r : updated data file (err/seg file
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


% set the death/deathF to current time. They are reset when cell is
% visited again.
if ~any (data_c.regs.ID == data_r.regs.ID(regNumR))
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
    
else
    idThief = find(data_c.regs.ID == data_r.regs.ID(regNumR));
    thiefIsCurReg = numel(idThief) == 1 && (idThief==regNumC);
    if ~thiefIsCurReg && data_r.regs.ID(regNumR)~=0
        disp (['FRAME :', num2str(time),' ID PROBLEM WITH ',num2str(regNumC), ' ', num2str(data_r.regs.ID(regNumR))]);
        %keyboard;
    end
end
end