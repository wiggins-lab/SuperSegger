function data = tryDifferentConstants(filename,resFlags, cropRegion, frameNumber)
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




if strcmp(filename(end-3:end), '.tif')
    tempImage = imread(filename);
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
        if ~exist('frameNumber','var') || isempty(frameNumber)
            lastPhaseImage = images(end).name;
        end
        
        lastPhaseImage = images(frameNumber).name;
    end
    tempImage = imread([filename,lastPhaseImage]);  
end

phase = intCropImage (tempImage, cropRegion);  


numFlags = numel(resFlags);
numCols = 3;
numRows = ceil(numFlags / numCols);

for i = 1:numFlags
    res = resFlags{i};
    disp(['Segmenting with ', res]);
    CONST = loadConstantsNN(res, 0);
    CONST.parallel.verbose = 0;
    dataname = 'test';
    data.SegFile {i} = CONST.seg.segFun( phase, CONST, '', dataname, [] ,0);
    data.res{i} = res;
end

figure(1);
close(1);
figure(1);
clf;
ha = tight_subplot(numRows,numCols,[.05 .02],[.05],[.05]);
for i = 1:numFlags
    axes(ha(i));
    showSegDataPhase(data.SegFile{i});
    title( data.res{i})
end


end

function im = intCropImage (im, cropRegion)
imageSize = size(im);

x = cropRegion([1, 2]);
y = cropRegion([3, 4]);

if x(2) > imageSize(2)
    x(2) = imageSize(2);
end

if y(2) > imageSize(1)
    y(2) = imageSize(1);
end

yy = y(1):y(2);
xx = x(1):x(2);

im  = im(yy,xx,:);
end

