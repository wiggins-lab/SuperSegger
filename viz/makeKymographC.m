function [imm] = makeKymographC( data, disp_flag, CONST, FLAGS )
% makeKymographC : creates a kymograph for given cell data file..
% A kymograph shows the fluorescence of the cell along the long axis
% of the cell, with time.
%
% INPUT :
%       data : cell data file
%       disp_flag : 1 to display image, 0 to not display image
%       CONST : segmentation parameters
%       which_channel : binarry array of fluorescence channels to be plotted eg. [1,1,1]
%
% OUTPUT :
%       Kymo: Kymo has images at .r .g and .b fields. The (autogained)
%       combination produces the kymgraph.
%       ll1: size of the y axis in pixels.
%       f1mm: is a two value array with the max and min value of channel 1
%       f2mm: is a two value array with the max and min value of channel 2
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

% compute number of channels
nc = intGetChannelNum( data.CellA{1} );

if ~exist( 'FLAGS', 'var' ) || isempty( FLAGS ) 
    FLAGS.composite = 1;
    FLAGS.f_flag    = 1;
    FLAGS.Outline_flag = 0;
    FLAGS.filt = zeros( [1,10] );
    FLAGS.include = true( [1,10] );
    FLAGS.level = 0.7*ones( [1,10] );
end



white_bg = 0; % set to 1 for white background, outlined kymo
Kymo = [];
ll1=[];
f1mm=[0,1];
f2mm=[0,1];
pixelsize = CONST.getLocusTracks.PixelSize;

if isempty(pixelsize)
    pixelsize = 0.1;
end


if ~isfield(CONST.view, 'falseColorFlag' )
    CONST.view.falseColorFlag = false;
end

% if ~exist( 'which_channel', 'var' ) || isempty(which_channel)
%     which_channel = [1,1,1];
% end

if ~isfield(CONST.view, 'filtered' )
    CONST.view.filtered = true;
end

filt_channel =  FLAGS.filt;%CONST.view.filtered ;

persistent colormap_;
if isempty( colormap_ )
    colormap_ = colormap( 'jet' );
    %colormap_ = colormap( 'hsv' );
end

if nargin < 2
    disp_flag = 0;
end

num_im = numel(data.CellA);

ss = [0,0];
ll = [0,0];

% ss is max size of phase image
% ll is max length/width of the cell
for ii = 1:num_im
    ss_tmp = size(data.CellA{ii}.phase);
    
    ss(1) = max([ss(1),ss_tmp(1)]);
    ss(2) = max([ss(2),ss_tmp(2)]);
    
    ll_tmp = data.CellA{ii}.length;
    
    ll(1) = max([ll(1),ll_tmp(1)]);
    ll(2) = max([ll(2),ll_tmp(2)]);
end

ss = ss + [5,5];

[XX,YY] = meshgrid( 1:ss(2), 1:ss(1) );
ll0 = ll;
ll = ceil(ll/2);

ll1 = [-ll(1):ll(1)];
ll2 = [-ll(2):ll(2)];

[LL1,LL2] = meshgrid( ll1,ll2 );

nn = numel( ll1 );

kymo_cell = cell([1,nc]);


if ~isfield(data.CellA{1}, 'pole');
    data.CellA{1}.pole.op_ori = 1;
end

for ii = 1:num_im

    mask  = data.CellA{ii}.mask;

    % take care of background image first
    [Chan_tmp,roffset] = fixIm(mask,ss);
    
    ro = data.CellA{ii}.r_offset;
    r = data.CellA{ii}.r;
    
    e1 = data.CellA{ii}.coord.e1;
    e2 = data.CellA{ii}.coord.e2;
    
    LL1x =  LL1*e1(1)+LL2*e2(1)+r(1)-ro(1)+1+roffset(1);
    LL2y =  LL1*e1(2)+LL2*e2(2)+r(2)-ro(2)+1+roffset(2);
    
    Chan_tmp = (interp2(XX,YY,double(Chan_tmp),LL1x,LL2y));
    Chan_tmp = sum( double(Chan_tmp) );
    kymo_back(:,ii) = Chan_tmp';
    
    if data.CellA{1}.pole.op_ori < 0 % flip the kymograph
            kymo_back(:,ii) = kymo_back(end:-1:1,ii);
    end
    % compute fluor channels
    
    
    for jj = 1:nc
        
            
        fluorName =  ['fluor',num2str(jj)];
        ffiltName =  ['fluor',num2str(jj),'_filtered'];
        flName    =  ['fl',num2str(jj)];
        
        if isfield( data.CellA{ii}, fluorName ) && ...
                ( FLAGS.f_flag == jj || FLAGS.composite )
            
            
            if ii == 1
                kymo_cell{jj} = zeros(nn,num_im);
            end
            
            if filt_channel(jj) && isfield( data.CellA{ii},ffiltName)
                fluor_tmp =data.CellA{ii}.(ffiltName);
            else
                fluor_tmp  = data.CellA{ii}.(fluorName);
                
                if isfield( data.CellA{ii}, flName  ) && isfield( data.CellA{ii}.(flName), 'bg' )
                    fluor_tmp = fluor_tmp - data.CellA{ii}.(flName).bg;
                    fluor_tmp(fluor_tmp<0) = 0;
                else
                    fluor_tmp = fluor_tmp - mean( fluor_tmp(mask));
                    fluor_tmp(fluor_tmp<0) = 0;
                end
            end
        else
            fluor_tmp = [];
        end
        
        if ~isempty( fluor_tmp )
            [Chan_tmp,~] = (fixIm(double((fluor_tmp)).*double(mask),ss));
            
            Chan_tmp = (interp2(XX,YY,double(Chan_tmp),LL1x,LL2y));
            Chan_tmp = sum( double(Chan_tmp) );
            kymo_cell{jj}(:,ii) = Chan_tmp';
            
            if data.CellA{1}.pole.op_ori < 0 % flip the kymograph
                kymo_cell{jj}(:,ii) = kymo_cell{jj}(end:-1:1,ii);
            end
        end

    end
end

kymo_back(isnan(kymo_back)) = 0;

kymo_back(kymo_back>1) = 1;
    
% get min and mask values in masked region for each channel
imRange = nan( [2,nc] );
for jj = 1:nc
    if ~isempty(kymo_cell{jj})
        imRange(:,jj) = intRange(kymo_cell{jj}(logical(kymo_back)));
    end
end


if CONST.view.falseColorFlag && FLAGS.f_flag > 0
    imm = comp( {kymo_cell{FLAGS.f_flag},imRange(:,FLAGS.f_flag),...
        colormap_,'mask',kymo_back,'back', CONST.view.background} );
else

    imm = [];
    
    for jj = 1:nc
        if ~isempty( kymo_cell{jj} ) && (FLAGS.composite || FLAGS.f_flag==jj )
            if FLAGS.include( jj+1)
                imm = comp( {imm}, {kymo_cell{jj}, imRange(:,jj),...
                    CONST.view.fluorColor{jj}, FLAGS.level(jj+1)} );
            end
        end
    end
    
    imm = comp( {imm, 'mask', kymo_back , 'back', CONST.view.background} );
    
end

if disp_flag
    figure (2);
    clf;
    imagesc(1:num_im,pixelsize*ll1, imm);
end

end

function [imFix,roffset] = fixIm(im, ss)

ssOld = size(im);
imFix = zeros(ss);

offset = floor((ss-ssOld)/2)-[1,1];
if offset(1)<0
    offset(1) = offset(1) + 1;
end
if offset(2)<0
    offset(2) = offset(2) + 1;
end

try
    imFix(offset(1)+(1:ssOld(1)),offset(2)+(1:ssOld(2))) = im;
catch ME
    printError(ME);
end
roffset = offset(2:-1:1);
end
