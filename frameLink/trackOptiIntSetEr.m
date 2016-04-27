function trackOptiIntSetEr(fname, CONST, i)
%  trackOptiSetEr: Resets errors flags for the data at fname.
%  Since errors are corrected twice, this resets all the error flags 
%  such that errors are not corrected twice.
% 
%  INPUT :
%        fname : is the filename of the .err file
%        CONST : Constants file
%        i : is the frame
% 
%  Copyright (C) 2016 Wiggins Lab 
%  University of Washington, 2016
%  This file is part of SuperSeggerOpti.
 
data = load(fname);
[data.regs.error.f]  = genError( data.regs.map.f, data.regs.DA.f,  CONST);
[data.regs.error.r]  = genError( data.regs.map.r, data.regs.DA.r,  CONST);
[data.regs.error.rf] = genError( data.regs.map.rf, data.regs.DA.rf, CONST);
[data.regs.error.fr] = genError( data.regs.map.fr, data.regs.DA.fr, CONST);

if i == 1
    data.regs.error.r = 0*data.regs.error.r;
end
    
data.regs.death          = zeros(1,data.regs.num_regs); % Death/divide time
data.regs.deathF         = zeros(1,data.regs.num_regs); % Divides in this frame
data.regs.birth          = zeros(1,data.regs.num_regs); % Birth Time: either division or appearance
data.regs.birthF         = zeros(1,data.regs.num_regs); % Divide in this frame
data.regs.age            = zeros(1,data.regs.num_regs); % cell age. starts at 1.
data.regs.divide         = zeros(1,data.regs.num_regs); % succesful division in this frame.
data.regs.ehist          = zeros(1,data.regs.num_regs); % True if cell has unresolved
% error before this time.
data.regs.stat0          = zeros(1,data.regs.num_regs); % Results from a successful
% division.
data.regs.sisterID       = zeros(1,data.regs.num_regs); % sister cell ID
data.regs.motherID       = zeros(1,data.regs.num_regs); % mother cell ID
data.regs.daughterID     = cell(1,data.regs.num_regs);  % daughter cell ID
data.regs.ID             = zeros(1,data.regs.num_regs); % cell ID number
save(fname,'-STRUCT','data');

end

