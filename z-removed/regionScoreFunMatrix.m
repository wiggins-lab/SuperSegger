function score = regionScoreFunMatrix( info, E)
% regionScoreFunMatrix : calculates the score of regions
%
% INPUT : 
%       info : has information about the segment (look at superSeggerOpti for
%       more info)
%       E : scoring vector optimized for different cells and imaging conditions
% OUTPUT :
%       score : segment score 
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

ss    = size(info);
info_ = [ones(ss(1),1),info];
score = sum((info_*E).*info_,2) - (info(:,4)/15).^4;

end