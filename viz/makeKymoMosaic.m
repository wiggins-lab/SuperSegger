function makeKymoMosaic (dirname, CONST)
% makeKymoMosaic creates a mosaic kymograph of multiple cells.
% make kymo mosaic is only for fl1 in makeKymograph, which is currently
% set to gfp. A kymograph shows the fluorescence of the cell along the
% long axis of the cell, with time.
%
% INPUT :
%       dirname : directory with cell data files
%       CONST : segmentation parameters
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


% PROBLEM IN MAKY KYMOGRAPH F1MM does not exist if view false color is not
% true!

% NOTE: TIME IN HOURS FOR 1 MIN FREQUENCY
TimeStep     = CONST.getLocusTracks.TimeStep/60;
PixelSize    = CONST.getLocusTracks.PixelSize;
tmp = [];

if ~isfield(CONST.view, 'falseColorFlag' )
    CONST.view.falseColorFlag = false;
end

%figure(1);
persistent colormap_;
if isempty( colormap_ )
    colormap_ = colormap( 'jet' );
end

if ~isfield( CONST, 'view') || CONST.view.showFullCellCycleOnly
    dir_list = dir([dirname,filesep,'Cell*.mat']);
else
    dir_list = dir([dirname,filesep,'*ell*.mat']);
end


num_list_ = numel( dir_list ); % number of cells to be displayed
num_list = 0;

% why is this necessary?
for ii = 1:num_list_   
    if (~isempty(dir_list(ii).name))
        num_list = num_list + 1;
    end
end

numa = ceil(sqrt(num_list));
numb = ceil( num_list/numa);


clf;
max_x = 0;
max_t = 0;
data_A = cell(1,num_list);
del = .1;
ii = 0;

for jj = 1:num_list_
    
    if ~isempty(dir_list(jj).name)
        
        ii = ii + 1;
        filename = [dirname,filesep,dir_list(jj).name];
        data = load(filename);
        [kymo,ttmp,f1mm,f2mm] = makeKymographC(data,0,CONST);
        
        name(jj) = data.ID;
        pole(jj) = getPoleSign( data );
        
        if CONST.view.falseColorFlag
            backer3 = double(cat(3, kymo.b, kymo.b, kymo.b)>1);
            im = doColorMap( ag(kymo.g,f1mm(1), f1mm(2)), colormap_ );
            data_A{ii} =( im.*backer3+.6*(1-backer3) );
        else
            data_A{ii} = cat(3,del*autogain(1-kymo.b)+autogain(kymo.r),...
                del*autogain(1-kymo.b)+ag(kymo.g),del*autogain(1-kymo.b));
        end
        
        ss = size(data_A{ii});       
        max_x = max([max_x,ss(1)]);
        max_t = max([max_t,ss(2)]);        
    end
    
end

max_x = max_x+1;
max_t = max_t+1;
imdim = [ max_x*numa + 1, max_t*numb + 1 ];

for ii = 1:2
    if isnan(imdim(ii))
        imdim (ii)= 0;
    end
end


if CONST.view.falseColorFlag
    cc = 'w';
    im = (zeros(imdim(1), imdim(2), 3 ));
    im(:,:,:) = del*0;
    
    for ii = 1:num_list
        yy = floor((ii-1)/numb);
        xx = ii-yy*numb-1;
        
        ss = size(data_A{ii});
        dx = floor((max_x-ss(1))/2);
        
        im(1+yy*max_x+(1:ss(1))+dx, 1+xx*max_t+(1:ss(2)),:) =  data_A{ii};
    end
else
    cc = 'w';
    im = uint8(zeros(imdim(1), imdim(2), 3 ));
    im(:,:,:) = del*255;
    
    for ii = 1:num_list
        yy = floor((ii-1)/numb);
        xx = ii-yy*numb-1;
        
        ss = size(data_A{ii});
        dx = floor((max_x-ss(1))/2);
        
        im(1+yy*max_x+(1:ss(1))+dx, 1+xx*max_t+(1:ss(2)),:) =  data_A{ii};
    end
end

ss = size(im);

T_ = (1:ss(2))*TimeStep;
X_ = (1:ss(1))*PixelSize;

inv_flag = 0;

if inv_flag
    imagesc(T_,X_,255-im);
else
    imagesc(T_,X_,im);
end
hold on;

nx = ceil(sqrt( num_list*max_x/max_t));
ny = ceil(num_list/nx);

max_T = max(T_);
max_X = max(X_);

for ii = 1:num_list
    yy = floor((ii-1)/numb);
    xx = ii-yy*numb-1;
    y = yy*(max_X/numa);
    x = xx*(max_T/numb);
    text( x+max_T/20/numb, y+max_X/20/numa, [num2str(name(ii))],'Color',cc,'FontSize',12,'VerticalAlignment','Top','HorizontalAlignment','Left');
end


dd = [1,numa*max_x+1];
for xx = 1:(numb-1)
    plot( (0*dd + 1+xx*max_t)*TimeStep, dd*PixelSize,[':',cc]);
end

dd = [1,numb*max_t+1];
for yy = 1:(numa-1)
    plot( (dd)*TimeStep, (0*dd + 1+yy*max_x)*PixelSize, [':',cc]);
end

xlabel('Time (h)');
ylabel('Long Axis Position (um)');

end


