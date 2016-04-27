function [X,Y] =  getInfoScores (dirname, xChoice, CONST)
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
       
        if exist('CONST','var')
            newInfo = calculateInfo (data);
            X = [X;newInfo];
        else
             X = [X;data.regs.info];
        end
    end
    
end

[indices] = find(~isnan(Y));
X = X(indices,:);
Y = Y(indices);

[indices] = find(isfinite(sum(X,2)));
X = X(indices,:);
Y = Y(indices);


function newInfo = calculateInfo (data)
    
%NUM_INFO = CONST.regionScoreFun.NUM_INFO;
ss = size( data.mask_cell );
data.regs.info = [];
for ii = 1:data.regs.num_regs 
    [xx,yy] = getBBpad( data.regs.props(ii).BoundingBox, ss, 1);
    mask = data.regs.regs_label(yy,xx)==ii;
    data.regs.info(ii,:) = CONST.regionScoreFun.props( mask, data.regs.props(ii) );
end
  
newInfo = data.regs.info;
end

end


