function updateScores(dirname,xChoice,coefficients)
% updates scores wiht new coefficients and saves data

if ~strcmp (xChoice,'segs') && ~strcmp (xChoice,'regs')
    disp('no x chosen, optimizing segments');
    xChoice = 'segs';
end
contents = dir([dirname,'*_seg.mat']);


for i = 1 : numel(contents)
    dataname = [dirname,contents(i).name];
    data = load(dataname);
    if strcmp (xChoice,'segs')
         X = data.segs.info;
    else
        X = data.regs.info;
    end
    [data.segs.score,data.segs.scoreRaw] = calculateLassoScores (X,coefficients);
    
     % save data with updated scores
     save(dataname,'-STRUCT','data');
end

end