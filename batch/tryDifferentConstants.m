function [data] = tryDifferentConstants( pathPhaseImage )
% tryDifferentConstants : displays images of cells segmented with
% different constants set in resFlags. It only does the initial
% segmentation (only the doSeg part) and not the regions decisions,
% linking and error resolution that come after.
%
% INPUT : pathPhaseImage : path to phase image you would like to segment
% OUTPUT :
%       data.SegFile: _seg file from segmentation
%            .res: constants resolution for each seg file
%
% Copyright (C) 2016 Wiggins Lab
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.

phase = imread(pathPhaseImage);

resFlags = {'100XPa','60XEc','100XEc','60XPa','60XA',...
    '60XEcLB','60XPaM','60XPaM2','60XBthai'};

numFlags = numel(resFlags);
numCols = 3;
numRows = ceil(numFlags / numCols);

for i = 1:numFlags
    res = resFlags(i);
    disp(['trying ', res]);
    CONST = loadConstants( res{1}, 0 );
    dataname = 'test';
    data.SegFile {i} = CONST.seg.segFun( phase, CONST, 'TryingConstants : ', dataname, [] );
    data.res{i} = res{1};  
end

figure(5);
clf;
ha = tight_subplot(numRows,numCols,[.03 .01],[.1 .1],[.01 .01]);
for i = 1:numFlags    
    %subplot(numRows,numCols,i);
    axes(ha(i));
    showSegDataPhase(data.SegFile{i});
    title( data.res{i})
end


end

