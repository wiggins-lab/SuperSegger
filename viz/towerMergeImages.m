function [imColor, imBW, towerIm, maskCons, nx, ny, max_x, max_y ] = ...
    towerMergeImages( imCell, maskCell, ssCell, xdim, skip, mag, CONST )
% towerMergeImages : merges the towers of several cells
%
% INPUT :
%       imCell
%       maskCell
%       ssCell
%       xdim : x dimensions for the towers
%       skip : skip frame
%       mag :
%       CONST : Constants file that was used.
% OUTPUT :
%         mColor
%         imBW
%         towerIm
%         maskCons
%         nx
%         ny
%         max_x
%         max_y
%
% Copyright (C) 2016 Wiggins Lab
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.




skip = 1;


colormap_ = jet(256);

max_x = 0;
max_y = 0;


% get number of time slices.
T0 = numel( ssCell );

for ii = 1:T0
    max_x = max( [max_x, ssCell{ii}(2)] );
    max_y = max( [max_y, ssCell{ii}(1)] );
end


if exist( 'xdim', 'var') && ~isempty( xdim )
    nx = xdim;
    ny = ceil( T0/nx/skip );
else
    nx = ceil( sqrt( T0*max_y/max_x/skip ) );
    ny = ceil( T0/nx/skip );
end

max_x = max_x+mag;
max_y = max_y+mag;

imdim = [ max_y*ny + mag, max_x*nx + mag ];

imColor   = uint8(zeros(imdim(1), imdim(2), 3 ));
imBW      = zeros(imdim(1), imdim(2));
maskCons  = zeros(imdim(1), imdim(2));
towerIm   = zeros(imdim(1), imdim(2));

im_list = [];


% make the composite image
for ii = 1:T0
    
    yy = floor((ii-1)/nx/skip);
    xx = (ii-1)/skip-yy*nx;
    
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
f1mm = [min( towerIm( maskCons(:)>.5 )), max( towerIm( maskCons(:)>.5 ))];
imBW = ag(towerIm.*maskCons,0,f1mm(2));


if CONST.view.falseColorFlag
    % make the false color image
    imColor = ag(doColorMap( imBW, colormap_ ));
    mask3   = cat( 3, maskCons, maskCons, maskCons );
    imColor = uint8(uint8( double(imColor).*mask3));
else
    % make normal image
    del = 0.15;    
    disk1 = strel('disk',1);    
    imColor = cat( 3, ...
        0*maskCons, ...
        uint8(double(imBW).*maskCons), ...
        del*ag(maskCons) );
end

end


