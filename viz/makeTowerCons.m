function  imData = makeTowerCons( data, CONST, xdim, ...
    disp_flag, skip, mag, fnum )
% makeTowerCons : Makes normalized time and shape tower for a single cell.
% It normalizes for time and cell shape.
%
% INPUT:
%        data : (struct) Cell data to construct the Time-Lapse Tower
%       CONST :  segmentation constants
%        xdim : dimensions of image along x axis
%   disp_flag : 0 or 1 value to show imagesa and progess
%        skip : number of frames to be skipped when generating the tower
%         mag : rescale image by mag
%         fnum : flurescence channel to be used
%
% OUPUT:
%       imData
%           .tower : Grayscale masked consensus image for a cell
%           .towerNorm : Normalized grayscale masked consensus image
%           .towerC : Colorized masked cons image of a single cell
%           .towerNormC : Normalized colorized masked cons image of a cell
%           .towerRaw : Raw tower for a single cell, not scaled, or cropper
%           .towerNormRaw : Normalized, not cropped (raw) tower for a cell
%           .towerMask : binary mask of the cell for the tower
%           .fmax : min and max intensity
%           .imCell : cell array of the raw consenus images
%           .imCellNorm : cell array of the raw normalized consenus images
%           .maskCell  : cell array of binary cell masks
%           .intWeight :
%
% Copyright (C) 2016 Wiggins Lab
% Written by Paul Wiggins & Stella Stylianidou.
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


% set the color map here to generate the color images
persistent colormap_;
if isempty( colormap_ )
    colormap_ = colormap( 'jet' );
    %colormap_ = colormap( 'hsv' );
end


% fill unset input arguments
if ~exist('skip','var') || isempty( skip )
    skip = 1;
end

if ~exist('disp_flag', 'var' ) || isempty( disp_flag )
    disp_flag = true;
end

if ~exist( 'xdim', 'var' ) || isempty( xdim )
    xdim = 1;
end

if isfield( CONST, 'view' ) && isfield( CONST.view, 'orientFlag' )
    orientFlag = CONST.view.orientFlag;
else
    orientFlag = true;
end


if  ~isfield(data.CellA{1},'fluor1')
    disp ('no fluorescence field found');
    return;
end

% get the TimeStep variable for plotting
TimeStep     = CONST.getLocusTracks.TimeStep;

% get the number of frames
numframe = numel( data.CellA );
t0 = numframe;


% set the consensus lengths
L0 = 26*mag; % length of the cell in the first frame
W0 =  9*mag; % width of the cells

% T0 is the number of frames in the consensus
if isfield( CONST.view, 'numCons' ) && ~isempty( CONST.view.numCons )
    T0 =  CONST.view.numCons;
else
    T0 =  8;
end

% init variables
imCell = cell( 1, T0 );
ssCell = imCell;
nii   = zeros(1, T0 );
maskCell = imCell;
imCellNorm = cell( 1, T0 );
intWeight = zeros(1, T0 );


f1mm = []; % init the max and min fluor values to empty.
mm_name = ['fluor', num2str(fnum),'mm'];
f_name  = ['fluor', num2str(fnum)];



% figure out the mapping between the different time coords
TT = (0:(T0-1))/(T0-1);
tt = (0:(t0-1))/(t0-1);
Td = abs( (0*tt'+1)*TT-tt'*(0*TT+1));
[~,ord_tt] = min( Td' );
[~,ord_TT] = min( Td );


% straighten and align the cells, frame by frame
for Tii = 1:T0
    
    ind = find( ord_tt == Tii );
    if isempty( ind )
        ind = ord_TT(Tii);
    end
    nii(Tii) = numel( ind );
    
    for ii = row(ind)
        % intDoCellOri: (i) rotate the image, (ii) adjust cell width to W0
        [imCell__, maskCell__, alpha__, ssCell__, xxCell__, yyCell__] = ...
            intDoCellOri( data.CellA{ii}, W0, L0, T0, Tii, mag, fnum );
        
        
        if isempty( imCell{Tii} )
            imCell{Tii}   = imCell__/nii(Tii);
            maskCell{Tii} = maskCell__;
            ssCell{Tii}   = ssCell__;
        else
            imCell{Tii}   = imCell{Tii} + imCell__/nii(Tii);
        end
        
        
        % set the max and min fluor values
        if isempty(f1mm)
            if isfield( data.CellA{ii}, mm_name )
                f1mm = data.CellA{ii}.(mm_name) ;
            else
                tmp_fluor = data.CellA{ii}.(f_name);
                f1mm = [ min(tmp_fluor(:)), max(tmp_fluor(:))];
            end
        else
            if isfield( data.CellA{ii}, mm_name )
                tmp_fluor = data.CellA{ii}.(mm_name) ;
                f1mm = [ min([tmp_fluor,f1mm(1)]), max([tmp_fluor(2),f1mm(2)]) ];
            else
                tmp_fluor = data.CellA{ii}.(f_name);
                f1mm = [ min([f1mm(1),min( tmp_fluor(:))]), max([f1mm(2),max(tmp_fluor(:))])];
            end
        end
    end
    
    
    im    = imCell{Tii};
    mask  = logical(maskCell{Tii});
    
    im = im - min( im( mask ) );
    
    intWeight( Tii ) = sum( double(im(mask)))./sum( double(mask(:)));
    imCellNorm{Tii} = imCell{Tii}/intWeight( Tii ) ;
    
end



% used to calculate scaled images so that they all have dimensions L0, W0, and T0
% [imCell, maskCell, ssCell, xxCell, yyCell, imCellS, maskCellS, ...
%     intWeight, imCellNorm, imCellNormS, intWeightS] = ...
%     intDoRescale( imCell, maskCell, ssCell, xxCell, yyCell, L0, W0, T0 );

% Merge the images from the arrays into a single image
[ imColorCons, imBWCons, towerIm, maskCons, nx, ny, max_x, max_y ] = ...
    towerMergeImages( imCell, maskCell, ssCell, xdim, skip, mag, CONST );

% Merge the normalized images from the arrays into a single image
[ imColorConsNorm, imBWConsNorm, towerImNorm, maskCons, nx, ny, max_x, max_y ] = ...
    towerMergeImages( imCellNorm, maskCell, ssCell, xdim, skip, mag, CONST );

% if the disp flag is true, show the image.
if disp_flag
    intDoDraw( imColorCons, T0, nx, ny, max_x, max_y, TimeStep, CONST );
    pause;
end

imData               = [];
imData.tower         = imBWCons;
imData.towerNorm     = imBWConsNorm;
imData.towerC        = imColorCons;
imData.towerNormC    = imColorConsNorm;
imData.towerRaw      = towerIm;
imData.towerNormRaw  = towerImNorm;
imData.towerMask     = maskCons;
imData.fmax          = f1mm;
imData.imCell        = imCell;
imData.imCellNorm    = imCellNorm;
imData.maskCell      = maskCell;
imData.intWeight     = intWeight;

% .imCellScale   : Grayscale non-crop cons.
% .imCellNormScale : Grayscale normalized non-crop cons.
% .maskCellScale : double binary mask of the cell.
%imData.imCellScale   = imCellScale;
%imData.imCellNormScale  = imCellNormS;
%imData.maskCellScale = maskCellScale;
%imData.intWeightS    = intWeightS;


end



function intDoDraw( im, T0, nx, ny, max_x, max_y, TimeStep, CONST )
% intDoDraw : draws the image.

imshow( im );

if CONST.view.falseColorFlag
    cc = 'w';
else
    cc = 'b';
end

hold on;

for ii = 1:T0
    yy = floor((ii-1)/nx);
    xx = ii-yy*nx-1;
    y = 1+yy*max_y;
    x = 1+xx*max_x;
    text( x+2, y+2, num2str((ii-1)*TimeStep),'Color',cc,'FontSize',12,'VerticalAlignment','Top');
end

dd = [1,ny*max_y+1];
for xx = 1:(nx-1)
    plot( 0*dd + 1+xx*max_x, dd,[':',cc]);
end

dd = [1,nx*max_x+1];
for yy = 1:(ny-1)
    plot( dd, 0*dd + 1+yy*max_y, [':',cc]);
end
end

function [fluor1, mask_rot, alpha, ss, xx, yy] = intDoCellOri( ...
    celld, W0, L0, T0, Tii, mag, fnum )
% intDoCellOri : orients the cell.

f_name = ['fluor',num2str(fnum)];
fl_name = ['fl',num2str(fnum)];
debug_flag = false;
Lii = L0*(1+(Tii-1)/(T0-1));

persistent strel1;
if isempty( strel1 )
    strel1 = strel('square',3);
end

if isfield( celld, 'pole' ) && ~isnan( celld.pole.op_ori ) && (celld.pole.op_ori ~= 0)
    ssign = sign(celld.pole.op_ori);
else
    ssign = 1;
end

e1 = celld.coord.e1;
alpha = 90-180/pi*atan2(e1(1),e1(2)) + 180*double(ssign==1);
mask = celld.mask;

% get the background fluorescence
if isfield( celld, fl_name) && ...
        isfield( getfield( celld, fl_name), 'bg' ) && ...
        ~isnan( getfield( getfield(celld, fl_name), 'bg'))
    bg_fluor =  double( getfield( getfield( celld, fl_name), 'bg' ));
else
    bg_fluor = 0;
end


% check to see if the cell runs up to the end
xx_ = sum( mask, 1);
xx_ = [find(logical(xx_), 1, 'first' ), find(logical(xx_), 1, 'last' )];

yy_ = sum( mask, 2);
yy_ = [find(logical(yy_), 1, 'first' ), find(logical(yy_), 1, 'last' )];

ss_old = size( mask );
fluor1  = double(getfield(celld,f_name))-bg_fluor;

if xx_(1) < 3
    mask   = [ false( [ss_old(1),6] ), mask  ];
    fluor1 = [ zeros( [ss_old(1),6] ), fluor1];
end

ss_old = size( mask );

if xx_(2) > ss_old(2)-2
    mask   = [ mask,   false( [ss_old(1),6] ) ];
    fluor1 = [ fluor1, zeros( [ss_old(1),6] ) ];
end

ss_old = size( mask );

if yy_(1) < 3
    mask   = [ false( [6,ss_old(2)] ); mask  ];
    fluor1 = [ zeros( [6,ss_old(2)] ); fluor1];
end

ss_old = size( mask );

if yy_(2) > ss_old(1)-2
    mask   = [ mask;   false( [6,ss_old(2)] ) ];
    fluor1 = [ fluor1; zeros( [6,ss_old(2)] ) ];
end

mask     = imrotate(       (mask),         alpha, 'bilinear' );
mask = logical(imdilate(mask,strel1));
fluor1   = imrotate( fluor1, alpha, 'bilinear');

% scale the cell to the target size

% compute the local width
w = sum( mask,1 );

w0 = median( w(logical(w)) );
l0 = find( logical(w), 1, 'last' )-find( logical(w), 1, 'first' )+1;

% magnify length and width independently to bring cell to approximately the
% right size.
mag_x = Lii/l0;
mag_y = W0/w0;
mag_v = [mag_y,mag_x];
ss_old = size( mask );


mask_rot = imresize( mask,   ss_old.*mag_v );
fluor1   = imresize( fluor1, ss_old.*mag_v );

% redefine width and length
w = sum( mask_rot,1 );
w0 = median( w(logical(w)) );
x0_srt = find( logical(w), 1, 'first' ); % starting x coord
x0_end = find( logical(w), 1, 'last' ); % ending x coord
l0 = x0_end-x0_srt+1; % cell length

ss = size( mask_rot );
x = 1:ss(2);
y = 1:ss(1);

x_mid = 0.5*(x(1)+x(end));
y_mid = 0.5*(y(1)+y(end));

[X,Y] = meshgrid( x, y );

% compute the center of intensity
y_cen0 = sum(mask_rot.*Y)./w;

x0_srt_ = x0_srt+floor(mag/2);
x0_end_ = x0_end-floor(mag/2);
dx0 = x0_end_-x0_srt_;

ranger = floor( dx0*(0:.2:1)+x0_srt_);

y_cen = interp1( ranger, y_cen0(ranger), x, 'linear','extrap' );

% compute the model (theory) width
RADIUS = W0/2;
wt = intCellFit( x, x0_srt-1, x0_end+1, RADIUS );

mask_rot_  = mask_rot;
mask_rot__ = mask_rot;
fluor1_    = fluor1;


if debug_flag
    figure(1);
    clf;
    imshow( mask_rot_, []);
    hold on;
    plot( y_cen, 'r.-' );
end


for ii = x
    dy1 = (y - y_cen(ii));
    dy2 = (y - y_mid);
    
    mask_rot_(:,ii) = 0;
    if wt(ii)~=0
        mask_rot_(abs(dy2)<=wt(ii)/2,ii) = 1;
    end
    
    mask_rot__(:,ii)   = interp1( dy1, double(mask_rot__(:,ii)),   dy2,'nearest','extrap' );
    fluor1_(:,ii)   = interp1( dy1, fluor1(:,ii),   dy2,'nearest','extrap' );
end

if debug_flag
    figure(2);
    clf;
    imshow( fluor1_,[] );
    colormap jet
    
    figure(3);
    clf;
    imshow( mask_rot_,[] );
    colormap jet
    
    figure(4);
    clf;
    imshow( mask_rot__,[] );
    colormap jet
end

w  = sum(mask_rot_);
xmin_ = max([1,find(w>0,1,'first')-1]);
xmax_ = min([ss(2),find(w>0,1, 'last')+1]);

ysum  = sum(mask_rot_');
ymin_ = max([1,find(ysum>0,1,'first')-1]);
ymax_ = min([ss(1),find(ysum>0,1, 'last')+1]);


yy = ymin_-1+(1:(W0+2));
xx = xmin_-1+(1:(Lii+2));


mask_rot = mask_rot_(yy, xx);
fluor1   = fluor1_(yy, xx);

ss = size( mask_rot );

end

function [X] = intDoFit( x, ysum )
% intDoFit : fits to the theoretical shape of the cell

X(1) = find( ysum, 1, 'first');
X(2) = find( ysum, 1, 'last');
X(3) = max( ysum );

X = fminsearch( @intDoFitInt, X );

    function err = intDoFitInt( X )
        y   = intCellFit( x, X(1), X(2), X(3) );
        
        err = sum( (ysum-y).^2 );
    end


if 0
    clf;
    plot( x, ysum, 'y.-');
    hold on;
    plot( x, intCellFit( x, X(1), X(2), X(3) ), 'r.-');
    pause;
end
end

function [imCell__, maskCell__, ssCell__, xxCell__, yyCell__, imCellScale, ...
    maskCellScale, intWeight, imCellNorm__, imCellNormS, intWeightS ] = ...
    intDoRescale( imCell, maskCell, ssCell, xxCell, yyCell, L0, W0, T0 )
% intDoRescale : rescales the cell in both space and time and fixes
% the normalization over time of the tower.


nt = numel( imCell );

% Renormalize the length of the cell to make it L = L0*(1+t/T)
for ii = 1:nt
    tii = (ii-1)/(nt-1);
    ss = size( imCell{ii} );
    
    x = 1:ss(2);
    y = 1:ss(1);
    
    [ X, Y ] = meshgrid( x, y );
    
    xsum  = sum(maskCell{ii});
    
    xcom  = sum(maskCell{ii}(:).*X(:))/sum(maskCell{ii}(:));
    ycom  = sum(maskCell{ii}(:).*Y(:))/sum(maskCell{ii}(:));
    
    xi = (1:(2*L0+4))-(2*L0+4-1)/2;
    yi = (1:(W0+4))-(W0+4-1)/2;
    
    [Xi,Yi] = meshgrid( xi, yi );
    
    xmin_ = max([1,find(xsum>1,1,'first')-1]);
    xmax_ = min([ssCell{ii}(2),find(xsum>1,1, 'last')+1]);
    dx = xmax_ - xmin_ + 1;
    
    imCell_{ii}   = interp2( (X-xcom)/dx*2*L0, Y-ycom,   imCell{ii}, Xi-1, Yi-1);
    maskCell_{ii} = interp2( (X-xcom)/dx*2*L0, Y-ycom, double(maskCell{ii}), Xi-1, Yi-1);
    
end

%  Renormalize the length of the cell cycle to be length T0.
for ii = 1:T0
    
    jj = (ii-1)/(T0-1)*(nt-1)+1;
    
    jjm = floor(jj);
    jjp = jjm + 1;
    djj = jj-jjm;
    
    if ii == 1
        imCell__{ii} = imCell_{ii};
        maskCell__{ii} = maskCell_{ii};
    elseif ii == T0
        imCell__{ii} = imCell_{end};
        maskCell__{ii} = maskCell_{end};
    else
        imCell__{ii} = (1-djj)*imCell_{jjm} + djj*imCell_{jjp};
        maskCell__{ii} = (1-djj)*maskCell_{jjm} + djj*maskCell_{jjp};
    end
    
end

% save the scaled versions
imCellScale   = imCell__;
imCellNormS   = imCell__;

maskCellScale = maskCell__;
intWeight = zeros(1,T0);
intWeightS = zeros(1,T0);

imCellNorm__ =  imCell__;

% rescale the long axis dimension to scale uniformly
for ii = 1:T0
    tii = (ii-1)/(T0-1);
    Lii = L0*(1+tii);
    
    xi = (1:(2*L0+4))-(2*L0+4-1)/2;
    yi = (1:(W0+4))-(W0+4-1)/2;
    
    [Xi,Yi] = meshgrid( xi, yi );
    
    imCell__{ii}   = interp2(  (Xi-1), Yi-1,   imCell__{ii}, (Xi-1)*(2*L0)/Lii, Yi-1);
    maskCell__{ii} = interp2(  (Xi-1), Yi-1, maskCell__{ii}, (Xi-1)*(2*L0)/Lii, Yi-1);
    
    imCell__{ii}(isnan(imCell__{ii}))     = 0;
    maskCell__{ii}(isnan(maskCell__{ii})) = 0;
    
    % normalizes fluor so that the mean fluor remains constant over time.
    % the abs value does not allow the sum to diverge. The sum can become 0
    % due to illumination non-unifority and real life, causing problems later.
    sum_ = sum(abs(imCell__{ii}(:)).*maskCell__{ii}(:))/sum(maskCell__{ii}(:));
    imCellNorm__{ii} = imCell__{ii}/sum_;
    intWeight(ii) = sum_;
    
    % normalize fluor so that the mean fluor remains constant over time.
    imCellScale{ii}(isnan(imCellScale{ii}))      = 0;
    maskCellScale{ii}(isnan(maskCellScale{ii}))  = 0;
    
    sumS_ = sum(imCellScale{ii}(:).*maskCellScale{ii}(:))/sum(maskCellScale{ii}(:));
    imCellNormS{ii} = imCellScale{ii}/sumS_;
    intWeightS(ii) = sumS_;
    ssCell__{ii} = size( imCell__{ii} );
    xxCell__{ii} = 1:ssCell__{ii}(2);
    yyCell__{ii} = 1:ssCell__{ii}(1);
    
end
end



