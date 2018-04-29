function [imColor, imBW, towerIm, maskCons, nx, ny, max_x, max_y ] = ...
    towerMergeImages( imCell, maskCell, ssCell, xdim, skip, mag, CONST )
% towerMergeImages : merges the towers of several cells.
%
% INPUT :
%       imCell : cell array of individual cell images
%       maskCell : image of tower mask
%       ssCell : width and length of cells
%       xdim : x dimensions for the towers
%       skip : skip frame
%       mag : used to set up the image dimensions
%       CONST : Constants file that was used.
%
% OUTPUT :
%         imColor : rescaled color (jet) consensus image
%         imBW : rescaled bw consesus image
%         towerIm : raw consensus image
%         maskCons : mask for consensus image
%         nx : number of cells in x
%         ny : number of cells in y
%         max_x : max long axis length
%         max_y : max short axis length
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou, Paul Wiggins.
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




if ~exist('skip','var') || isempty (skip)
    skip = 1;
end

colormap_ = jet(256);
max_x = 0;
max_y = 0;


% get number of time slices.
T0 = numel(ssCell);

for ii = 1:T0
    max_x = max([max_x, ssCell{ii}(2)]);
    max_y = max([max_y, ssCell{ii}(1)]);
end


if exist( 'xdim', 'var') && ~isempty(xdim)
    nx = xdim;
    ny = ceil(T0/nx/skip);
else
    nx = ceil(sqrt(T0*max_y/max_x/skip));
    ny = ceil(T0/nx/skip);
end

max_x = max_x+mag;
max_y = max_y+mag;

imdim = [ max_y*ny + mag, max_x*nx + mag ];

maskCons  = zeros(imdim(1), imdim(2));
towerIm   = zeros(imdim(1), imdim(2));

% make the composite image
for ii = 1:T0
    
    yy = floor((ii-1)/nx/skip);
    xx = floor((ii-1)/skip)-yy*nx;
    
    ss = ssCell{ii};
    
    dx = floor((max_x-ss(2))/2);
    dy = floor((max_y-ss(1))/2);
    
    mask = maskCell{ii};
    
    try
        maskCons(1+yy*max_y+(1:ss(1))+dy, 1+xx*max_x+(1:ss(2))+dx) = mask;
        towerIm(1+yy*max_y+(1:ss(1))+dy, 1+xx*max_x+(1:ss(2))+dx) = imCell{ii};
    catch ME
        printError(ME);
        disp( 'Error in towerMergeImages' );
    end
end

% rescale the dynamic range of the image.
f1mm = [min(towerIm( maskCons(:)>.5 )), max( towerIm( maskCons(:)>.5 ))];
imBW = ag(towerIm.*maskCons,0,f1mm(2));

if CONST.view.falseColorFlag
    % make the false color image
    imColor = ag(doColorMap( imBW, colormap_ ));
    mask3   = cat( 3, maskCons, maskCons, maskCons );
    imColor = uint8(uint8( double(imColor).*mask3));
else
    % make normal image
    del = 0.15;
    imColor = cat( 3, ...
        0*maskCons, ...
        uint8(double(imBW).*maskCons), ...
        del*ag(maskCons) );
end
end


