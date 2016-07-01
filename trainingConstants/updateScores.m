function updateScores(dirname,xChoice,coefficients,scoreFunction)
% updateScores : updates the raw scores using scoreFunction and coefficients 
% Coefficients are the A or E (can be a neural network) that were created
% during training.
% It saves the loaded data (seg files) at the same location with the new scores.
%
% INPUT : 
%       dirname : directory with seg files 
%       xChoice : 'segs' to load _seg.mat files, anything else loads *_seg*.mat 
%       coefficients : A (segs) or E (regs), coefficients or network
%       scoreFunction : function used to calculate score
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Stylianidou.
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
% 
% You should have received a copy of the GNU General Public License
% along with SuperSegger.  If not, see <http://www.gnu.org/licenses/>.


if ~strcmp (xChoice,'segs') && ~strcmp (xChoice,'regs')
    disp('no x chosen, optimizing segments');
    xChoice = 'segs';
end


if strcmp (xChoice,'segs')
    contents = dir([dirname,'*_seg.mat']);
else
    contents = dir([dirname,'*_seg*.mat']);
end

for i = 1 : numel(contents)
    dataname = [dirname,contents(i).name];
    data = load(dataname);
    if strcmp (xChoice,'segs')
        X = data.segs.info;
        [data.segs.scoreRaw] = scoreFunction (X,coefficients)';
        data.regs.score = ones(data.regs.num_regs,1);
    else
         X = data.regs.info;
        [data.regs.scoreRaw] = scoreFunction (X,coefficients)';
    end
    % save data with updated scores
    save(dataname,'-STRUCT','data');
end
    
end

