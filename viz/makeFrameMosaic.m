function [im] = makeFrameMosaic( data, CONST, xdim, disp_flag, skip, FLAGS )
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


if ~exist( 'FLAGS', 'var' ) || isempty( FLAGS ) 
    FLAGS.composite = 1;
    FLAGS.f_flag    = 1;
    FLAGS.Outline_flag = 0;
    FLAGS.filt = zeros( [1,10] );
    FLAGS.include = true( [1,10] );
    FLAGS.level = 0.7*ones( [1,10] );
end

    

%which_channel = [1,1,1];
% if ~exist( 'which_channel', 'var' ) || isempty(which_channel)
%     which_channel = [1,1,1];
% end

nc = intGetChannelNum( data.CellA{1} );


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

if ~isfield( CONST.view, 'background' )
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



imm = cell([1,nc]);

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
    

    
    FLAG_ = zeros([1,nc]);
    % fluor1
    % loop over channels
    
    for jj = 1:nc

        
        if ii==1
           imm{jj} = mask_mosaic; 
        end
        
        fluorName =  ['fluor',num2str(jj)];
        ffiltName =  ['fluor',num2str(jj),'_filtered'];
        flName    =  ['fl',num2str(jj)];
        
        if isfield( data.CellA{ii}, fluorName )
            if FLAGS.filt(jj) && ...
                    isfield( data.CellA{ii}, ffiltName )
                fluor_tmp =data.CellA{ii}.(ffiltName);
            else
                fluor_tmp = data.CellA{ii}.(fluorName);
                if isfield( data.CellA{ii}, flName ) && ...
                        isfield( data.CellA{ii}.(flName), 'bg' )
                    fluor_tmp = fluor_tmp - data.CellA{ii}.(flName).bg;
                end
            end
            
            fluor_tmp = imrotate(fluor_tmp, alpha(ii), 'bilinear');
            fluor_tmp = fluor_tmp(yyCell{ii}, xxCell{ii});
            imm{jj}(1+yy*max_y+(1:ss(1))+dy, 1+xx*max_x+(1:ss(2))+dx) = fluor_tmp;
            
            FLAG_(jj) = true;
        else
            %im1_      = 0*mask_mosaic;
            FLAG_(jj) = false;
            f1mm      = [0,1];
        end
                
%         if FLAG2
%             im_list = [im_list, data.CellA{ii}.fluor1(:)', data.CellA{ii}.fluor2(:)'];
%         elseif FLAG1
%             im_list = [im_list, data.CellA{ii}.fluor1(:)'];
%         else
%             im_list = [im_list];
%         end
        
    end

    
end

% autogain the images


%im1_ = ag(im1_);
%im2_ = ag(im2_);
disk1 = strel('disk',1);



% different display methods
if isfield(CONST.view, 'falseColorFlag') && ...
        CONST.view.falseColorFlag
    % false color image - only works if there is only one channel

    im = comp( {imm{jj},colormap_,'mask', mask_mosaic, 'back' ,CONST.view.background} );
else
    
    if FLAGS.Outline_flag
        
        disk1 = strel('disk',2);
        outer = imdilate(mask_mosaic, disk1).*double(~mask_mosaic);
    else
        outer = zeros( size( im1_ ) );
    end
    
    % plots normal mosaic with region outline
    im = [];
    for jj = 1:nc
        if FLAGS.composite || FLAGS.f_flag == jj
           if FLAGS.include(jj+1)
                im = comp( {im}, {imm{jj}, CONST.view.fluorColor{jj}, FLAGS.level(jj+1)} );
           end
        end
    end
    
    im = comp( {im,'mask',mask_mosaic,'back',CONST.view.background},...
        {ag(outer),'b'} );
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


