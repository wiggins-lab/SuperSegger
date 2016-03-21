function updateScores(dirname,xChoice,coefficients,scoreFunction,linear)
% updates raw scores with the lasso coefficients and saves data

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
        [data.segs.scoreRaw] = scoreFunction (X,coefficients,linear);
        % if you want to update the scores too..
        % data.segs.score = double(data.segs.scoreRaw > 0)
    else
         X = data.regs.info;
        [data.regs.scoreRaw] = scoreFunction (X,coefficients,linear);
    end
        % save data with updated scores
        save(dataname,'-STRUCT','data');
    end
    
end

