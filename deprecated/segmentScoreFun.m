function [scoreRaw] = segmentScoreFun(info, A )
% segmentScoreFun calls a function to calculates the score of the segment. 
% to determine if the segment will be included.
%
% INPUT : 
%       info : has information about the segment (look at superSeggerOpti for
%       more info)
%       A : scoring segment vector optimized for different cells 
%       and imaging conditions
% OUTPUT :
%       score : segment score, a score below 0 is set off.
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

scoreRaw = segmentScoreFunMatrix(info,A);
%score =  double( 0 < scoreRaw);

end