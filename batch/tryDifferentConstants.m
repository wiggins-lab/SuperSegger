function tryDifferentConstants(dirname )
% tryDifferentConstants : displays images of cells segmented with
% different constants set in resFlags. It only does the initial
% segmentation (only the doSeg part) and not the regions decisions,
% linking and error resolution that come after.
%
% INPUT :
%       dirname : directory with images
% OUTPUT :
%       data.SegFile: _seg file from segmentation
%            .res: constants resolution for each seg file
%
% Copyright (C) 2016 Wiggins Lab
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.

% modify this accoding to the constants you want to try
resFlags = {'60XEc','60XA','60XEcLB',...
    '60XPa','60XPaM','60XPaM2','60XBthai','100XEc','100XPa'};

if nargin < 1 || isempty( dirname ) || dirname == '.'
    dirname = pwd;
end

dirname = fixDir(dirname);
images = dir([dirname,'*c1*.tif']);
lastPhaseImage = images(end).name;
phase = intCropImage (imread(lastPhaseImage));


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
ha = tight_subplot(numRows,numCols,[.05 .02],[.05],[.05]);
for i = 1:numFlags
    axes(ha(i));
    showSegDataPhase(data.SegFile{i});
    title( data.res{i})
end


end

function im = intCropImage (im)
figure;
imshow(ag(im))
disp('Pick the first corner of the crop region.')
ss = size(im);
corner1 = ginput (1);

hold on; plot (corner1(1) * ones (1,ss(1)),1:ss(1),'r');
hold on; plot (1:ss(2),corner1(2) * ones (1,ss(2)),'r');
disp('Pick the second corners of the crop region.')
corner2 = ginput (1);
x = floor(sort([corner1(1),corner2(1)]));
y = floor(sort([corner1(2),corner2(2)]));

if x(1)<1
    x(1) = 1;
elseif x(2)>ss(2)
    x(2) = ss(2);
end

if y(1)<1
    y(1) = 1;
elseif y(2)>ss(1)
    y(2) = ss(1);
end

yy = y(1):y(2);
xx = x(1):x(2);

clf;
imshow(im(yy,xx,:));
im  = im(yy,xx,:);
end

