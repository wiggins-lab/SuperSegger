%% vizulizations for superSegger


%% error figure
% make segment mosaic

dirname = '/Users/Stella/Documents/MATLAB/phase/minlengnew_sml_reg_opy/xy1/seg/'
files = dir([dirname,'*err.mat']);
tmp_axis = [50  192 19 188];
figure(1);
clf;
time = 1:5:121;
num_time = numel(time)
x = 6;
y = round(num_time/x);
ha = tight_subplot(y,x,[0.01 0],[0 0],[0 0])%,0.3,0.3,0.3)

counter = 0;
for i = time
    counter = counter  + 1;
     
     data = load([dirname,files(i).name]);
     
     axes(ha(counter));
     showSegDataPhase(data)
     axis( tmp_axis );
    
    
end


%% figure for explaining segmentation
%contents = dir([dirname,'*seg.mat']);

% % example 1 : 
% dirname = '/Users/Stella/Dropbox/mrnasegger/xy1/seg/'
% filename = '2014_05_30_controlagaint110xy1_seg.mat'
% data = load([dirname,filename]);
% tmp_axis = [250 360 184 298];

%%

CONST = loadConstants('60XEcLB');
dirname = '/Users/Stella/Documents/MATLAB/forPublishingSSO/'
filename = '2014_05_30_controlagaint105xy1_seg.mat'
data = load([dirname,filename]);
[dataSeg]  = superSeggerOpti(data.phase, [], 1, CONST, 1, [], [] )
dataRegOpt = perRegionOpti( dataSeg, 1, CONST,'');
figure(1);
imshow(dataSeg.mask_cell)
figure(2);
imshow(dataRegOpt.mask_cell)

%%
tmp_axis = [400 478 282 348];

tmp_axis = [1485 1555 970 1030];


figure;
imshow(dataSeg.mask_cell)
axis(tmp_axis)


figure;
%imshow(dataRegOpt.mask_cell)
axis(tmp_axis)


% superSeggerOpti images

crop_box = [];

MIN_BG_AREA     = CONST.superSeggerOpti.MIN_BG_AREA;
MAGIC_RADIUS    = CONST.superSeggerOpti.MAGIC_RADIUS;
MAGIC_THRESHOLD = CONST.superSeggerOpti.MAGIC_THRESHOLD;
CUT_INT         = CONST.superSeggerOpti.CUT_INT;
SMOOTH_WIDTH    = CONST.superSeggerOpti.SMOOTH_WIDTH;
MAX_WIDTH       = CONST.superSeggerOpti.MAX_WIDTH;
A               = CONST.superSeggerOpti.A;


phaseOrig = data.phase;
phaseNormFilt = phaseOrig;

% fix the range, set the max and min value of the phase image
mult_max = 2.5;
mult_min = 0.3;
mp = mean(phaseNormFilt(:));
phaseNormFilt(phaseNormFilt > (mult_max*mp)) = mult_max*mp;
phaseNormFilt(phaseNormFilt < (mult_min*mp)) = mult_min*mp;

% if the size of the matrix is even, we get a half pixel shift in the
% position of the mask which turns out to be a probablem later.
f = fspecial('gaussian', 11, SMOOTH_WIDTH);
phaseNormFilt = imfilter(phaseNormFilt, f,'replicate');

filt_3 = fspecial( 'gaussian',25, 15 );
filt_4 = fspecial( 'gaussian',5, 1/2 );
mask_bg_ = makeBgMask(phaseNormFilt,filt_3,filt_4,MIN_BG_AREA, CONST, crop_box);

% Minimum constrast filter to enhance inter-cellular image contrast
phaseNormFilt = ag(phaseNormFilt);
magicPhase = magicContrast(phaseNormFilt, MAGIC_RADIUS);

% % this is to remove small object - it keeps only objects with bright halos
filled_halos = fillHolesAround(magicPhase,CONST,crop_box);

% make sure that not too much was discarded
if sum(phaseNormFilt(:)>0) < 1.5 * sum(filled_halos(:))
    disp('keeping only objects with bright halos');
    mask_bg_ = filled_halos & mask_bg_;
end

% remove bright halos from the mask
mask_halos = (magicPhase>CUT_INT);
mask_bg = logical((mask_bg_-mask_halos)>0);


% C2phase is the Principal curvature 2 of the image without negative values
% it also enhances subcellular contrast. We subtract the magic threshold
% to remove the variation in intesnity within a cell region.
[~,~,~,C2phase] = curveFilter (double(phaseNormFilt),1);
C2phaseThresh = double(uint16(C2phase-MAGIC_THRESHOLD));

% watershed just the cell mask to identify segments
phaseMask = uint8(agd(C2phaseThresh) + 255*(1-(mask_bg)));
ws = 1-(1-double(~watershed(phaseMask,8))).*mask_bg;



% h = figure(22);
% clf;
figure('DefaultAxesFontSize',12)

%ha = tight_subplot(Nh, Nw, gap, marg_h, marg_w)
ha = tight_subplot(3,2,[0.05 0],[0.05 0.05],[0.01 0.01])%,0.3,0.3,0.3)


% phase image with more contrast
axes(ha(1));
imshow( 1.3*ag((double(data.phase))) );
axis( tmp_axis );
title( 'Phase' );


%subplot( 3,2,2 );

bg_color = [87,87,138];
% bg mask with background color
axes(ha(2));
back = double(~mask_bg);
masker = uint8(cat(3, bg_color(1)*back, bg_color(2)*back, bg_color(3)*back ));
imshow( masker );
axis( tmp_axis );
title( 'Mask' );


axes(ha(3));

%ax1 = subplot( 3,2,3 );
phaseC2cubed = (double(C2phase)).^0.5;
caxis_tmp = [.3*min(phaseC2cubed( mask_bg )),max(phaseC2cubed( mask_bg ))];
jetter = gray(256);
jetter = jetter( 1:150,:);
tmp_magic = doColorMap( phaseC2cubed, jetter, caxis_tmp);
tmp1 = tmp_magic(:,:,1);
tmp2 = tmp_magic(:,:,2);
tmp3 = tmp_magic(:,:,3);

masker = double(masker)/255;

tmp1_ = masker(:,:,1);
tmp2_ = masker(:,:,2);
tmp3_ = masker(:,:,3);


tmp1(~mask_bg) = tmp1_(~mask_bg);
tmp2(~mask_bg) = tmp2_(~mask_bg);
tmp3(~mask_bg) = tmp3_(~mask_bg);

tmp_magic = cat(3, tmp1,tmp2,tmp3);
imshow( tmp_magic )
axis( tmp_axis );
title( 'Contrast Filter' );


% watershed image
%subplot( 3,2,4 );
axes(ha(4));
back = double(ws);
masker = uint8(cat(3, bg_color(1)*back, bg_color(2)*back, bg_color(3)*back ));
imshow( masker );
axis( tmp_axis );
title( 'Watershed' );



%subplot( 3,2,5 );
axes(ha(5));
showSegDataPhase(dataSeg)
axis( tmp_axis );
title( 'Segment Optimized' );

%subplot( 3,2,6 );
% axes(ha(6));
% showSegDataPhase(dataRegOpt)
% axis( tmp_axis );
% title( 'Region Optimized' );


%% more figures
figure;
ha = tight_subplot(1,2,[0.05 0],[0.05 0.05],[0.01 0.01])%,0.3,0.3,0.3)

back = double(~mask_bg_);
masker = uint8(cat(3, bg_color(1)*back, bg_color(2)*back, bg_color(3)*back ));

axes(ha(1));
imshow(masker,[])
axis(tmp_axis);

axes(ha(2));
imshow(magicPhase,[])
axis(tmp_axis);

figure;
imshow(C2phase.^.8,[])
axis(tmp_axis);
%% LIKING STUFF

dirname = '/Users/Stella/Documents/MATLAB/data/mrnaControl/seg120/'
contents = dir ([dirname,'*err.mat']);
data1 = load([dirname,contents(10).name]);
data2 = load([dirname,contents(15).name]);
data3 = load([dirname,contents(20).name]);
data4 = load([dirname,contents(25).name]);

%% Figure to show linking
tmp_axis = [919 980 2070 2162];
figure(1);
imshow( 1.5*ag((double(data1.phase))) );
axis(tmp_axis);

figure(2);
imshow(4*ag(cat(3,0*double(data1.fluor1),double(data1.fluor1),0*double(data1.fluor1))));
axis(tmp_axis);



dots =0;
figure(3);
clf;
cellOutline( data1, dots)
axis(tmp_axis);
dots = 1;


figure(2);
clf;
ha = tight_subplot(4,1,[0.05 0],[0.05 0.05],[0.01 0.01])%,0.3,0.3,0.3)
axes(ha(1));
cellOutline( data1,dots);axis(tmp_axis);

axes(ha(2));
cellOutline( data2,dots)
axis(tmp_axis);

axes(ha(3));
cellOutline( data3,dots)
axis(tmp_axis);

axes(ha(4));
cellOutline( data4,dots)
axis(tmp_axis);



%% Cells


load('/Users/Stella/Documents/MATLAB/data/testData3.mat')
data = cellData;
%clear all; data = load('/Users/Stella/Dropbox/mrnasegger/xy1/cell/cell0000010.mat')
time = 23;


figure(1)
clf;

celld = data.CellA{time};
mask = celld.mask;


len = celld.length;
r_center = data.CellA{time}.coord.r_center;
e1 = data.CellA{time}.coord.e1;
e2 = data.CellA{time}.coord.e2;

xaxisxp = [e1(1)*len(1),0]/2 + r_center(1);
xaxisyp = [e1(2)*len(1),0]/2 + r_center(2);
yaxisxp = [e2(1)*len(2),0]/2 + r_center(1);
yaxisyp = [e2(2)*len(2),0]/2 + r_center(2);

im_size   = size(mask);
im_size_x = im_size(2);
im_size_y = im_size(1);

xx = 1:im_size_x;
yy = 1:im_size_y;

xxx = xx + celld.r_offset(1)-1;
yyy = yy + celld.r_offset(2)-1;

hold on;
imagesc( xxx,yyy,ag(mask));

axis equal

colormap gray
hold on;
%    plot( r(1), r(2), 'bo');
plot( celld.coord.rcm(1), celld.coord.rcm(2), 'r.');
plot( celld.coord.r_center(1), celld.coord.r_center(2), 'r*');
plot( celld.coord.xaxis(:,1),celld.coord.xaxis(:,2),'r:')
plot( celld.coord.yaxis(:,1),celld.coord.yaxis(:,2),'r:')
plot( xaxisxp, xaxisyp,'r-')
plot( yaxisxp, yaxisyp,'r-')
plot( celld.r_offset(1), celld.r_offset(2),'ro')
plot( celld.coord.box(:,1), celld.coord.box(:,2),'r-')


figure(2);
clf;
ha = tight_subplot(3,1,[0.05 0],[0.05 0.05],[0.01 0.01]);


% plot pole
tmp = data.CellA{time};
r = tmp.coord.r_center;

if tmp.pole.op_ori
    old_pole = r + tmp.length(1)*tmp.coord.e1*tmp.pole.op_ori/2;
    new_pole = r - tmp.length(1)*tmp.coord.e1*tmp.pole.op_ori/2;
else
    old_pole = r + tmp.length(1)*tmp.coord.e1/2;
    new_pole = r - tmp.length(1)*tmp.coord.e1/2;
end

x_= tmp.r_offset(1)-1;
y_= tmp.r_offset(2)-1;
centerx = r(1) -  x_;
centery = r(2) - y_;
polex = old_pole(1) -  x_;
poley = old_pole(2)  - y_;

axes(ha(1));
imshow(ag(data.CellA{time}.phase))


axes(ha(2));

imshow(cat(3,data.CellA{time}.mask*0,ag(data.CellA{time}.fluor1),data.CellA{time}.mask*0))
hold on;
for i = 1 : numel(data.CellA{time}.locus1)
    if data.CellA{time}.locus1(i).score > 5
        locusPos = data.CellA{time}.locus1(i).r;
        plot( locusPos(1)-x_, locusPos(2)-y_, 'w*','MarkerSize',2);
    end
end

axes(ha(3));

imshow(data.CellA{time}.mask)
hold on;
plot( old_pole(1)-x_, old_pole(2)-y_, 'ro','MarkerSize',6);
plot( new_pole(1)-x_, new_pole(2)-y_, 'r*','MarkerSize',6);
%plot( celld.coord.rcm(1)-x_, celld.coord.rcm(2)-y_, 'r^');
plot( celld.coord.r_center(1)-x_, celld.coord.r_center(2)-y_, 'rd');
plot( celld.coord.xaxis(:,1)-x_,celld.coord.xaxis(:,2)-y_,'r:')
plot( celld.coord.yaxis(:,1)-x_,celld.coord.yaxis(:,2)-y_,'r:')
plot( xaxisxp-x_, xaxisyp-y_,'r-')
plot( yaxisxp-x_, yaxisyp-y_,'r-')
plot( celld.r_offset(1)-x_, celld.r_offset(2)-y_,'r^')
plot( celld.coord.box(:,1)-x_, celld.coord.box(:,2)-y_,'r-')






%%
data = data1;
cell_mask = data.mask_cell;
back = double(1*ag(~cell_mask));
outline = imdilate( cell_mask, strel( 'square',3) );
outline = ag(outline-cell_mask);
back2 = (back-double(outline));
imshow(uint8(cat(3,back2 + 0.9*double(ag(outline))...
    ,back2,...
    back2 + 0.1*double(ag(~cell_mask)-outline))));
axis(tmp_axis);

% 
% figure(2);
% clf;
% backphase =  double(ag(data.phase));
% imshow(uint8(cat(3,backphase + double(ag(outline))...
%     ,backphase)...
%     ,backphase +  0.2 * double(ag(~cell_mask)-outline))));
% axis(tmp_axis);



% get centroids
hold on;
for i = 1 : data.regs.num_regs
    hold on;
    plot(data.regs.props(i).Centroid(1),data.regs.props(i).Centroid(2),'.', 'MarkerSize',23,'Color',[1,0.3,0]);
end




