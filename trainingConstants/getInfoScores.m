function [X,Y] =  getInfoScores (dirname,xChoice)
% gathers all x and y to be used for logistic regression
%  xChoice : 'segs' or 'regs'

dirname = fixDir(dirname);
if ~strcmp (xChoice,'segs') && ~strcmp (xChoice,'regs')
    disp('no x chosen, optimizing segments');
    xChoice = 'segs';
end
if strcmp (xChoice,'segs')
    contents = dir([dirname,'*_seg.mat']);
else
    contents = dir([dirname,'*_seg*.mat']);
end
Y = [];
X = [];


for i = 1 : numel(contents)
    data = load([dirname,contents(i).name]);
    if strcmp (xChoice,'segs')
        Y = [Y;data.segs.score];
        X = [X;data.segs.info];
    else
        Y = [Y;data.regs.score];
        X = [X;data.regs.info];
    end
    
end

[indices] = find(~isnan(Y));
X = X(indices,:);
Y = Y(indices);

[indices] = find(isfinite(sum(X,2)));
X = X(indices,:);
Y = Y(indices);

end
