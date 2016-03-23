function updateScores(dirname,xChoice,coefficients,scoreFunction,linear)
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
%       linear : 1 to use only linear relationships for the parameters
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


if ~strcmp (xChoice,'segs') && ~strcmp (xChoice,'regs')
    disp('no x chosen, optimizing segments');
    xChoice = 'segs';
end

if ~exist('linear','var') || isempty(linear)
    linear = false;
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
        data.segs.scoreRaw = scoreFunction (X,coefficients);
        % if you want to update the scores too..
        % data.segs.score = double(data.segs.scoreRaw > 0)
    else
         X = data.regs.info;
        [data.regs.scoreRaw] = scoreFunction (X,coefficients);
    end
        % save data with updated scores
        save(dataname,'-STRUCT','data');
    end
    
end

