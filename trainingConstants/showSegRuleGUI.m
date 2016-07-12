function showSegRuleGUI( data, FLAGS, viewport )
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
%       viewport : display axis
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

if ~isfield( FLAGS, 'index_score' ) % labels for segments
    FLAGS.index_score = [];
end
index_score = FLAGS.index_score;

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

segs_good      = zeros( size( data.phase ) );
segs_good_fail = segs_good;
segs_bad       = segs_good;
segs_bad_fail  = segs_good;
segs_Include   = segs_good;
num_segs = numel( data.segs.score(:) );

sz = size(segs_good);
backer = 0.7*ag(data.phase);

if ~exist('viewport','var') || isempty(viewport)
    figure;
else
    axes(viewport);
end


if im_flag == 1
    
    rawSegScore = data.segs.scoreRaw;
    if size(rawSegScore, 2) > size(rawSegScore, 1)
        rawSegScore = rawSegScore';
    end
    
    
    rawSegScore = round(rawSegScore > 0);
    isnan_rawscore = isnan(rawSegScore);
    rawSegScore(isnan_rawscore) = 0;
    isnan_score = isnan(data.segs.score);
    data.segs.score(isnan_score) = 0;
    
    if isempty(data.segs.score)
        segs_good      = data.segs.segs_label*0;
        segs_good_fail = data.segs.segs_label*0;
        segs_bad_fail  = data.segs.segs_label*0;
        segs_bad  =data.segs.segs_label*0;
    else
        segs_good      = ismember( data.segs.segs_label, find(and( ~isnan_score, and(data.segs.score,rawSegScore))));
        segs_good_fail = ismember( data.segs.segs_label, find(and( ~isnan_score, and(data.segs.score,~rawSegScore))));
        segs_bad_fail  = ismember( data.segs.segs_label, find(and( ~isnan_score, and(~data.segs.score,rawSegScore))));
        segs_bad       = ismember( data.segs.segs_label, find(and( ~isnan_score, and(~data.segs.score,~rawSegScore))));
    end
    str = strel('square',2);
    
    segs_good = imdilate(double(segs_good), str);
    segs_good_fail = imdilate(double(segs_good_fail), str);
    segs_bad_fail = imdilate(double(segs_bad_fail), str);
    segs_bad = imdilate(double(segs_bad),str);
    
    segsGoodag  = ag(segs_good);
    segsGoodFailag = ag(segs_good_fail);
    segs3nag = ag(data.segs.segs_3n);
    segsBadag  = ag(segs_bad );
    segsBadFailag = ag(segs_bad_fail);
    
    if FLAGS.phase
        phaseBackag = uint8(ag(data.segs.phaseMagic));
    else
        phaseBackag = uint8(ag(~data.mask_cell));
    end
    
    
    imshow( cat(3, 0.2*phaseBackag + 0.3*segs3nag + uint8(segsGoodag+segsGoodFailag+0.5*segsBadFailag), ...
        0.2*phaseBackag + 0.3*segs3nag + 0.8*uint8(segsGoodFailag+segsBadFailag) , ...
        0.2*phaseBackag + 0.3*segs3nag + uint8(segsBadag+segsBadFailag + 0.2 * segsGoodFailag) ), 'InitialMagnification', 'fit');
    
    props = regionprops( data.segs.segs_label, 'Centroid'  );
    num_segs = numel(props);
    
    if S_flag && (~t_flag)
        for ii = 1:num_segs
            r = props(ii).Centroid;
            
            if isempty(index_score) || index_score(1) < 1 || index_score(1) > size(data.segs.info,2)
                score_tmp =  data.segs.scoreRaw(ii);
            else
                score_tmp =  data.segs.info(ii,index_score);
            end
            
            tmp_flag = ((score_tmp>0) == (data.segs.score(ii)));
                       
            
            if tmp_flag == 0
                if ~Sj_flag
                    text( r(1), r(2), num2str( score_tmp, 2), 'Color', [0.5,0.5,0.5] );
                end
            else
                if isfield (data.segs, 'Include') && data.segs.Include(ii)
                    text( r(1), r(2), num2str( score_tmp, 2), 'Color', 'w' );
                elseif ~Sj_flag
                    text( r(1), r(2), num2str( score_tmp, 2), 'Color', 'g' );
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
        error ('no region fields');
        return;
    end
    num_regs = data.regs.num_regs;
    
    if isfield(data.regs,'score')
        regs_good_agree = double(ag(ismember(data.regs.regs_label,find(data.regs.score & round(data.regs.scoreRaw > 0)))));
        regs_good_disagree = double(ag(ismember(data.regs.regs_label,find(data.regs.score & ~round(data.regs.scoreRaw > 0)))));
        
        regs_bad_agree = double(ag(ismember(data.regs.regs_label,find(~data.regs.score & ~round(data.regs.scoreRaw > 0)))));
        regs_bad_disagree = double(ag(ismember(data.regs.regs_label,find(~data.regs.score & round(data.regs.scoreRaw > 0)))));
        
        
        imshow( cat(3, 0.2*backer + uint8(regs_good_agree+regs_good_disagree+0.5*regs_bad_disagree),...
            0.2*backer + 0.8 * uint8(regs_good_disagree+regs_bad_disagree),...
            0.2*backer + uint8(regs_bad_agree + regs_bad_disagree + 0.2*regs_good_disagree)), 'InitialMagnification', 'fit');
        
    else
        imshow( cat(3, 0.8*backer + ag(data.mask_cell), ...
            0.8*backer, ...
            0.8*backer) , 'InitialMagnification', 'fit');
    end
    
    
    if S_flag && (~t_flag)
        for ii = 1:num_regs
            r = data.regs.props(ii).Centroid;
            flagger = 1;
            
            if isfield (data.regs,'score')
                if isempty(index_score) || index_score(1) < 1 || index_score(1) > size(data.regs.info,2)
                    score_tmp =  data.regs.scoreRaw(ii);
                else
                    score_tmp =  data.regs.info(ii,index_score);
                end

                flagger = ((score_tmp>0) == (data.regs.score(ii)));

                if flagger
                    text( r(1), r(2), num2str( score_tmp, 2), 'Color', 'w' );
                elseif ~Sj_flag
                    text( r(1), r(2), num2str( score_tmp, 2), 'Color', [0.5,0.5,0.5] );
                end
            end
        end
    end
    
    if t_flag
        for ii = 1:num_regs
            r = data.regs.props(ii).Centroid;
            text( r(1), r(2), num2str( ii ), 'Color', 'w' );
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
    
    imshow(uint8(cat(3,back + 0.1*double(outline)+ double(ag(segs_good+segs_3n)),...
        back ,...
        back + 0.2*double(ag(segs_bad))+ 0.2*double(ag(~cell_mask)-outline))));
    
    drawnow;
end


end