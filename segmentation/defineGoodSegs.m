function [data] = defineGoodSegs(data, ws, phaseNorm, C2phaseThresh, ...
    mask_bg, A, CONST, calcScores)

% defineGoodSegs is a sub function that uses intensity thresholds to
% segregate the set of segments produced by the watershed algorithm
% into "good" segments (segs_good) which lie along a real cellular
% boundary, and "bad" segments, which lie along spurious boundaries
% within single cells.
% note that we assume (safely) that the watershed always over- rather
% than under-segment the image. That is, the set of all real segments is
% contained with the set of all segments produced by the watershed algorithm.



sim = size( phaseNorm );

% Create labeled image of the segments
%here we obtain the cell-background boundary, which we know is correct.
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
% required to process each segment
segs_label = bwlabel( segs,4);
numSegs    = max( segs_label(:) );
segs_props = regionprops(segs_label,  {'Area', 'BoundingBox','MinorAxisLength',...
    'MajorAxisLength', 'Orientation', 'Centroid' } );

[~, ~, ~, ~, ~, G, C1, C2, f_xx, f_yy, f_xy] = curveFilter (double(phaseNorm),1.5);
G_ = G;
G_(G_>0) = 0;


segs_props_tmp = regionprops(segs_label, G, 'MeanIntensity' );

[segs_props(:).G] = deal (segs_props_tmp.MeanIntensity);

segs_props_tmp = regionprops(segs_label, G_, 'MeanIntensity' );
[segs_props(:).G_] = deal (segs_props_tmp.MeanIntensity);

segs_props_tmp = regionprops(segs_label, C1, 'MeanIntensity' );
[segs_props(:).C1] = deal (segs_props_tmp.MeanIntensity);

segs_props_tmp = regionprops(segs_label, C2, 'MeanIntensity' );
[segs_props(:).C2] = deal (segs_props_tmp.MeanIntensity);

segs_props_tmp = regionprops(segs_label, f_xx, 'MeanIntensity' );
[segs_props(:).f_xx] = deal (segs_props_tmp.MeanIntensity);

segs_props_tmp = regionprops(segs_label, f_yy, 'MeanIntensity' );
[segs_props(:).f_yy] = deal (segs_props_tmp.MeanIntensity);

segs_props_tmp = regionprops(segs_label, f_xy, 'MeanIntensity' );
[segs_props(:).f_xy] = deal (segs_props_tmp.MeanIntensity);


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

% Make the segs_info:
num_info = CONST.superSeggerOpti.NUM_INFO;
seg_info = nan(numSegs,num_info);

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
    segs_props_tmp = [];
    
    segs_props_tmp.mask = logical(segs_label(yy, xx) == ii);
    segs_props_tmp.phase = phaseNorm(yy, xx);
    segs_props_tmp.phaseC2 = C2phaseThresh(yy,xx);
    segs_props_tmp.regs_label = regs_label(yy,xx);
    segs_props_tmp.sim = sim;
    
    seg_info(ii,:) = CONST.seg.segScoreInfo( segs_props(ii),segs_props_tmp,...
        regs_prop,regs_label,disk1);
    
    if calcScores    
        % Calculate the score to determine if the seg will be included.
        % if score is less than 0 set the segment off
        [scoreRaw(ii)] = CONST.seg.segmentScoreFun( seg_info(ii,:), A );
        score(ii) = double( 0 < scoreRaw (ii));

        % update the good and bad segs images.

        if score(ii)
            segs_good(yy,xx) = or(segs_good(yy, xx),  segs_props_tmp.mask);
        else
            segs_bad(yy,xx) = or(segs_bad(yy, xx),  segs_props_tmp.mask);
        end
    end
    
end
data.segs.phaseC2     = C2phaseThresh;
data.segs.phaseNorm   = phaseNorm;
data.mask_bg          = mask_bg;
data.segs.segs_good   = segs_good;
data.segs.segs_bad    = segs_bad;
data.segs.segs_3n     = segs_3n;
data.segs.info        = seg_info;
data.segs.segs_label  = segs_label;
data.segs.score       = score;
data.segs.scoreRaw    = scoreRaw;
data.segs.props       = segs_props;

%intShowSegScore( data, reshape([drill(segs_props,'.Centroid(1)'),...
%    drill(segs_props,'.Centroid(2)')],[numel(segs_props),2]) , 23 );

end
