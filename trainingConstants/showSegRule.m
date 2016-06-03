function showSegRule( data, FLAGS, figNum,CONST )
% showSegRule : shows the segmentation for regions and segments
%
% INPUT :
%       data : data file with segmentation information.
%       FLAGS :
%           .im_flag = 1 : segment view ,
%                      2 : region view,
%                      3 : false color,
%                      4 : phase image
%           .S_flag = segments/regions' scores
%           .t_flag = segments/regions' labels
%           .Sj_flag = shows disagreeing segments scores (S_flag must be on
%           too)
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins & Stella Stylianidou.
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

if (~exist('FLAGS','var') || isempty(FLAGS)) || ~isfield( FLAGS, 'im_flag' )
    FLAGS.im_flag=2;
end

im_flag = FLAGS.im_flag;

if ~isfield( FLAGS, 'S_flag' ) % shows all segments scores
    FLAGS.S_flag = 0;
end

S_flag = FLAGS.S_flag;

if ~isfield( FLAGS, 't_flag' ) % labels for segments
    FLAGS.t_flag = 1;
end

t_flag = FLAGS.t_flag;


if ~isfield( FLAGS, 'phase' ) % labels for segments
    FLAGS.phase = 0 ;
end

% shows scores for segments/regions that computer/user disagrees
if ~isfield( FLAGS, 'Sj_flag' )
    FLAGS.Sj_flag = 0;
end

Sj_flag = FLAGS.Sj_flag;

if ~exist('figNum','var') || isempty(figNum)
    figNum = 4;
end

figure(figNum);
axis_current = axis;
clf;

segs_good      = zeros( size( data.phase ) );
segs_good_fail = segs_good;
segs_bad       = segs_good;
segs_bad_fail  = segs_good;
segs_Include   = segs_good;
num_segs = numel( data.segs.score(:) );

sz = size(segs_good);
backer = 0.7*ag(data.phase);

if im_flag == 1
    
    isnan_scoreraw = isnan(data.segs.scoreRaw);
    isnan_score = isnan(data.segs.score);
    data.segs.score(isnan_score) = 0;
    data.segs.scoreRaw(isnan_scoreraw) = 0;
    
    if ~isfield(data.segs, 'Include' )
        data.segs.Include = 0*data.segs.score+1;
    end
    
    %segs_Include   = ismember( data.segs.segs_label, find(~data.segs.Include));
   
    segs_good      = ismember( data.segs.segs_label, find((data.segs.score)));
    segs_bad       = ismember( data.segs.segs_label, find((~data.segs.score)));
%     
%     segs_good      = ismember( data.segs.segs_label, find(and( ~isnan_score, and(data.segs.score,round(data.segs.scoreRaw)))));
%     segs_good_fail = ismember( data.segs.segs_label, find(and( ~isnan_score, and(data.segs.score,~round(data.segs.scoreRaw)))));
%     segs_bad_fail  = ismember( data.segs.segs_label, find(and( ~isnan_score, and(~data.segs.score,round(data.segs.scoreRaw)))));
%     segs_bad       = ismember( data.segs.segs_label, find(and( ~isnan_score, and(~data.segs.score,~round(data.segs.scoreRaw)))));
%     
    %segsInlcudeag  = ag(segs_Include);
    segsGoodag  = ag(segs_good);
    segsGoodFailag = ag(segs_good_fail);
    segs3nag = ag(data.segs.segs_3n  );
    segsBadag  = ag(segs_bad );
    segsBadFailag = ag(segs_bad_fail);
    %maskBgag = ag(~data.mask_bg);
    
    if FLAGS.phase
        phaseBackag = uint8(ag(data.segs.phaseMagic));
    else
        phaseBackag = uint8(ag(~data.mask_cell));
    end
    
    imshow( uint8(cat(3,...
            0.1*phaseBackag + 0.3*segs3nag +0.6*(segsGoodag + segsGoodFailag), ...
            0.15*phaseBackag + 0.1*segs3nag + 0.4*(segsGoodFailag+segsBadFailag), ...
            0.2*phaseBackag + 0.4*(segsBadag + segsBadFailag))), ...
            'InitialMagnification', 'fit','Border','tight');
    
    
    flagger = and( data.segs.Include, ~isnan(data.segs.score) );
    scoreRawTmp = data.segs.scoreRaw(flagger);
    scoreTmp    = data.segs.score(flagger);
    [y_good,x_good] = hist(scoreRawTmp(scoreTmp>0),[-40:2:40]);
    [y_bad,x_bad] = hist(scoreRawTmp(~scoreTmp),[-40:2:40]);

    figure(figNum);
    props = regionprops( data.segs.segs_label, 'Centroid'  );
    num_segs = numel(props);
    
    if S_flag && (~t_flag)
        for ii = 1:num_segs
            r = props(ii).Centroid;
            tmp_flag = double(round(data.segs.scoreRaw(ii)))-double(data.segs.score(ii));
            if tmp_flag == 0
                if ~Sj_flag
                    text( r(1), r(2), num2str( data.segs.scoreRaw(ii), 2), 'Color', [0.5,0.5,0.5] );
                end
            else
                if data.segs.Include(ii)
                    text( r(1), r(2), num2str( data.segs.scoreRaw(ii), 2), 'Color', 'w' );
                elseif ~Sj_flag
                    text( r(1), r(2), num2str( data.segs.scoreRaw(ii), 2), 'Color', 'g' );
                end
            end
        end
    end
    
    if t_flag
        for ii = 1:num_segs
            
            r = props(ii).Centroid;
            text( r(1), r(2), num2str( ii ), 'Color', 'w' );
        end
    end
    
    
elseif im_flag == 2 % region view
    
    if ~isfield(data,'regs')
        data = updateRegionFields (data,CONST)
    end
    num_regs = data.regs.num_regs;
    
    if isfield(data.regs,'score')
    regs_good_agree = 0.3*double(ag(ismember(data.regs.regs_label,find(data.regs.score & round(data.regs.scoreRaw)))));
    regs_good_disagree = double(ag(ismember(data.regs.regs_label,find(data.regs.score & ~round(data.regs.scoreRaw)))));
    
    regs_bad_agree = 0.3*double(ag(ismember(data.regs.regs_label,find(~data.regs.score & ~round(data.regs.scoreRaw)))));
    regs_bad_disagree = double(ag(ismember(data.regs.regs_label,find(~data.regs.score & round(data.regs.scoreRaw)))));
    
    imshow( cat(3, 0.5*backer + 1*uint8(regs_good_agree+regs_good_disagree), ...
        0.5*backer, ...
        0.5*backer + 1*uint8(regs_bad_agree+regs_bad_disagree)) , 'InitialMagnification', 'fit');
    else
       % imshow(label2rgb(data.regs.regs_label))
         
        imshow( cat(3, 0.8*backer + 1*ag(data.mask_cell), ...
        0.8*backer, ...
        0.8*backer) , 'InitialMagnification', 'fit');
  
        
    end
    
    
    if S_flag && (~t_flag)
        for ii = 1:num_regs            
            r = data.regs.props(ii).Centroid;
            flagger = 1;
            if isfield (data.regs,'score')
            flagger =  logical(data.regs.score(ii)) == round(data.regs.scoreRaw(ii)); 
            end
            if flagger
                text( r(1), r(2), num2str( data.regs.scoreRaw(ii), 2), 'Color', 'w' );
            elseif ~Sj_flag
                text( r(1), r(2), num2str( data.regs.scoreRaw(ii), 2), 'Color', [0.5,0.5,0.5] );
            end
        end        
    end
    
    if t_flag
        for ii = 1:num_regs
            r = data.regs.props(ii).Centroid;
            text( r(1), r(2), num2str( ii ), 'Color', 'w' );
            %text( r(1), r(2), num2str( data.regs.props(ii).Orientation ), 'Color', 'w' );
        end
    end
    
elseif im_flag == 3 % phase image in jet color
    
    imshow( data.segs.phaseMagic, [], 'InitialMagnification', 'fit' );
    colormap jet;
    
elseif im_flag == 4 % phase image
    
    backer = ag(data.phase);
    imshow( cat(3,backer,backer,backer), 'InitialMagnification', 'fit' );
elseif im_flag == 5
    
cell_mask = data.mask_cell;
segs_3n = data.segs.segs_3n ;
segs_good = data.segs.segs_good;   
segs_bad = data.segs.segs_bad  ;

back = double(0.7*ag( data.phase ));
outline = imdilate( cell_mask, strel( 'square',3) );
outline = ag(outline-cell_mask);
  
        clf
        imshow(uint8(cat(3,back + 0.1*double(outline)+ double(ag(segs_good+segs_3n)),...
            back ,...
            back + 0.2*double(ag(segs_bad))+ 0.2*double(ag(~cell_mask)-outline))));

    drawnow;
end

% if ~all(axis_current == [ 0     1     0     1])
%     axis(axis_current);
% end

end