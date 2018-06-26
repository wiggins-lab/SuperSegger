function data = tryDifferentConstants(filename,resFlags)
% tryDifferentConstants : displays images of cells segmented with
% different constants set in resFlags. It only does the initial
% segmentation (only the doSeg part) and not the regions decisions,
% linking and error resolution that come after.
% Images need to have the right naming convention - if they don't use
% renameImages before this script.
%
% INPUT :
%       dirname : directory with images or filename of image (must be .tif)
% OUTPUT :
%       data.SegFile: _seg file from segmentation
%            .res: constants resolution for each seg file
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou
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

% modify this accoding to the constants you want to try
if nargin < 1 || isempty( filename ) || strcmp(filename,'.')
    filename = pwd;
end

if ~exist('resFlags','var') || isempty(resFlags)
    [~,resFlags] = getConstantsList();
end

% imfinfo()

if strcmp(filename(end-3:end), '.tif')
    tempImage = intImRead(filename);
else % it is a folder
    filename = fixDir(filename);
    images = dir([filename,'*c1*.tif']);
    if isempty (images)
        disp('no images found in the directory with c1.tif.Select an image');
        [lastPhaseImage,filename , ~] = uigetfile('*.tif', 'Pick an image file');
        if lastPhaseImage == 0
            return;
        end
    else
        lastPhaseImage = images(end).name;
    end
    tempImage = intImRead([filename,lastPhaseImage]);  
end

phase = intCropImage (tempImage);  


numFlags = numel(resFlags);
numCols = 3;
numRows = ceil(numFlags / numCols);

for i = 1:numFlags
    res = resFlags{i};
    disp(['Segmenting with ', res]);
    CONST = loadConstants(res, 0);
    CONST.parallel.verbose = 0;
    dataname = 'test';
    data.SegFile {i} = CONST.seg.segFun( phase, CONST, '', dataname, []);
    data.res{i} = res;
end
figure(5);
close(5);
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
disp('Pick the second corner of the crop region.')
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

