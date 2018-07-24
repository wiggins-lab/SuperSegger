function [data,A]  = superSeggerOpti(phaseOrData, mask, disp_flag, CONST, adapt_flag, header, crop_box)
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
%       phaseOrData : phase image or data file to be used
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
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou & Paul Wiggins.
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

% Load the constants from the package settings file

%% Handles inputs here
MIN_BG_AREA     = CONST.superSeggerOpti.MIN_BG_AREA;
MAGIC_RADIUS    = CONST.superSeggerOpti.MAGIC_RADIUS;
MAGIC_THRESHOLD = CONST.superSeggerOpti.MAGIC_THRESHOLD;
CUT_INT         = CONST.superSeggerOpti.CUT_INT;
SMOOTH_WIDTH    = CONST.superSeggerOpti.SMOOTH_WIDTH;
MAX_WIDTH       = CONST.superSeggerOpti.MAX_WIDTH;
verbose         = CONST.parallel.verbose;


if ~isfield( CONST.seg, 'segScoreInfo' )
    CONST.seg.segScoreInfo = @segInfoL2;
end

if ~exist('header','var')
    header = [];
end

if ~exist('crop_box','var')
    crop_box = [];
end

if ~exist('adapt_flag','var')
    adapt_flag = 1;
end

if ~exist('mask','var')
    mask = [];
end

mask_colonies = [];

% If data structure is passed, rescue the phase image and mask
if isstruct( phaseOrData )
    data  = phaseOrData;
    phaseOrig = data.phase;
    dataFlag  = true;
    segs_old = data.segs;
        
    % Copy the mask from data into mask if it is empty 
    if isempty( mask )
        mask  = data.mask_bg;
    end
else
    phaseOrig = phaseOrData;
    dataFlag  = false;
    data       = [];
    data.phase = phaseOrig;
end

%% Start segementation process here

% Initial image smoothing to reduce the camera and read noise in the raw
% phase image. Without it, the watershed algorithm will over-segment the
% image.
if all(ismember('100X',CONST.ResFlag))
    phaseNorm = imfilter(phaseOrig,fspecial('disk',1),'replicate');
else
    phaseNorm = phaseOrig;
end

% fix the range, set the max and min value of the phase image
mult_max = 2.5;
mult_min = 0.3;
mean_phase = mean(phaseNorm(:));
phaseNorm(phaseNorm > (mult_max*mean_phase)) = mult_max*mean_phase;
phaseNorm(phaseNorm < (mult_min*mean_phase)) = mult_min*mean_phase;

% Filter to remove internal structure from phase image ofcells here 
% (and little pieces of debris from the background
if isfield( CONST.superSeggerOpti, 'remove_int_struct' ) && ...    
        CONST.superSeggerOpti.remove_int_struct.flag
        tmp_im = imclose( phaseNorm, strel('disk',...
           CONST.superSeggerOpti.remove_int_struct.radius ));
       W = CONST.superSeggerOpti.remove_int_struct.weight;
       phaseNorm = (1-W)*phaseNorm + W*tmp_im;
end


% if the size of the matrix is even, we get a half pixel shift in the
% position of the mask which turns out to be a problem later.

% autogain smoothed image
f = fspecial('gaussian', 11, SMOOTH_WIDTH);
phaseNormFilt = imfilter(phaseNorm, f,'replicate');
[phaseNormFilt,imin,imax] = ag(phaseNormFilt);

% autogained non smoothed phase image
phaseNormUnfilt = (double(phaseOrig)-imin)/(imax-imin); 

% Minimum constrast filter to enhance inter-cellular image contrast
magicPhase = magicContrast(phaseNormFilt, MAGIC_RADIUS);

% C2phase is the Principal curvature 2 of the image without negative values
% it also enhances subcellular contrast. We subtract the magic threshold
% to remove the variation in intesnity within a cell region.
[~,~,~,C2phase] = curveFilter (double(phaseNormFilt),1);
C2phaseThresh = double(uint16(C2phase-MAGIC_THRESHOLD));


% creates initial background mask by globally thresholding the band-pass
% filtered phase image. We determine the thresholds empirically.
% We use one threshold to remove the background, and another to remove
% the smaller background regions between cells.
if isempty(mask)
    % no background making mask
    filt_3 = fspecial('gaussian',25, 15);
    filt_4 = fspecial('gaussian',5, 1/2);
    mask_colonies = makeBgMask(phaseNormFilt, filt_3, filt_4, MIN_BG_AREA, CONST, crop_box);
    
    [~,~,~,~,~,K,~,~] = curveFilter(phaseNormUnfilt, 3 );
    aK = abs(K);

    
    if CONST.superSeggerOpti.remove_debris
        mask_colonies = removeDebris(mask_colonies, phaseNormUnfilt, aK, CONST);
    end

    
    % remove bright halos from the mask
    mask_halos = (magicPhase>CUT_INT);
    mask_bg = logical((mask_colonies-mask_halos)>0);
    
    % removes micro-colonies with background level outline intensity - not bright enough
    
    if CONST.superSeggerOpti.remove_microcolonies
        mask_bg = intRemoveFalseMicroCol(mask_bg, phaseOrig, CONST);
    end
    
else
    mask_bg = mask;
end

if nargin < 3 || isempty(disp_flag)
    disp_flag=1;
end

if nargin < 5 || isempty(adapt_flag)
    adapt_flag=1;
end


% Remove CellASIC pillars here
if isfield( CONST.superSeggerOpti, 'remove_pillars' ) &&  ...
    CONST.superSeggerOpti.remove_pillars.flag 
    mask_to_remove = ~intRemovePillars(phaseOrig,CONST);
    mask_bg(mask_to_remove) = false;
end

%% Split up the micro colonies into watershed regions to assemble cells
% if data exists, reconstruct ws
if dataFlag
    ws = logical(~data.mask_bg+data.segs.segs_3n+data.segs.segs_bad+data.segs.segs_good);
else
    % watershed just the cell mask to identify segments
    phaseMask = uint8(agd(C2phaseThresh) + 255*(1-(mask_bg)));
    ws = 1-(1-double(~watershed(phaseMask,8))).*mask_bg;
    
    if adapt_flag
        % If the adapt_flag is set to true (on by default) it watersheds the C2phase
        % without using the thershold to identify more segments. It atempts to
        % breaks regions that are too big to be cells. This function slows the
        % code down, AND slows down the regionOpti code.
        
        wsc = 1- ws;
        regs_label = bwlabel( wsc );
        props = regionprops( regs_label, 'BoundingBox','Orientation','MajorAxisLength','MinorAxisLength');
        L2 = [props.MinorAxisLength];
        wide_regions = find(L2 > MAX_WIDTH);
        
        for ii = wide_regions
            [xx,yy] = getBB( props(ii).BoundingBox );
            mask_reg = (regs_label(yy,xx)==ii);
            
            c2PhaseReg = double(C2phase(yy,xx)).*mask_reg;
            invC2PhaseReg = 1-mask_reg;
            ppp = c2PhaseReg+max(c2PhaseReg(:))*invC2PhaseReg;
            wsl = double(watershed(ppp)>0);
            wsl = (1-wsl).*mask_reg;
            
            % prune added segs by adding just enough to fix the cell width problem
            wsl_cc = compConn( wsl, 4 );
            wsl_3n = double(wsl_cc>2);
            wsl_segs = wsl-wsl_3n;
            wsl_label = bwlabel(wsl_segs,4);
            num_wsl_label = max(wsl_label(:));
            wsl_mins = zeros(1,num_wsl_label);
            
            debug_flag = 0;
            if debug_flag
                backer = 0.5*ag(ppp);
                imshow(cat(3,backer,backer,backer + ag(wsl_segs)),[]);
                keyboard;
            end
            
            for ff = 1:num_wsl_label
                wsl_mins(ff) = min(c2PhaseReg(ff==wsl_label));
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
            
            tmp_3s = compConn( logical(wsl_segs_good), 4 );
            tmp_3s([1,end],:) = 0;
            tmp_3s(:,[1,end]) = 0;
            
            wsl_segs_good(tmp_3s==0)=0;
            
            ws(yy,xx) = double(0<(ws(yy,xx) + wsl_segs_good));
        end
    end
end

%% Remake the data structure

% Determine the "good" and "bad" segments
data.mask_bg       = mask_bg;
data.phaseNorm     = phaseNormUnfilt;
data.C2phaseThresh = C2phaseThresh;

data = defineGoodSegs(data, ws, CONST, ~dataFlag );

data.mask_colonies = mask_colonies;

% copy the existing score into the data structure
if dataFlag
    data.segs.score = nan( [size(data.segs.info,1),1] );
    % map the regions
    props_tmp = regionprops( data.segs.segs_label, segs_old.segs_label, {'MinIntensity','MaxIntensity'} );
    tmp_min = [props_tmp.MinIntensity];
    tmp_max = [props_tmp.MaxIntensity];
    
    [y,x] = hist( tmp_max, 0:max(tmp_max));
    good_club = x(y==1);
    flagger = and( ismember( tmp_max,good_club), and(tmp_min==tmp_max,tmp_min>0));
    
    data.segs.score( flagger ) = segs_old.score(  tmp_max(flagger) );
    data.segs.score( ~flagger )  = nan;
    
    data.segs.segs_good = segs_old.segs_good;
    data.segs.segs_bad  = segs_old.segs_bad;
    data.segs.segs_3n   = segs_old.segs_3n;
end

% Calculate and return the final cell mask
data.mask_cell = double((mask_bg - data.segs.segs_good - data.segs.segs_3n)>0);


if disp_flag
    figure( 'name', 'SuperSegger frame segmentation' )
    clf;
    showSegDataPhase(data);
    drawnow;
end

end

function Lmax = maxMinAxis(mask)
% maxMinAxis : calculates maximum minor axis length of the regions in the mask.
mask_label = bwlabel(mask);
props = regionprops( mask_label, 'Orientation', 'MinorAxisLength' );
Lmax =  max([props.MinorAxisLength]);
end

