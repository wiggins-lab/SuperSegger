function [im] = makeFrameMosaic( data, CONST, xdim, disp_flag, skip )
% makeFrameMosaic: Creates a tower for a single cell.
% The cell is shown masked. If CONST.view.orientFlag is true the cell 
% is oriented horizontally, it can be shown with FalseColor and
% in the fluorescent channel.
%
% INPUT :
%       data : cell file
%       CONST : segmentation parameters
%       xdim : number of frames in a row in final image
%       disp_flag : 1 to display image, 0 to not display iamge
%       skip : frames to be skipped in final image
%
% OUTPUT :
%       im : frame mosaic image
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

with_outline = 1;

persistent strel1;
if isempty( strel1 )
    strel1 = strel('disk',1);
end

persistent colormap_;
if isempty( colormap_ )
    colormap_ = jet( 256 );
end

if ~exist('CONST', 'var' ) || isempty( CONST )
    CONST = loadConstants(60,0);
end

if ~exist('skip','var') || isempty( skip )
    skip = 1;
end

if ~exist('disp_flag', 'var' ) || isempty( disp_flag )
    disp_flag = true;
end

% orients the cell horizontally if true
% keeps the orientation in the frame if false.
if isfield( CONST, 'view' ) && isfield( CONST.view, 'orientFlag' )
    orientFlag = CONST.view.orientFlag;
else
    orientFlag = true;
end

if ~isfield( CONST.view, 'background' );
    CONST.view.background = [0,0,0];
end


numframe = numel( data.CellA );
TimeStep = CONST.getLocusTracks.TimeStep; % used when plotting the numbers
imCell = cell( 1, numel(data.CellA) );
alpha = zeros(1, numel(data.CellA) );
ssCell = imCell;
xxCell = imCell;
yyCell = imCell;
max_x = 0;
max_y = 0;


for ii = 1:numframe % go through all the frames
    
    if orientFlag % to orient horizontally
        if isfield( data.CellA{ii}, 'pole' ) && ~isnan( data.CellA{ii}.pole.op_ori ) && (data.CellA{ii}.pole.op_ori ~= 0)
            ssign = sign(data.CellA{ii}.pole.op_ori);
        else
            ssign = 1;
        end
        
        e1 = data.CellA{ii}.coord.e1;
        alpha(ii) = 90-180/pi*atan2(e1(1),e1(2)) + 180*double(ssign==1);
        
        mask = data.CellA{ii}.mask;
        mask = logical(imdilate(mask,strel1)); % dilate the mask
        rotated_mask = imrotate( double(mask), alpha(ii), 'bilinear' );
        
        summedMaskX = sum(rotated_mask);
        xmin_ = max([1,find(summedMaskX>0,1,'first')-1]);
        xmax_ = min([size(rotated_mask,2),find(summedMaskX>0,1, 'last')+1]);
        
        summedMaskY = sum(rotated_mask');
        ymin_ = max([1,find(summedMaskY>0,1,'first')-1]);
        ymax_ = min([size(rotated_mask,1),find(summedMaskY>0,1, 'last')+1]);
        
        yyCell{ii} = ymin_:ymax_;
        xxCell{ii} = xmin_:xmax_;
        
        try
            imCell{ii} = rotated_mask( ymin_:ymax_, xmin_:xmax_ );
        catch ME
            printError(ME);
        end
        
        ss = size(imCell{ii});
        ssCell{ii} = ss;
    else % non rotated mask
        imCell{ii} = data.CellA{ii}.mask;
        ss = size(data.CellA{ii}.mask);
        ssCell{ii} = ss;
    end
    
    max_x = max([max_x, ss(2)]);
    max_y = max([max_y, ss(1)]);
end


if exist( 'xdim', 'var') && ~isempty( xdim )
    nx = xdim;
    ny = ceil( numframe/nx/skip );
else
    nx = ceil( sqrt( numframe*max_y/max_x/skip ) );
    ny = ceil( numframe/nx/skip );
end

max_x = max_x+1;
max_y = max_y+1;


imdim = [ max_y*ny + 1, max_x*nx + 1 ];
im = uint8(zeros(imdim(1), imdim(2), 3 ));
im1_= uint16(zeros(imdim(1), imdim(2)));
im2_= uint16(zeros(imdim(1), imdim(2)));
mask_mosaic = zeros(imdim(1), imdim(2));
im_list = [];



for ii = 1:skip:numframe
    
    yy = floor((ii-1)/nx/skip);
    xx = (ii-1)/skip-yy*nx;    
    ss = ssCell{ii};    
    dx = floor((max_x-ss(2))/2);
    dy = floor((max_y-ss(1))/2);
        

    if orientFlag
        mask = imCell{ii};
        mask = (imdilate( mask, strel1 ));
    else
        mask = data.CellA{ii}.mask;
        mask = (imdilate( mask, strel1 ));
    end
    
    mask_mosaic(1+yy*max_y+(1:ss(1))+dy, 1+xx*max_x+(1:ss(2))+dx) = mask;
    
        % fluor1
     if isfield( data.CellA{ii}, 'fluor1' )        
        if isfield( CONST.view, 'filtered' ) && ...
                CONST.view.filtered && ...
                isfield( data.CellA{ii}, 'fluor1_filtered' )           
            fluor1 =data.CellA{ii}.fluor1_filtered;
        else
            fluor1 = data.CellA{ii}.fluor1;            
            if isfield( data.CellA{ii}, 'fl1' ) && ...
                    isfield( data.CellA{ii}.fl1, 'bg' )
                fluor1 = fluor1 - data.CellA{ii}.fl1.bg;
            end
        end
        
        fluor1 = imrotate(fluor1,alpha(ii),'bilinear');
        fluor1 = fluor1(yyCell{ii}, xxCell{ii});
        im1_(1+yy*max_y+(1:ss(1))+dy, 1+xx*max_x+(1:ss(2))+dx) = fluor1;        
        FLAG1 = true;
    else
        im1_ = 0*mask_mosaic;
        FLAG1 = false;
        f1mm = [0,1];
    end
    
       
    % fluor2
    flag2 = isfield( data.CellA{ii}, 'fluor2' );
    if isfield( data.CellA{ii}, 'fluor2' ) && 1
        
        if isfield( CONST.view, 'filtered' ) && ...
                CONST.view.filtered && ...
                isfield( data.CellA{ii}, 'fluor2_filtered' )
            
            fluor2 =data.CellA{ii}.fluor2_filtered;
        else
            fluor2 = data.CellA{ii}.fluor2;
        end
        
        fluor2 = imrotate(fluor2,alpha(ii),'bilinear');
        fluor2 = fluor2(yyCell{ii}, xxCell{ii});
        
        
        if isfield( data.CellA{ii}, 'fl2' ) && ...
                isfield( data.CellA{ii}.fl2, 'bg' )
            fluor2 = fluor2 - data.CellA{ii}.fl2.bg;
            fluor2(fluor2<0) = 0;
        end
        
        im2_(1+yy*max_y+(1:ss(1))+dy, 1+xx*max_x+(1:ss(2))+dx) = fluor2;
        FLAG2 = true;
    else
        im2_ = uint8(0*mask_mosaic);
        FLAG2 = false;
        f2mm = [0,1];
    end
    
    
    if FLAG2
        im_list = [im_list, data.CellA{ii}.fluor1(:)', data.CellA{ii}.fluor2(:)'];
    elseif FLAG1
        im_list = [im_list, data.CellA{ii}.fluor1(:)'];
    else
        im_list = [im_list];
    end

end


% autogain the images
im1_ = ag(im1_);
im2_ = ag(im2_);
disk1 = strel('disk',1);


% different display methods
if isfield(CONST.view, 'falseColorFlag') && ...
        CONST.view.falseColorFlag && ~flag2
    % false color image - only works if there is only one channel
    im    = ag(doColorMap( im1_, colormap_ ));
    back3 = uint8( cat( 3, double(CONST.view.background(1))*double(1-mask_mosaic),...
        double(CONST.view.background(2))*double(1-mask_mosaic),...
        double(CONST.view.background(3))*double(1-mask_mosaic)));
    mask3 = cat( 3, mask_mosaic, mask_mosaic, mask_mosaic );
    im = uint8(uint8( double(im).*mask3)+back3);
elseif with_outline
    % plots normal mosaic with region outline
    del = 1;
    disk1 = strel('disk',1);   
    outer = imdilate(mask_mosaic, disk1).*double(~mask_mosaic);
    im = cat( 3, ...
        uint8(double(im2_).*mask_mosaic)+del*ag(1-mask_mosaic), ...
        uint8(double(im1_).*mask_mosaic)+del*ag(1-mask_mosaic), ...
        del*ag(1-mask_mosaic)+ag(outer));
else
    del = 1;    
    disk1 = strel('disk',1);
    im = cat( 3, ...
        uint8(double(im2_).*mask_mosaic)+del*ag(1-mask_mosaic), ...
        uint8(double(im1_).*mask_mosaic)+del*ag(1-mask_mosaic), ...
        del*ag(1-mask_mosaic) );
end




inv_flag = 0;
frameNumbers = 1:skip:numframe;

if disp_flag
    figure(2);
    clf;
    if inv_flag
        imshow(255-im);
    else
        imshow(im);
    end
    
    if isfield( CONST.view, 'falseColorFlag' ) ...
            && CONST.view.falseColorFlag
        cc = 'w';
    else
        cc = 'b';
    end
       
    
    hold on;    
    for ii = 1:numel(frameNumbers)        
        yy = floor((ii-1)/nx);
        xx = ii-yy*nx-1;
        y = 1+yy*max_y;
        x = 1+xx*max_x;                
        text( x+2, y+2, num2str(frameNumbers(ii)*TimeStep),'Color',[0.5, 0.5, 1],'FontSize',15,'VerticalAlignment','Top');
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


end


