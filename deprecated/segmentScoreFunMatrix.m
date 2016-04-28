function score = segmentScoreFunMatrix(info, A )
% segmentScoreFun calculates the score of a segment.
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

ss    = size(info);
info_ = [ones(ss(1),1),info]; % adds ones on the top row
score = sum((info_*A).*info_,2);

end