%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% function makeTowerCons
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Paul Wiggins, University of Washington, written 2011
%                                         Modified 2012/02/12
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DESCRIPTION:
%
% Make Times-Lapse Tower with normaled time and cell shape
%
% INPUT ARGUMENTS:
%        data : (struct) Cell data to construct the Time-Lapse Tower
%       CONST : (struct) Constant variable
%        xdim : 
%   disp_flag : (flag) flag to tell the code whether to show progress
%        skip : (int) skip every skip files when generating the tower 
%         mag : (double) rescale image by mag
%
% OUPUT VARIABLES:
%       imColorCons: (im tower) Colorized cropped cons image of a single cell
%         imBWCons : (im tower) Grayscale non-crop cons image for a single cell
%         maskCons : (im tower) double 0-1 mask of the cell.
%             f1mm : [min intensity, max intensity]
%
%           imCell : Grayscale non-crop cons. (Cell array of ims)
%         maskCell : double 0-1 mask of the cell. (Cell array of masks)
%
% Scaled Long Axis Images, Cell Array of time points:
%          imCellS : (Scaled) Grayscale non-crop cons. (Cell array of ims)
%        maskCellS : (Scaled) double 0-1 mask of the cell. (Cell array of masks)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  imData = makeTowerCons( data, CONST, xdim, ...
    disp_flag, skip, mag, fnum )


del = 0.0;


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
    % do something to set xdim
end

if isfield( CONST, 'view' ) && isfield( CONST.view, 'orientFlag' )
    orientFlag = CONST.view.orientFlag;
else
    orientFlag = true;
end


% get the TimeStep variable for plotting
TimeStep     = CONST.getLocusTracks.TimeStep;

% get the number of frames
numframe = numel( data.CellA );

% init variables
imCell = cell( 1, numel(data.CellA) );
alpha  = zeros(1, numel(data.CellA) );
ssCell = imCell;
xxCell = imCell;
yyCell = imCell;


% set the consensus lengths


% L0 is the length of the cell in the first frame
L0 = 26*mag;

% W0 is the width of the cells
W0 =  9*mag;

% T0 is the number of frames in the consensus 
if isfield( CONST.view, 'numCons' ) && ~isempty( CONST.view.numCons )
    T0 =  CONST.view.numCons;
else
    T0 =  8;
end


% init the max and min fluor values to empty.
f1mm = [];

mm_name = ['fluor', num2str(fnum),'mm'];
f_name  = ['fluor', num2str(fnum)];


% straighten and align the cells, frame by frame
for ii = 1:numframe
    
    % intDoCellOri: (i) rotate the image, (ii) adjust cell width to W0
    [imCell{ii}, maskCell{ii}, alpha(ii), ssCell{ii}, xxCell{ii}, yyCell{ii}] = ...
        intDoCellOri( data.CellA{ii}, W0, mag, fnum );
       
    % set the max and min fluor values
    if isempty(f1mm)
        if isfield( data.CellA{ii}, mm_name )
            
            f1mm = getfield( data.CellA{ii}, mm_name) ;
        else
            tmp_fluor = getfield( data.CellA{ii}, f_name );
            
            f1mm = [ min( ...
                tmp_fluor(:)), max(tmp_fluor(:))];
        end
    else
        if isfield( data.CellA{ii}, mm_name )
            tmp_fluor = getfield( data.CellA{ii}, mm_name );
            
            f1mm = [ min([tmp_fluor,f1mm(1)]), max([tmp_fluor(2),f1mm(2)]) ];
        else
           tmp_fluor = getfield( data.CellA{ii}, f_name );

            
            f1mm = [ min([f1mm(1),min( tmp_fluor(:))]), max([f1mm(2),max(tmp_fluor(:))])];
        end
    end
end


% rescale the time steps so that they have dimensions L0, W0, and T0
[imCell, maskCell, ssCell, xxCell, yyCell, imCellS, maskCellS, ...
    intWeight, imCellNorm, imCellNormS, intWeightS] = ...
    intDoRescale( imCell, maskCell, ssCell, xxCell, yyCell, L0, W0, T0 );

% Merge the images from the arrays into a single image
[ imColorCons, imBWCons, towerIm, maskCons, nx, ny, max_x, max_y ] = ...
    towerMergeImages( imCell, maskCell, ssCell, xdim, skip, mag, CONST );

% Merge the images from the arrays into a single image
[ imColorConsNorm, imBWConsNorm, towerImNorm, maskCons, nx, ny, max_x, max_y ] = ...
    towerMergeImages( imCellNorm, maskCell, ssCell, xdim, skip, mag, CONST );

% if the disp flag is true, show the image.
if disp_flag
    intDoDraw( imColorCons, T0, nx, ny, max_x, max_y, TimeStep, CONST );
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
imData.imCellScale   = imCellS;
imData.imCellNormScale  = imCellNormS;
imData.maskCellScale = maskCellS;

imData.intWeight     = intWeight;
imData.intWeightS    = intWeightS;


end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intDoDraw
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function intDoDraw( im, T0, nx, ny, max_x, max_y, TimeStep, CONST )

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% do cell orientation
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [fluor1, mask_rot, alpha, ss, xx, yy] = intDoCellOri( celld, W0, mag, fnum )

f_name = ['fluor',num2str(fnum)];
fl_name = ['fl',num2str(fnum)];



persistent strel1;
if isempty( strel1 )
    strel1 = strel('square',3);
end


if isfield( celld, 'pole' ) && ~isnan( celld.pole.op_ori ) && (celld.pole.op_ori ~= 0)
    ssign = sign(celld.pole.op_ori);
else
    ssign = 1;
end

%ssign

e1 = celld.coord.e1;
alpha = 90-180/pi*atan2(e1(1),e1(2)) + 180*double(ssign==1);

mask = celld.mask;

mask     = imrotate(       (mask),         alpha, 'bilinear' );
mask = logical(imdilate(mask,strel1));

if isfield( celld, fl_name) && ...
   isfield( getfield( celld, fl_name), 'bg' ) && ...
   ~isnan( getfield( getfield(celld, fl_name), 'bg'))
    bg_fluor =  double( getfield( getfield( celld, fl_name), 'bg' ));
else
    bg_fluor = 0;
end

fluor1   = imrotate( double(getfield(celld,f_name))-bg_fluor, alpha, 'bilinear');

mask_rot = imresize( mask,   mag );



fluor1   = imresize( fluor1, mag );

sstmp = size( mask_rot );

x = 1:sstmp(2);
y = 1:sstmp(1);

x2 = 0.5*(x(1)+x(end));
y2 = 0.5*(y(1)+y(end));

[X,Y] = meshgrid( x, y );

xsum  = sum(mask_rot);
xsumy = sum(mask_rot.*Y)./xsum;

%yshift = xsumy - y2;
%yshift(isnan(yshift)) = 0;

ind = isnan(xsumy);
xsumy(ind) = y2;

mask_rot_ = mask_rot;
fluor1_   = fluor1;
%for ii = x
%    mask_rot_(:,ii) = interp1( y, mask_rot(:,ii), yshift(ii) + y,'linear','extrap' );
%    fluor1_(:,ii)   = interp1( y, fluor1(:,ii),   yshift(ii) + y,'linear','extrap' );
%end

XXX = intDoFit( x, xsum );

RADIUS = W0/2;
xsumt = intCellFit( x, XXX(1), XXX(2), RADIUS );

for ii = x
    if (xsumt(ii)>0) && (xsum(ii)>0)
        dy1 = (y - xsumy(ii))*xsumt(ii)/xsum(ii);
        dy2 = (y - y2);
        
        mask_rot_(:,ii) = interp1( dy1, double(mask_rot(:,ii)), dy2,'linear','extrap' );
        fluor1_(:,ii)   = interp1( dy1, fluor1(:,ii),   dy2,'linear','extrap' );
    else
        mask_rot_(:,ii) = 0*mask_rot(:,ii);
        fluor1_(:,ii)   = fluor1(:,ii);
    end
end


xsum  = sum(mask_rot_);
xmin_ = max([1,find(xsum>0,1,'first')-1]);
xmax_ = min([sstmp(2),find(xsum>0,1, 'last')+1]);

ysum  = sum(mask_rot_');
ymin_ = max([1,find(ysum>0,1,'first')-1]);
ymax_ = min([sstmp(1),find(ysum>0,1, 'last')+1]);


yy = ymin_:ymax_;
xx = xmin_:xmax_;


mask_rot = mask_rot_( ymin_:ymax_, xmin_:xmax_ );
fluor1   = fluor1_(yy, xx);

ss = size( mask_rot );

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% do the fit to the theoretical shape of the cell
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [X] = intDoFit( x, ysum )

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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% do rescale of cell in both space and time and fixes the normalization
% over time of the tower.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [imCell__, maskCell__, ssCell__, xxCell__, yyCell__, imCellS, ...
    maskCellS, intWeight, imCellNorm__, imCellNormS, intWeightS ] = ...
    intDoRescale( imCell, maskCell, ssCell, xxCell, yyCell, L0, W0, T0 )

nt = numel( imCell );
tt = (0:(T0-1))/(T0-1);


% (i) Renormalize the length of the cell to make it L = L0*(1+t/T)
for ii = 1:nt
    tii = (ii-1)/(nt-1);
    Lii = L0*(1+tii);
    
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
    
    
    % imshow( maskCell_{ii}, [] );
    % 'hi'
    
    
end

% (ii) Renormalize the length of the cell cycle to be length T0.
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
imCellS   = imCell__;
imCellNormS   = imCell__;

maskCellS = maskCell__;
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
    
    %     xmin_ = max([1,find(xsum>1,1,'first')-1]);
    %     try
    %     xmax_ = min([ssCell{ii}(2),find(xsum>1,1, 'last')+1]);
    %     catch
    %        'hi'
    %     end
    %     dx = xmax_ - xmin_ + 1;
    
    imCell__{ii}   = interp2(  (Xi-1), Yi-1,   imCell__{ii}, (Xi-1)*(2*L0)/Lii, Yi-1);
    maskCell__{ii} = interp2(  (Xi-1), Yi-1, maskCell__{ii}, (Xi-1)*(2*L0)/Lii, Yi-1);
    
    imCell__{ii}(isnan(imCell__{ii}))     = 0;
    maskCell__{ii}(isnan(maskCell__{ii})) = 0;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % normalize fluor so that the mean fluor remains constant over time.
       
    % the abs here is a bit of a cheat to nexver allow the sum fluor to
    % diverge. Due to illulimnation non-unifority and real life, sum can be
    % essentially = 0 causing all sorts of problems later.
    
    sum_ = sum(abs(imCell__{ii}(:)).*maskCell__{ii}(:))/sum(maskCell__{ii}(:));
    imCellNorm__{ii} = imCell__{ii}/sum_;
    intWeight(ii) = sum_;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % normalize fluor so that the mean fluor remains constant over time.    
    imCellS{ii}(isnan(imCellS{ii}))      = 0;
    maskCellS{ii}(isnan(maskCellS{ii}))  = 0;
    
    sumS_ = sum(imCellS{ii}(:).*maskCellS{ii}(:))/sum(maskCellS{ii}(:));
    imCellNormS{ii} = imCellS{ii}/sumS_;
    intWeightS(ii) = sumS_;

    %imshow( maskCell__{ii}, [] );
    
    ssCell__{ii} = size( imCell__{ii} );
    xxCell__{ii} = 1:ssCell__{ii}(2);
    yyCell__{ii} = 1:ssCell__{ii}(1);
    
end
%intWeight

end