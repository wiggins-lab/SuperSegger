function [Kymo,ll1,f1mm,f2mm] = makeKymographC( data, disp_flag, CONST, FLAGS )
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



if ~exist( 'FLAGS', 'var' ) || isempty( FLAGS ) 
    FLAGS.composite = 1;
    FLAGS.f_flag    = 1;
    FLAGS.Outline_flag = 0;
    FLAGS.filt = 0;
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

if ~exist( 'which_channel', 'var' ) || isempty(which_channel)
    which_channel = [1,1,1];
end

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

kymoR = zeros(nn,num_im);
kymoG = zeros(nn,num_im);
kymoB = zeros(nn,num_im);


for ii = 1:num_im
    
    mask  = data.CellA{ii}.mask;
    
    if isfield( data.CellA{ii}, 'fluor1') && which_channel(1)
        if filt_channel && isfield( data.CellA{ii},'fluor1_filtered')
            fluor1 =data.CellA{ii}.fluor1_filtered;
        else
            fluor1  = data.CellA{ii}.fluor1;
            if isfield( data.CellA{ii}, 'fl1' ) && isfield( data.CellA{ii}.fl1, 'bg' )
                fluor1 = fluor1 - data.CellA{ii}.fl1.bg;
                fluor1(fluor1<0) = 0;
            else
                fluor1 = fluor1 - mean( fluor1(mask));
                fluor1(fluor1<0) = 0;
            end
        end
    else
        fluor1 = 0*mask;
    end
    
    if isfield( data.CellA{ii}, 'fluor2') && which_channel(2)
        if filt_channel && isfield( data.CellA{ii}, 'fluor2_filtered' )
            fluor2 = data.CellA{ii}.fluor2_filtered;
        else
            fluor2 = data.CellA{ii}.fluor2;
            if isfield( data.CellA{ii}, 'fl12' ) && ...
                    isfield( data.CellA{ii}.fl2, 'bg' )
                fluor2 = fluor2 - data.CellA{ii}.fl2.bg;
                fluor2(fluor1<0) = 0;
            else
                fluor2 = fluor2 - mean( fluor2(mask));
                fluor2(fluor2<0) = 0;
            end
        end
    else
        fluor2 = 0*data.CellA{ii}.mask;
    end
    
    mask  = data.CellA{ii}.mask;
    
    % Make all the images the same sizes
    [Chan2,~] = (fixIm(double((fluor2)).*double(mask),ss));
    [Chan1,~] = (fixIm(double((fluor1)).*double(mask),ss));
    [ChanB,roffset] = fixIm(mask,ss);
    
    ro = data.CellA{ii}.r_offset;
    r = data.CellA{ii}.r;
    
    e1 = data.CellA{ii}.coord.e1;
    e2 = data.CellA{ii}.coord.e2;
    
    LL1x =  LL1*e1(1)+LL2*e2(1)+r(1)-ro(1)+1+roffset(1);
    LL2y =  LL1*e1(2)+LL2*e2(2)+r(2)-ro(2)+1+roffset(2);
    
    Chan2p = (interp2(XX,YY,double(Chan2),LL1x,LL2y));
    Chan1p = (interp2(XX,YY,double(Chan1),LL1x,LL2y));
    ChanBp = (interp2(XX,YY,double(ChanB),LL1x,LL2y));
    
    Chan2ps = sum( double(Chan2p) );
    Chan1ps = sum( double(Chan1p) );
    ChanBps = sum( double(ChanBp) );
    
    kymo2(:,ii) = Chan2ps';
    kymo1(:,ii) = Chan1ps';
    kymoB(:,ii) = ChanBps';
end

Kymo = [];

if ~isfield(data.CellA{1}, 'pole');
    data.CellA{1}.pole.op_ori = 1;
end


if data.CellA{1}.pole.op_ori < 0 % flip the kymograph
    Kymo.c1 = kymo1(end:-1:1,:);
    Kymo.b = kymoB(end:-1:1,:);
    Kymo.b(isnan(Kymo.b)) = 0;
    Kymo.c2 = kymo2(end:-1:1,:);
else
    Kymo.c1 = kymo1;
    Kymo.b = kymoB;
    Kymo.b(isnan(Kymo.b)) = 0;
    Kymo.c2 = kymo2;
end

f1mm(1) = min(Kymo.c1(logical(Kymo.b)));
f1mm(2) = max(Kymo.c1(logical(Kymo.b)));
f2mm(1) = min(Kymo.c2(logical(Kymo.b)));
f2mm(2) = max(Kymo.c2(logical(Kymo.b)));


if CONST.view.falseColorFlag
    % false color figure
    
    if FLAGS.f_flag == 1
        im__ = ag(Kymo.c1, f1mm(1), f1mm(2));
    elseif FLAGS.f_flag == 2
        im__ = ag(Kymo.c2, f2mm(1), f2mm(2));
    else
        im__ = zeros(size(Kymo.c1));
    end
    
    tmp = Kymo.b;
    tmp(tmp>1)=1;
    
    imm = comp( {im__,colormap_,'mask',tmp,'back', CONST.view.background} );
    
else
    
    tmp = Kymo.b;
    tmp(tmp>1)=1;
    
    if FLAGS.composite
        imm = comp( {Kymo.c1, CONST.view.fluorColor{1}},...
            {Kymo.c2, CONST.view.fluorColor{2}} );
    elseif FLAGS.f_flag == 1
        imm = comp( {ag(Kymo.c1), CONST.view.fluorColor{1}} );
    elseif  FLAGS.f_flag == 2
        imm = comp( {ag(Kymo.c2), CONST.view.fluorColor{2}} );
    end
    
    imm = comp( {imm, 'mask', tmp, 'back', CONST.view.background} );
    
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


