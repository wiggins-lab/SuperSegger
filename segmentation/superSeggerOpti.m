function [data,A]  = superSeggerOpti(phase_, mask, disp_flag, CONST, adapt_flag, header, crop_box )
% superSeggerOpti generates the initial segmentation of rod-shaped cells.
% It uses a local minimum filter (similar to a median filter) to enhance
% contrast and then uses Matlab's WATERSHED command to generate
% cell boundaries. The spurious boundaries (i.e., those that lie in the
% cell interiors) are removed by an intensity thresholding routine
% on each boundary. Any real boundaries incorrectly removed
% by this thresholding are added back by an iterative algorithm that
% uses knowledge of cell shape to determine which regions are missing
% boundaries.
%
% INPUT :
%       phase_ : phase image
%       mask : cell mask, given externally or calculated with band-pass filter
%       disp_flag : display flag
%       CONST : segmentation constants
%       adapt_flag : break up regions that are too big to be cells
%       header : string displayed with infromation
%       crop_box : information about alignement of the image
%
% OUTPUT :
%       data.segs : defined below
%       data.mask_bg : a binary image in which all background (non-cell) pixels are masked
%       data.mask_cell : cell mask, a binary image the same size as phase in
%       which each cell is masked by a connected region of white pixels
%       data.phase : Original phase image
%       A : scoring vector optimized for different cells and imaging conditions
%
%   segs.
%     phaseMagic: % phase image processed with magicContrast only
%      segs_good: % on segments, image of the boundaries between cells that the program
%      has determined are correct (i.e., not spurious).
%       segs_bad: % off segments, image of program-determined spurious boundaries between cells
%        segs_3n: % an image of all of boundary intersections, segments that cannot be switched off
%           info: % segment parameters that are used to generate the raw
%           score, looke below
%     segs_label: % bwlabel of good and bad segs.
%          score: % cell scores for regions
%       scoreRaw: % raw scores for segments
%          props: % segement properties for segments
%
%
%         seg.info(:,1) : the minimum phase intensity on the seg
%         seg.info(:,2) : the mean phase intensity on the seg
%         seg.info(:,3) : area of the seg
%         seg.info(:,4) : the mean second d of the phase normal to the seg
%         seg.info(:,5) : second d of the phase normal to the seg at the min pixel
%         seg.info(:,6) : second d of the phase parallel to the seg at the min pixel
%         seg.info(:,7) and seg_info(:,8) : min and max area of neighboring regions
%         seg.info(:,9) and seg_info(:,10) : min and max lengths of the minor axis of the neighboring regions
%         seg.info(:,11) and seg_info(:,12) : min and max lengths of the major axis of the neighboring regions
%         seg.info(:,11) : length of minor axis
%         seg.info(:,12) : length of major axis
%         seg.info(:,13) : square of length of major axis
%         seg.info(:,16) : max length of region projected onto the major axis
%         segment
%         seg.info(:,17) : min length of region projected onto the major axis
%         segment
%         seg.info(:,18) : max length of region projected onto the minor axis
%         segment
%         seg.info(:,19) : min length of region projected onto the minor axis
%         segment
%
% The output images are related by
% mask_cell = mask_bg .* (~segs_good) .* (~segs_3n);
%
%
% Written by Paul Wiggins and Keith Cheveralls
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

% Load the constants from the package settings file
MIN_BG_AREA     = CONST.superSeggerOpti.MIN_BG_AREA;
MAGIC_RADIUS    = CONST.superSeggerOpti.MAGIC_RADIUS;
MAGIC_THRESHOLD = CONST.superSeggerOpti.MAGIC_THRESHOLD;
CUT_INT         = CONST.superSeggerOpti.CUT_INT;
MIN_THRESHOLD   = CONST.superSeggerOpti.MIN_THRESHOLD;
MEAN_THRESHOLD  = CONST.superSeggerOpti.MEAN_THRESHOLD;
SMOOTH_WIDTH    = CONST.superSeggerOpti.SMOOTH_WIDTH;
MAX_WIDTH       = CONST.superSeggerOpti.MAX_WIDTH;
A               = CONST.superSeggerOpti.A;

if ~exist('header')
    header = [];
end

if ~exist('crop_box')
    crop_box = [];
end


% Initial image smoothing
%this step is necessary to reduce the camera and read noise in the raw
%phase image. Without it, the watershed algorithm will over-segment the
%image.
if CONST.ResFlag == CONST.R100X
    phase = imfilter(phase_,fspecial('disk',1),'replicate');
elseif CONST.ResFlag == CONST.R100XPa
    phase = imfilter(phase_,fspecial('disk',1),'replicate'); 
else
    phase = phase_;
end


% fix the range, set the max and min value of the phase image
mult_max = 2.5;
mult_min = 0.3;
mp       = mean(phase(:));
phase( phase > (mult_max*mp) ) = mult_max*mp;
phase( phase < (mult_min*mp) ) = mult_min*mp;


% if the size of the matrix is even, we get a half pixel shift in the
% position of the mask which turns out to be a probablem later.
f = fspecial('gaussian', 11, SMOOTH_WIDTH);
phase = imfilter(phase, f,'replicate');


% Create a Background mask
% we create the background mask MASK_BG by globally thresholding the band-pass
% filtered phase image. We determine the thresholds empirically.
% We use one threshold to remove the background, and another to remove
% the smaller background regions between cells.

if nargin < 2 || isempty(mask)
    % no background making mask
    filt_3 = fspecial( 'gaussian',25, 15 );
    filt_4 = fspecial( 'gaussian',5, 1/2 );
    mask_bg_ = make_bg_mask(phase,filt_3,filt_4,MIN_BG_AREA, CONST, crop_box);
else
    mask_bg_ = mask;
end

if nargin < 3 || isempty(disp_flag)
    disp_flag=1;
end

if nargin < 5 || isempty(adapt_flag)
    adapt_flag=1;
end

% Enhance inter-cellular image contrast
%this filter enhances the contrast of the phase image by subtracting from
%each pixel the minimum intensity in its neighborhood. It
%forces the interior of the cells closer to zero intensity.
phase = ag(phase);
phase__ = magicContrastFast2(phase, MAGIC_RADIUS);
phase = double(uint16(phase__-MAGIC_THRESHOLD));

% This cuts out bright spots from the mask
mask_mod = (phase>CUT_INT);
mask_bg = logical((mask_bg_-mask_mod)>0);

% Watershed the image
%here we use matlab's standard watershed algorithm to watershed just the
%cell-filled regions of the image.
phaseMask = uint8(agd(phase) + 255*(1-(mask_bg)));
ws = 1-(1-double(~watershed(phaseMask,8))).*mask_bg;


if adapt_flag
    % If the adapt_flag is set to true (on by default) it breaks regions 
    % that are too big to be cells. This function slows the code down, AND 
    % it significantly slows down the regionOpti code since there are many
    % more marginal segments to consider.

    wsc = 1- ws;
    regs_label = bwlabel( wsc );
    props = regionprops( regs_label, 'BoundingBox','Orientation' );
    
    num_wsc = max(regs_label(:));
    L1 = zeros(1,num_wsc);
    L2 = zeros(1,num_wsc);
    
    for ii = 1:num_wsc
        [xx,yy] = getBB(props(ii).BoundingBox);
        [L1(ii),L2(ii)] = makeRegionSizeProjectionBBint2( (regs_label(yy,xx)==ii), props(ii) );
        
        if L2(ii) > MAX_WIDTH;

            [xx,yy] = getBB( props(ii).BoundingBox );                        
            mask_reg = (regs_label(yy,xx)==ii);          
            
            pp = double(phase__(yy,xx)).*mask_reg;
            mm = 1-mask_reg;
            ppp = pp+max(pp(:))*mm;
            wsl = double(watershed( ppp )>0);
            wsl = (1-wsl).*mask_reg;
            
            % prune added segs by adding just enough to fix the cell width problem
            wsl_cc = compConn( wsl, 4 );
            wsl_3n = double(wsl_cc>2);
            wsl_segs = wsl-wsl_3n;
            wsl_label = bwlabel(wsl_segs,4);
            num_wsl_label = max(wsl_label(:));
            wsl_mins = zeros(1,num_wsl_label);
            for ff = 1:num_wsl_label
                wsl_mins(ff) = min(pp(ff==wsl_label));
            end
            [wsl_mins, sort_ord] = sort(wsl_mins,'descend');
            
            wsl_segs_good = wsl_3n;
            
            for ff = sort_ord;
                wsl_segs_good = wsl_segs_good + double(wsl_label==ff);
                mask_reg_tmp = mask_reg-wsl_segs_good;
                if maxMinAxis(mask_reg_tmp) < MAX_WIDTH
                    break
                end
            end 
            ws(yy,xx) = double(0<(ws(yy,xx) + wsl_segs_good));
        end
    end
end


% Determine the "good" and "bad" segments
[data] = defineGoodSegs(ws,phase,mask_bg,MIN_THRESHOLD, MEAN_THRESHOLD, A);
data.mask_cell = double((mask_bg - data.segs.segs_good - data.segs.segs_3n)>0);
data.phase = phase_;


% Calculate and return the final cell mask
if disp_flag
    figure(1)
    clf;
    showSegDataPhase(data);
    drawnow;
end



end


function [data] = defineGoodSegs(ws,phase,mask_bg,MIN_THRESHOLD,MEAN_THRESHOLD,A)
% defineGoodSegs is a sub function that uses intensity thresholds to
% segregate the set of segments produced by the watershed algorithm
% into "good" segments (segs_good) which lie along a real cellular
% boundary, and "bad" segments, which lie along spurious boundaries
% within single cells.
% note that we assume (safely) that the watershed always over- rather
% than under-segment the image. That is, the set of all real segments is
% contained with the set of all segments produced by the watershed algorithm.

sim = size( phase );

% Create labeled image of the segments
%here we obtain the cell-background boundary, which we know is correct.
sqr3 = strel('square',3);
disk1 = strel('disk',1);
outer_bound = xor(bwmorph(mask_bg,'dilate'),mask_bg);

% label the connected regions in the mask with an id 
% and calculate the properties
regs_label = bwlabel( ~ws, 8);
regs_prop = regionprops( regs_label,...
    {'BoundingBox','MinorAxisLength','MajorAxisLength','Area'});

% calculate the connectivity of each pixel in the segments
ws = double(ws.*mask_bg);
ws_cc = compConn( ws+outer_bound, 4 );

% segs_3n are the non-negotiable segments. They are on no matter what.
% this includes the outer boundary of the clumps (outer_bound), as well as the
% intersections between seg lines (pixels with connectivity_4 > 2).
segs_3n = double(((ws_cc > 2)+outer_bound)>0);

% segs are the guys that divide cells in the clumps that may or may not be
% on. Since we have removed all the intersections, we can label these and
% calculate their properties.
segs    = ws-segs_3n.*ws;

%turn on all the segs smaller than MIN_SEGS_SIZE
MIN_SEGS_SIZE = 2;
cc = bwconncomp( segs, 4 );
segs_props = regionprops(cc, 'Area');
logmask = [segs_props.Area] < MIN_SEGS_SIZE;

idx = find(logmask);
segs_3n = segs_3n + ismember(labelmatrix(cc), idx);
idx = find(~logmask);
segs = ismember(labelmatrix(cc), idx);

% redefine segs after eliminating the small segs and calculate all the
% region properties we will need.
% here we create coordinates to crop around each segment. This decreases the time
% required to process each segment.segs = double(segs_label>0);
segs_label = bwlabel( segs,4);
numSegs    = max( segs_label(:) );
segs_props = regionprops(  segs_label,  {'Area', 'BoundingBox','MinorAxisLength',...
    'MajorAxisLength', 'Orientation'} );

% segs_good is the im created by the segments that will be on
% segs_bad  is the im created by the rejected segs
segs_good  = false(sim);
segs_bad   = false(sim);

% these define the size of the image for use in crop sub regions in the
% loop--basically used to reduced the computation time.
xmin = 1;
ymin = 1;
xmax = sim(2);
ymax = sim(1);

% seg_info holds all the properties of each segment
seg_info = zeros(numSegs,19);

% score is a binary include (1)/exclude (0) flag generated
% by a vector multiplcation of A with seg_info.
score    = zeros(numSegs,1);
scoreRaw = zeros(numSegs,1);


% Loop through all segments to decide which are good and which are
% bad.
for ii = 1:numSegs
    
    % Crop around each segment with two pixels of padding in x and y
    [xx,yy] = getBBpad( segs_props(ii).BoundingBox, sim, 2 );
    
    % here we get the cropped segment mask and corresponding phase image
    mask_ii  = (segs_label(yy, xx) == ii);
    phase_ii = phase(yy, xx);
    sim_ii   = size(phase_ii);
    regs_label_ii = regs_label(yy,xx);
    %and its length
    nn = segs_props(ii).Area;
    
    % mask_ii_out are the pixels around the segment so that a second d over
    % the segment can be computed.
    if nn>2
        mask_ii_end  = (compConn(mask_ii,4)==1);
        mask_ii_out  = xor(bwmorph( xor(mask_ii,mask_ii_end), 'dilate' ),mask_ii);
    elseif nn == 1
        mask_ii_out  = xor(bwmorph( mask_ii, 'dilate'),mask_ii);
    else
        mask_ii_out  = imdilate( mask_ii, disk1)-mask_ii;
        mask_ii_out  = and(mask_ii_out,(compConn(mask_ii_out,4)>0));
    end
    
    % seg_info(:,1) is the minimum phase intensity on the seg
    [seg_info(ii,1),ind] = min(phase_ii(:).*double(mask_ii(:))+1e6*double(~mask_ii(:)));
    
    % seg_info(:,2) is the mean phase intensity on the seg
    seg_info(ii,2) = mean(phase_ii(mask_ii));
    
    % seg_info(:,3) is area of the seg
    seg_info(ii,3) = nn;
    
    % seg_info(:,4) is the mean second d of the phase normal to the seg
    seg_info(ii,4) = mean(phase_ii(mask_ii_out)) - seg_info(ii,2);
    
    % next we want to do some more calculation around the minimum phase
    % pixel. sub1 and sub2 are the indicies in the cropped image
    [sub1,sub2] = ind2sub(sim_ii,ind);
    % sub1_ and sub2_ are the indices in the whole image.
    %     sub1_ = sub1-1+yymin;
    %     sub2_ = sub2-1+xxmin;
    
    % calculate the local second d of the phase at the min pixel
    % normal to the seg and parallel to it.
    % min_pixel is the mask of the min pixel
    min_pixel = false(sim_ii);
    min_pixel(sub1,sub2) = true;
    % outline the min pixel
    min_pixel_out = bwmorph( min_pixel, 'dilate');
    % and mask/anti-mask it
    ii_min_para   = and(min_pixel_out,mask_ii);
    ii_min_norm   = xor(min_pixel_out,ii_min_para);
    
    % seg_info(:,5) is the second d of the phase normal to the seg at the
    % min pixel
    seg_info(ii,5) = mean(phase_ii(ii_min_norm))-mean(phase_ii(ii_min_para));
    
    % seg_info(:,6) is the second d of the phase parallel to the seg at the
    % min pixel
    tmp_mask = xor(ii_min_para,min_pixel);
    seg_info(ii,6) = mean(phase_ii(tmp_mask))-seg_info(ii,1);
    
    if isnan(seg_info(ii,6))
        disp([header,'NaN in seg_info!']);
    end
    
    % We also wish to add information about the neighboring regions. First we
    % have to determine what these regions are... ie the regs_label number
    % By construction, each seg touches two regions. Ind_reg is the vector
    % of the region indexes--after we eliminate '0'.
    uu = regs_label_ii(imdilate( mask_ii, disk1));
    ind_reg = unique(uu(logical(uu)));
    
    % seg_info(:,7) and seg_info(:,8) are the min and max area of the
    % neighboring regions
    seg_info(ii,7)  = min( regs_prop(ind_reg(:)).Area);
    seg_info(ii,8)  = max( regs_prop(ind_reg(:)).Area);
    
    % seg_info(:,9) and seg_info(:,10) are the min and max minor axis
    % length of the neighboring regions
    seg_info(ii,9)  = min( regs_prop(ind_reg(:)).MinorAxisLength);
    seg_info(ii,10) = max( regs_prop(ind_reg(:)).MinorAxisLength);
    
    % seg_info(:,11) and seg_info(:,12) are the min and max major axis
    % length of the neighboring regions
    seg_info(ii,11) = min( regs_prop(ind_reg(:)).MajorAxisLength);
    seg_info(ii,12) = max( regs_prop(ind_reg(:)).MajorAxisLength);
    
    % seg_info(:,11), seg_info(:,12), and seg_info(:,13) are the min
    % and max major axis length of the segment itself, including the
    % square of the major axis length... which would allow a non-
    % linarity in the length cutoff. No evidence that this helps...
    % just added it because I could.
    seg_info(ii,13) = segs_props(ii).MinorAxisLength;
    seg_info(ii,14) = segs_props(ii).MajorAxisLength;
    seg_info(ii,15) = segs_props(ii).MajorAxisLength^2;
    
    
    % Next we want to do some calculation looking at the size of
    % the regions, normal and parallel to the direction of the
    % segment. This is a bit computationally expensive, but worth
    % it I think.
    
    % Get size of the regions in local coords
    
    % This function computes the principal axes of the segment
    % mask. e1 is aligned with the major axis and e2 with the
    % minor axis and com is the center of mass.
    [e1,e2] = makeRegionAxisFast( segs_props(ii).Orientation );
    
    % L1 is the length of the projection of the region on the
    % major axis and L2 is the lenght of the projection on the
    % minor axis.
    L1 = [0 0];
    L2 = [0 0];
    
    % Loop through the two regions
    
    
    for kk = 1:numel(ind_reg);
        % get a new cropping region for each region with 2 pix padding
        [xx_,yy_] = getBBpad(regs_prop(ind_reg(kk)).BoundingBox,sim,2);
        
        
        % mask the region of interest
        kk_mask = (regs_label(yy_, xx_) == ind_reg(kk));
        
        % This function computes the projections lengths on e1 and e2.
        [L1(kk),L2(kk)] = makeRegionSize( kk_mask,e1,e2);
    end
    
    % seg_info(:,16) and seg_info(:,17) are the min and max Length of the
    % regions projected onto the major axis of the segment.
    seg_info(ii,16) = max(L1); % max and min region length para to seg
    seg_info(ii,17) = min(L1);
    % seg_info(:,16) and seg_info(:,17) are the min and max Length of the
    % regions projected onto the minor axis of the segment.
    seg_info(ii,18) = max(L2); % max and min region length normal to seg
    seg_info(ii,19) = min(L2);
    
    
    % Calculate the score to determine if the seg will be included.
    % if score is less than 0 set the segment off
    scoreRaw(ii) = segmentScoreFun( seg_info(ii,:), A );
    score(ii) = double( 0 < scoreRaw (ii));
    
    % update the good and bad segs images.
    
    if score(ii)
        segs_good(yy, xx)  = or(segs_good(yy, xx),mask_ii);
    else
        segs_bad(yy, xx)   = or(segs_bad(yy, xx),mask_ii);
    end
    
end


data = [];

data.segs.phaseMagic  = phase;

data.mask_bg          = mask_bg;
data.segs.segs_good   = segs_good;
data.segs.segs_bad    = segs_bad;
data.segs.segs_3n     = segs_3n;
data.segs.info        = seg_info;
data.segs.segs_label  = segs_label;
data.segs.score       = score;
data.segs.scoreRaw    = scoreRaw;
data.segs.props       = segs_props;
end


function Lmax = maxMinAxis(mask)

mask_label = bwlabel(mask);
props = regionprops( mask_label, 'Orientation' );
num_regs = max(mask_label(:));
Lmax = 0;

for ii = 1:num_regs
    [L1,L2] = makeRegionSizeProjectionBBint2( (mask_label==ii), props(ii) );
    Lmax = max([Lmax,L2]);
end
end




