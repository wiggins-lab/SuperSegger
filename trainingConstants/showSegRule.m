function showSegRule( data, FLAGS )

if isfield( FLAGS, 'im_flag' )
    im_flag = FLAGS.im_flag;
else
    im_flag = 1;
end

if isfield( FLAGS, 'S_flag' )
    S_flag = FLAGS.S_flag;
else
    S_flag = 0;
end

if isfield( FLAGS, 't_flag' )
    t_flag = FLAGS.t_flag;
else
    t_flag = 0;
end

% only show scores for things that are wrong
if isfield( FLAGS, 'Sj_flag' )
    Sj_flag = FLAGS.Sj_flag;
else
    Sj_flag = 0;
end

axis_current = axis;




figure(1)
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
    
%     for ii = 1:num_segs
%         
%         [xx,yy] = getBBpad(data.segs.props(ii).BoundingBox,sz,2);
%         
%         if (~data.segs.Include(ii))
%             segs_Include(yy,xx) = ...
%                         segs_Include(yy,xx) + ...
%                         double(data.segs.segs_label(yy,xx) == ii);
%         end
%         
%         if ~isnan( data.segs.score(ii) );
%             if data.segs.score(ii)
%                 
%                 if data.segs.scoreRaw(ii)>0
%                     segs_good(yy,xx) = ...
%                         segs_good(yy,xx) + ...
%                         double(data.segs.segs_label(yy,xx) == ii);
%                 else
%                     segs_good_fail(yy,xx) = ...
%                         segs_good_fail(yy,xx) +...
%                         double(data.segs.segs_label(yy,xx) == ii);
%                 end
%             else
%                 if data.segs.scoreRaw(ii) > 0
%                     segs_bad_fail(yy,xx) = ...
%                         segs_bad_fail(yy,xx) + ...
%                         double(data.segs.segs_label(yy, xx) == ii);
%                 else
%                     segs_bad(yy, xx) = ...
%                         segs_bad(yy, xx) +...
%                         double(data.segs.segs_label(yy, xx) == ii);
%                 end
%                 
%             end
%         end
%     end
    

    isnan_score     = isnan( data.segs.score );
    data.segs.score(isnan_score) = 1;
    
    if ~isfield(data.segs, 'Include' )
        data.segs.Include = 0*data.segs.score+1;
    end
    
    segs_Include   = ismember( data.segs.segs_label, find(~data.segs.Include));
    segs_good      = ismember( data.segs.segs_label, find(and( ~isnan_score, and(data.segs.score,data.segs.scoreRaw>0))));
    segs_good_fail = ismember( data.segs.segs_label, find(and( ~isnan_score, and(data.segs.score,~(data.segs.scoreRaw>0)))));
    segs_bad_fail  = ismember( data.segs.segs_label, find(and( ~isnan_score, and(~data.segs.score,data.segs.scoreRaw>0))));
    segs_bad       = ismember( data.segs.segs_label, find(and( ~isnan_score, and(~data.segs.score,~(data.segs.scoreRaw>0)))));
    
    
    sI  = autogain(segs_Include);
    sg  = autogain(segs_good);
    sgf = autogain(segs_good_fail);
    s3n = autogain(data.segs.segs_3n  );
    sb  = autogain(segs_bad );
    sbf = autogain(segs_bad_fail);
    mbg = autogain(~data.mask_bg);
    
    ww = 0.5*(sgf + sbf);
    %
    %     imshow( cat(3,...
    %         backer+0.3 *autogain(segs_good)+autogain(segs_good_fail), ...
    %         backer+0.15*autogain(data.segs.segs_3n  )+0.15*autogain(~data.mask_bg), ...
    %         backer+0.3 *autogain(segs_bad )+autogain(segs_bad_fail)), ...
    %         'InitialMagnification', 'fit');
    %
    
    
    imshow( uint8(cat(3,...
        0.5*sg + 1.0*sgf, ...
        0.25*uint8(mbg-s3n) + 0.4*s3n + 0.5*(sgf+sbf)+0.6*sI, ...
        0.5*sb + 1.0*sbf)), ...
        'InitialMagnification', 'fit','Border','tight');
    
    figure(2);
    clf;
    
    
    flagger = and( data.segs.Include, ~isnan(data.segs.score) );
    scoreRawTmp = data.segs.scoreRaw(flagger);
    scoreTmp    = data.segs.score(flagger); 
    [y_good,x_good] = hist(scoreRawTmp(scoreTmp>0),[-40:2:40]);
    
    
    [y_bad,x_bad] = hist(scoreRawTmp(~scoreTmp),[-40:2:40]);
    semilogy( x_good,y_good,'.-r');
    hold on;
    semilogy( x_bad,y_bad,'.-b');
    
    figure(1);
    
    
    
    props = regionprops( data.segs.segs_label, 'Centroid'  );
    num_segs = numel(props);
    
    if S_flag && (~t_flag)
        for ii = 1:num_segs
            
            r = props(ii).Centroid;
            
            tmp_flag = double(data.segs.scoreRaw(ii)>0)-double(data.segs.score(ii));
            
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
    
    if ~isempty( data.segs.scoreRaw(data.segs.score>0) )
        disp( ['Min on: ',...
        num2str(min(data.segs.scoreRaw(data.segs.score>0)))] );
    end
    if ~isempty( data.segs.scoreRaw(data.segs.score==0) )
        disp( ['Max off: ',...
        num2str(max(data.segs.scoreRaw(data.segs.score==0)))] );
    end
    
elseif im_flag == 2
    
    backer    = 0*ag(data.phase);
    regs_good = zeros(size(backer));
    regs_bad  = zeros(size(backer));
    
    num_regs = data.regs.num_regs;
    
%     for ii = 1:num_regs
%         [xx,yy] = getBBpad( data.regs.props(ii).BoundingBox, sz, 2 );
%         if data.regs.score(ii)
%             regs_good(yy,xx) = regs_good(yy,xx) + ...
%                 0.5*((data.regs.scoreRaw(ii)<0)+1)*double(ag(data.regs.regs_label(yy,xx)==ii));
%             
%         else
%             regs_bad(yy,xx)  = regs_bad(yy,xx)  + ...
%                 0.5*((data.regs.scoreRaw(ii)>0)+1)*double(ag(data.regs.regs_label(yy,xx)==ii));
%         end
%     end
    
regs_good =     double(ag(ismember( data.regs.regs_label, find(and(data.regs.score,data.regs.scoreRaw<0))))) + ...
            0.5*double(ag(ismember( data.regs.regs_label, find(and(data.regs.score,~(data.regs.scoreRaw<0))))));

regs_bad  =      double(ag(ismember( data.regs.regs_label, find(and(~data.regs.score,data.regs.scoreRaw>0))))) + ...
            0.5*double(ag(ismember( data.regs.regs_label, find(and(~data.regs.score,~(data.regs.scoreRaw>0))))));
        
        
    imshow( cat(3, 0.8*backer + 1*uint8(regs_good), ...
        0.8*backer, ...
        0.8*backer + 1*uint8(regs_bad)) , 'InitialMagnification', 'fit');
    
    
    figure(2);
    clf;
    [y_good,x_good] = hist(data.regs.scoreRaw(data.regs.score>0));
    [y_bad,x_bad] = hist(data.regs.scoreRaw(~data.regs.score));
    semilogy( x_good,y_good,'o-r');
    hold on;
    semilogy( x_bad,y_bad,'o-b');
    figure(1);
    
    if ~isempty( data.regs.scoreRaw(data.regs.score>0) )
        disp( ['Min on: ',...
        num2str(min(data.regs.scoreRaw(data.regs.score>0)))] );
    end
    
    if S_flag && (~t_flag)
        for ii = 1:num_regs
            
            r = data.regs.props(ii).Centroid;
            
            %if scoreTmp > CONST.trackOpti.SCORE_LIMIT
            %    cc = 'r';
            %else
            %    cc = 'w';
            %end
            flagger =  logical(data.regs.score(ii)) == (data.regs.scoreRaw(ii)<0);
            
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
    
elseif im_flag == 3
    
    imshow( data.segs.phaseMagic, [], 'InitialMagnification', 'fit' );
    colormap jet;
    
elseif im_flag == 4
    
    backer = autogain(data.phase);
    imshow( cat(3,backer,backer,backer), 'InitialMagnification', 'fit' );
    
end

axis(axis_current);

end