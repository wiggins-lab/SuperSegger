function [data_c,cell_count] = createNewCell (data_c, regNum, time, cell_count)
% createNewCell : creates a new cell for regNum with region id cell_count + 1
%
% INPUT :
%       data_c : data file (err/seg file) in current frame
%       regNumC : region number in current frame
%       time : current time frame
%       cell_count : last cell id used
%
% OUTPUT :
%       data_c : updated data file (err/seg file).
%       cell_count : last cell id used.
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



cell_count = cell_count+1;

% set the death/deathF to current time. They are reset when cell is
% visited again.
data_c.regs.death(regNum) = time; % Death/divide time
data_c.regs.deathF(regNum) = 1;    % Divides in this frame
data_c.regs.birth(regNum) = time; % Birth T: either division or appearance
data_c.regs.birthF(regNum) = 1;    % Divide in this frame
data_c.regs.age(regNum) = 1;    % cell age. starts at 1.
data_c.regs.divide(regNum) = 0;    % succesful divide in this this frame.
data_c.regs.ehist(regNum) = 0;    % 1 if cell had unresolved error before this time.
data_c.regs.stat0(regNum) = 0;    % Results from a successful division.
data_c.regs.sisterID(regNum) = 0; % sister cell ID
data_c.regs.motherID(regNum) = 0; % mother cell ID
data_c.regs.daughterID{regNum} = []; % daughter cell ID
data_c.regs.ID(regNum) = cell_count; % cell ID number
data_c.regs.ID_{regNum} = cell_count; % cell ID_ can hold a vector - can be resolved later

if isfield( data_c.regs, 'lyse' )
    data_c.regs.lyse.errorColor1Cum(regNum) = time*double(logical(data_c.regs.lyse.errorColor1(regNum)));
    data_c.regs.lyse.errorColor2Cum(regNum) = time*double(logical(data_c.regs.lyse.errorColor2(regNum)));
    data_c.regs.lyse.errorColor1bCum(regNum) = time*double(logical(data_c.regs.lyse.errorColor1b(regNum)));
    data_c.regs.lyse.errorColor2bCum(regNum) = time*double(logical(data_c.regs.lyse.errorColor2b(regNum)));
    data_c.regs.lyse.errorShapeCum(regNum)  = time*double(logical(data_c.regs.lyse.errorShape(regNum)));
end


end