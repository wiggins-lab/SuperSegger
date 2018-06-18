function [im]= makeKymoMosaic (dirname, CONST, FLAGS)
% makeKymoMosaic creates a mosaic kymograph of multiple cells.
% make kymo mosaic is only for fl1 in makeKymograph, which is currently
% set to gfp. A kymograph shows the fluorescence of the cell along the
% long axis of the cell, with time.
%
% INPUT :
%       dirname : directory with cell data files
%       CONST : segmentation parameters
% OUTPUT : 
%       im : output image of kymo mosaic
%
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins, Stella Stylianidou.
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

% NOTE: TIME IN HOURS FOR 1 MIN FREQUENCY
TimeStep     = CONST.getLocusTracks.TimeStep/60;
PixelSize    = CONST.getLocusTracks.PixelSize;


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

if ~isfield(CONST.view, 'maxNumCell' )
    CONST.view.maxNumCell = 100;
else
    
num_list_ = min( [num_list_, CONST.view.maxNumCell] );
num_list = 0;

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

h = waitbar(0, 'Computation' );
cleanup = onCleanup( @()( delete( h ) ) );

for jj = 1:num_list_
    
    if ~isempty(dir_list(jj).name)
        
        ii = ii + 1;
        filename = [dirname,filesep,dir_list(jj).name];
        data = load(filename);
        data_A{ii} = makeKymographC(data, 0, CONST, FLAGS);
        
        name(jj) = data.ID;
        pole(jj) = getPoleSign( data );
        
%         if CONST.view.falseColorFlag
%             backer3 = double(cat(3, kymo.b, kymo.b, kymo.b)>1);
%             im = doColorMap( ag(kymo.c1,f1mm(1), f1mm(2)), colormap_ );
%             data_A{ii} =( im.*backer3+.6*(1-backer3) );
%         else
%             data_A{ii} = comp( {ag(1-kymo.b),[del,del,del]}, ...
%                 {ag(kymo.c2),CONST.view.fluorColor{2} },...
%                 {ag(kymo.c1),CONST.view.fluorColor{1} });
%         end
        


        ss = size(data_A{ii});       
        max_x = max([max_x,ss(1)]);
        max_t = max([max_t,ss(2)]);        
    end
     waitbar(jj/num_list_,h);
end
 close(h);
 
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

    for ii = 1:3
        im(:,:,ii) = uint8(CONST.view.background(ii)*255);
    end
    
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
    for ii = 1:3
        im(:,:,ii) = uint8(CONST.view.background(ii)*255);
    end
    
    for ii = 1:num_list
        yy = floor((ii-1)/numb);
        xx = ii-yy*numb-1;
        
        ss = size(data_A{ii});
        dx = floor((max_x-ss(1))/2);
        
        im(1+yy*max_x+(1:ss(1))+dx, 1+xx*max_t+(1:ss(2)),:) =  data_A{ii};
    end
end

im = uint8( im );

ss = size(im);

T_ = (1:ss(2))*TimeStep;
X_ = (1:ss(1))*PixelSize;

inv_flag = 0;
figure;
clf;
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


