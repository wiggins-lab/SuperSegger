function showSegRule( data, FLAGS )
% showSegRule : shows the segmentations rules for regions and segments
%
% INPUT :
%       data :
%       FLAGS :
%           .im_flag = 1 : segment view ,
%                      2 : region view,
%                      3 : false color,
%                      4 : phase image
%           .S_flag = segments' scores
%           .t_flag = segments' labels
%           .Sj_flag = shows disagreeing segments scores (S_flag must be on
%           too)

if ~exist('FLAGS','var') || ~isfield( FLAGS, 'im_flag' )
    FLAGS.im_flag=2;
end

im_flag = FLAGS.im_flag;

if ~isfield( FLAGS, 'S_flag' ) % shows all segments scores
    FLAGS.S_flag = 1;
end

S_flag = FLAGS.S_flag;

if ~isfield( FLAGS, 't_flag' ) % labels for segments
    FLAGS.t_flag = 0;
end

t_flag = FLAGS.t_flag;


if ~isfield( FLAGS, 'phase' ) % labels for segments
    FLAGS.phase = 1 ;
end

% shows scores for segments/regions that computer/user disagrees
if ~isfield( FLAGS, 'Sj_flag' )
    FLAGS.Sj_flag = 0;
end

Sj_flag = FLAGS.Sj_flag;

% figNum = 4;
% figure(figNum);
figure;
axis_current = axis;
clf;

segs_good      = zeros( size( data.phase ) );
segs_good_fail = segs_good;
segs_bad       = segs_good;
segs_bad_fail  = segs_good;
segs_Include   = segs_good;
num_segs = numel( data.segs.score(:) );

sz = size(segs_good);
backer = 0*autogain(data.segs.phaseMagic);

if im_flag == 1
    
    isnan_score = isnan(data.segs.score);
    data.segs.score(isnan_score) = 1;
    
    if ~isfield(data.segs, 'Include' )
        data.segs.Include = 0*data.segs.score+1;
    end
    
    segs_Include   = ismember( data.segs.segs_label, find(~data.segs.Include));
    segs_good      = ismember( data.segs.segs_label, find(and( ~isnan_score, and(data.segs.score,round(data.segs.scoreRaw)))));
    segs_good_fail = ismember( data.segs.segs_label, find(and( ~isnan_score, and(data.segs.score,~round(data.segs.scoreRaw)))));
    segs_bad_fail  = ismember( data.segs.segs_label, find(and( ~isnan_score, and(~data.segs.score,round(data.segs.scoreRaw)))));
    segs_bad       = ismember( data.segs.segs_label, find(and( ~isnan_score, and(~data.segs.score,~round(data.segs.scoreRaw)))));
    
    segsInlcudeag  = autogain(segs_Include);
    segsGoodag  = autogain(segs_good);
    gegsGoodFailag = autogain(segs_good_fail);
    segs3nag = autogain(data.segs.segs_3n  );
    segsBadag  = autogain(segs_bad );
    segsBadFailag = autogain(segs_bad_fail);
    maskBgag = autogain(~data.mask_bg);
    
    if FLAGS.phase
        phaseBackag = uint8(autogain(data.segs.phaseMagic));
        imshow( uint8(cat(3,...
            phaseBackag + 0.3*segsGoodag + 0.9*gegsGoodFailag, ...
            phaseBackag + 0.25*uint8(segs3nag) + 0.4*segs3nag + 0.5*(gegsGoodFailag+segsBadFailag)+0.6*segsInlcudeag, ...
            phaseBackag + 0.3*segsBadag + 0.9*segsBadFailag)), ...
            'InitialMagnification', 'fit','Border','tight');
    else
        imshow( uint8(cat(3,...
            0.5*segsGoodag + 1*gegsGoodFailag, ...
            0.25*uint8(maskBgag -segs3nag) + 0.4*segs3nag + 0.5*(gegsGoodFailag+segsBadFailag)+0.6*segsInlcudeag, ...
            0.5*segsBadag + 1*segsBadFailag)), ...
            'InitialMagnification', 'fit','Border','tight');
        
    end
    
    flagger = and( data.segs.Include, ~isnan(data.segs.score) );
    scoreRawTmp = data.segs.scoreRaw(flagger);
    scoreTmp    = data.segs.score(flagger);
    [y_good,x_good] = hist(scoreRawTmp(scoreTmp>0),[-40:2:40]);
    [y_bad,x_bad] = hist(scoreRawTmp(~scoreTmp),[-40:2:40]);
    %
    %     figure(2);
    %     clf;
    %     semilogy( x_good,y_good,'.-r');
    %     hold on;
    %     semilogy( x_bad,y_bad,'.-b');
    
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
    
    backer = 0*ag(data.phase);
    num_regs = data.regs.num_regs;
    
    if isfield(data.regs,'score')
    regs_good_agree = 0.3*double(ag(ismember(data.regs.regs_label,find(data.regs.score & round(data.regs.scoreRaw)))));
    regs_good_disagree = double(ag(ismember(data.regs.regs_label,find(data.regs.score & ~round(data.regs.scoreRaw)))));
    
    regs_bad_agree = 0.3*double(ag(ismember(data.regs.regs_label,find(~data.regs.score & ~round(data.regs.scoreRaw)))));
    regs_bad_disagree = double(ag(ismember(data.regs.regs_label,find(~data.regs.score & round(data.regs.scoreRaw)))));
    
    imshow( cat(3, 0.8*backer + 1*uint8(regs_good_agree+regs_good_disagree), ...
        0.8*backer, ...
        0.8*backer + 1*uint8(regs_bad_agree+regs_bad_disagree)) , 'InitialMagnification', 'fit');
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
        end
    end
    
elseif im_flag == 3 % phase image in jet color
    
    imshow( data.segs.phaseMagic, [], 'InitialMagnification', 'fit' );
    colormap jet;
    
elseif im_flag == 4 % phase image
    
    backer = autogain(data.phase);
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