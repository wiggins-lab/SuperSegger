function score = regionScoreFun0( info, E)
% regionScoreFun0 : calculates the score of regions match to cellprops0
% The score is calculated as :
%  ((first element of A)  + info*A).*info
% and then sum of that.
%
% INPUT : 
%   info : has information about the segment (look at superSeggerOpti for
%   more info
%   A : scoring vector optimized for different cells and imaging conditions
% OUTPUT :
%  score : segments score, a score below zero is set off.
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

L1            = double(info(:,1)==0)+info(:,1);
L2max         = info(:,2);
Lneck         = double(info(:,3)==0)+info(:,3);
L2mean        = info(:,4);
stm           = info(:,5);
RoundIndOver  = info(:,6); 
RoundIndUnder = info(:,7);
A             = info(:,8)/300;

epp = (L2mean./Lneck-1);
vvv = (L2max-L2mean);
RI  = RoundIndOver + RoundIndUnder;


score = E(1) + ...
        E(3)*(abs(E(2)-L2mean)).^E(4) + ...
        E(7)./L1 + E(8).*L1  + E(9).*L1.^2 + ...
        E(10).*epp + E(11).*epp.^2 + ...
        E(12).*stm + E(13).*stm.^2 + ...
        E(14).*RI  + E(15).*RI.^2 + ...
        0*E(16).*vvv + 0*E(17).*vvv.^2;  

end