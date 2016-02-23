function im = showDA4new( data, data_r, data_f, FLAGS, clist, CONST)
% Copyright (C) 2016 Wiggins Lab 
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.

iptsetpref('imshowborder','tight');
iptsetpref('ImshowInitialMagnification','fit');

if ~isfield(CONST.view, 'falseColorFlag' )
    CONST.view.falseColorFlag = false;
end


if nargin<4
    FLAGS = [];
end


% check to see if there are any missing flags in the structure and fix it
% if there are.
FLAGS = intFixFlags( FLAGS );


% having a clist enables you to only look at the cells included in the
% clist.
if ~isempty( clist );
    clist = gate( clist );
    ID_LIST = clist.data(:,1);
    ID_LIST = ID_LIST(logical(ID_LIST));
else
    
    if isfield(data, 'regs') && isfield( data.regs, 'ID' );
        ID_LIST = data.regs.ID;
    else
        ID_LIST = [];
    end
end


[xx,yy] = intGetImSize( data, FLAGS );



% Not sure what the hell this first thing does anymore.
if FLAGS.D_flag == 2
    im = makeImD( data, FLAGS );
else
    mask_full = data.mask_cell;
    im = makeIm( data, FLAGS, ID_LIST, CONST );
    
    if FLAGS.m_flag
        if isempty(data_r)
            mask_full_r = 0*mask_full;
            im_r = cat(3,mask_full_r,mask_full_r,mask_full_r);
        else
            mask_full_r = data_r.mask_cell;
            im_r = makeIm( data_r, FLAGS );
        end
        
        if isempty(data_f)
            mask_full_f = 0*mask_full;
            im_f = cat(3,mask_full_f,mask_full_f,mask_full_f);
        else
            mask_full_f = data_f.mask_cell;
            im_f = makeIm( data_f, FLAGS );
        end
        
        im =  [im_r(yy,xx,:),im(yy,xx,:); im_f(yy,xx,:), ...
            cat(3, ...
            0.5*autogain(mask_full_r(yy,xx)>0),...
            0.5*autogain(mask_full(yy,xx)>0),...
            0.5*autogain(mask_full_f(yy,xx)>0))...
            ];
    end
end

imshow(im);

%if FLAGS.m_flag
%    imshow( im );
%else
%    imshow2( im );
%end

%imshow2( im(yy,xx) );

if FLAGS.D_flag ~= 2
    hold on;
    
    if ~FLAGS.m_flag 
        doAnnotation( data, -xx(1)+1, -yy(1)+1 );     
    else
        doAnnotation( data, -xx(1)+xx(end)-xx(1)+1, -yy(1)+1 ); 
        doAnnotation( data_r , -xx(1)+1, -yy(1)+1);
        doAnnotation( data_f , -xx(1)+1, -yy(1)+yy(end)-yy(1)+1 );
        doFrameMerge( -xx(1)+xx(end)-xx(1)+1+1, -yy(1)+yy(end)-yy(1)+1+1);
    end
end

    function doAnnotation( data_, x_, y_ )
        if ~isempty(data_)
            if FLAGS.t_flag
                intPlotNum( data_ , x_, y_, FLAGS, ID_LIST );
            end
            
            if FLAGS.s_flag && isfield(data_,'CellA')
                intPlotSpot( data_, x_, y_, FLAGS, clist, CONST );
            end
            if FLAGS.p_flag
                intPlotLink( data_, x_, y_ );
            end
        end
        
    end


    function doFrameMerge( x_, y_ )
        
        if ~isempty( data )
            for kk = 1:data.regs.num_regs
                rr3 = [x_,y_ ];
                rr_c = data.regs.props(kk).Centroid;
                try
                    if isfield(data.regs,'ID')
                        ID  = data.regs.ID(kk);
                        if ID
                            if ~isempty(data_r) && isfield(data_r.regs,'ID')
                                ind_r = find(ID == data_r.ID);
                                if ~isempty( ind_r );
                                    rr_r = data_r.props(ind_r).Centroid ;
                                    plot( [rr_c(1),rr_r(1)]+rr3(1), [rr_c(2),rr_r(2)]+rr3(2), 'r');
                                end
                            end
                            
                            if ~isempty(data_f) && isfield(data_f.regs,'ID')
                                ind_f = find(ID == data_f.ID);
                                if ~isempty( ind_f );
                                    rr_f = data_f.props(ind_f).Centroid ;
                                    plot( [rr_c(1),rr_f(1)]+rr3(1), [rr_c(2),rr_f(2)]+rr3(2), 'b');
                                end
                            end
                        end
                    end
                end
            end  
        end
    end


end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function im = makeImD( data, FLAGS )

back = ag(data.phase);

if isfield( data, 'fluor1' )
    fluor1 = ag(data.fluor1);
else
    fluor1 = 0*back;
end

if isfield( data, 'fluor2' )
    fluor2 = ag(data.fluor2);
else
    fluor2 = 0*back;
end

im = cat(3, fluor2 + 0.5*back, fluor1 + 0.5*back, 0.5*back );
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Make Im : Puts together the image if the data is segmented.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function im = makeIm( data, FLAGS, ID_LIST, CONST )
% makeIm puts together the image if data is segmented
% but not the text/pole/other labels.

persistent colormap_;
if isempty( colormap_ )
    colormap_ = colormap( 'jet' );
end

% get the image size
ss = size(data.phase);


% if the phase image exists use this as the back ground, else use the cell
% masks
if isfield(data,'phase');
    back = autogain(data.phase);
    
    im = cat(3, ...
        back,...
        back,...
        back);
else
    im = 0*cat(3, ...
        autogain(data.mask_cell),...
        autogain(data.mask_cell),...
        autogain(data.mask_cell));
end



% this code highlights the lysed cells
if isfield( data.regs, 'lyse' ) && FLAGS.lyse_flag
    %is_lyse    = or( data.regs.lyse.errorColor1Cum, ...
    %or(data.regs.lyse.errorColor2Cum, data.regs.lyse.errorShapeCum));
    is_lyse    = and( or( data.regs.lyse.errorColor1bCum, ...
        data.regs.lyse.errorColor2bCum), data.regs.lyse.errorShapeCum);
    lyse_im = intDoOutline2(ismember( ...
        data.regs.regs_label,find(is_lyse)));
else
    lyse_im = zeros( ss );
end




% if you are in fluorescence mode (f_flag ==true) then just draw the fluor
% channels but not the regions.
if FLAGS.f_flag
    im = 0.3*im;
    if FLAGS.P_flag
        if FLAGS.v_flag
            im(:,:,3) = im(:,:,3) + 0.5*ag(data.cell_outline);
        else
            im(:,:,3) = im(:,:,3) + 0.5*ag(data.outline);
        end
    end
    
    
    % make the background subtracted fluor
    if isfield( data, 'fluor1' )
        fluor1 = data.fluor1;
        if isfield( data, 'fl1bg' )
            fluor1 = fluor1 - data.fl1bg;
            fluor1( fluor1< 0 ) = 0;
        else
            fluor1 = fluor1-mean(fluor1(:));
            fluor1( fluor1< 0 ) = 0;
        end
    else
        fluor1 = 0*data.phase;
    end
    
    if isfield( data, 'fluor2' )
        fluor2 = data.fluor2;
        if isfield( data, 'fl2bg' )
            fluor2 = fluor2 - data.fl2bg;
            fluor2( fluor2< 0 ) = 0;
        else
            fluor2 = fluor2-mean(fluor2(:));
            fluor2( fluor2< 0 ) = 0;
        end
    else
        fluor2 = 0*data.phase;
    end
    
    
    
    %
    if isfield( data, 'fluor1')
        if CONST.view.falseColorFlag
            im = ag(doColorMap( ag(data.fluor1), colormap_ ));
            if FLAGS.P_flag
                if FLAGS.v_flag
                    im = im + 0.2*cat(3,ag(data.cell_outline),ag(data.cell_outline),ag(data.cell_outline));
                else
                    im = im + 0.2*cat(3,ag(data.outline),ag(data.outline),ag(data.outline));
                end
            end
            
        else
            if isfield( CONST.view, 'LogView' ) && CONST.view.LogView
                im(:,:,2) = im(:,:,2) + 0.8*ag( log(double(fluor1)+500));
            else
                im(:,:,2) = im(:,:,2) + 0.8*ag( fluor1 );
            end
            
        end
    end
    if isfield( data, 'fluor2' )
        if isfield( CONST.view, 'LogView' ) && CONST.view.LogView
            im(:,:,1) = im(:,:,1) + 0.8*ag( log(double(fluor2)+100)+1);
        else
            im(:,:,1) = ag( fluor2 );
        end
        
    end
    
    
    
    
    % add the lysis outline to the fluor image.
    im(:,:,1) = 255*uint8(lyse_im) + im(:,:,1);
    im(:,:,2) = 255*uint8(lyse_im) + im(:,:,2);
    im(:,:,3) = 255*uint8(lyse_im) + im(:,:,3);
    
    
    % if P_flag is true, it shows the regions.
elseif FLAGS.P_flag
    
    
    if isfield( data.regs, 'ignoreError' )
        ignoreErrorV = data.regs.ignoreError;
    else
        ignoreErrorV = 0*data.reg.divide;
    end
    
    is_cell_V   = or(ismember( data.regs.ID, ID_LIST),~FLAGS.v_flag);
    is_div_V    = or(and(data.regs.birthF,data.regs.stat0),...
        data.regs.divide);
    
    
    map_err_fr_ind = find(and(is_cell_V,and(~is_div_V,and(and(data.regs.ehist,...
        data.regs.error.r),~ignoreErrorV))));
    map_err_fr  = double(      ismember( data.regs.regs_label, ...
        map_err_fr_ind ));
    
    map_err_frO_ind = find(and(is_cell_V,and( is_div_V,and(and(data.regs.ehist,...
        data.regs.error.r),~ignoreErrorV))));
    map_err_frO = intDoOutline(ismember( data.regs.regs_label, ...
        map_err_frO_ind ));
    
    map_err_nf_ind =  find(and(is_cell_V,and(~is_div_V,and(and(data.regs.ehist,...
        ~data.regs.error.r),~ignoreErrorV))));
    map_err_nf  = double(      ismember( data.regs.regs_label, ...
        map_err_nf_ind ));
    
    map_err_nfO_ind =  find(and(is_cell_V,and( is_div_V,and(and(data.regs.ehist,...
        ~data.regs.error.r),~ignoreErrorV))));
    map_err_nfO = intDoOutline(ismember( data.regs.regs_label, ...
        map_err_nfO_ind ));
    
    map_no_err_ind =  find(and(is_cell_V,and(~is_div_V,or(~data.regs.ehist,...
        ignoreErrorV))));
    map_no_err  = double(      ismember( data.regs.regs_label, ...
        map_no_err_ind));
    
    map_no_errO_ind = find(and(is_cell_V,and( is_div_V,or(~data.regs.ehist,...
        ignoreErrorV))));
    map_no_errO = intDoOutline(ismember( data.regs.regs_label, ...
        map_no_errO_ind));
    
    map_stat0_2_ind = find(and(is_cell_V,and(~is_div_V,...
        data.regs.stat0==2)));
    map_stat0_2 = double(      ismember( data.regs.regs_label, ...
        map_stat0_2_ind ));
    
    map_stat0_2O_ind =  find(and(is_cell_V,and( is_div_V,...
        data.regs.stat0==2)));
    map_stat0_2O= intDoOutline(ismember( data.regs.regs_label, ...
        map_stat0_2O_ind ));
    
    map_stat0_1_ind  = find(and(is_cell_V,and(~is_div_V,...
        data.regs.stat0==1)));
    map_stat0_1  = double(      ismember( data.regs.regs_label, ...
        map_stat0_1_ind ));
    
    map_stat0_1O_ind = find(and(is_cell_V,and( is_div_V,...
        data.regs.stat0==1)));
    map_stat0_1O = intDoOutline(ismember( data.regs.regs_label, ...
        map_stat0_1O_ind ));
    
    map_stat0_0_ind = find(and(is_cell_V,and(~is_div_V,...
        data.regs.stat0==0)));
    map_stat0_0 = double(      ismember( data.regs.regs_label, ...
        map_stat0_0_ind ));
    
    map_stat0_0O_ind =  find(and(is_cell_V,and( is_div_V,...
        data.regs.stat0==0)));
    map_stat0_0O= intDoOutline(ismember( data.regs.regs_label, ...
        map_stat0_0O_ind ));
    
    
    
    reg_color = uint8( 255*cat( 3, ...
        double(lyse_im)+0.15*(2*(map_err_fr+map_err_frO)+(map_err_nf+map_err_nf)),...
        0.30*(map_no_err+map_no_errO),...
        0.30*(3*(map_stat0_2+map_stat0_2O)+...
        1.5*(map_stat0_1+map_stat0_1O)+...
        0.5*(map_stat0_0+map_stat0_0O))));
    
    
    
    im = reg_color + im;
    
    
end


im = uint8(im);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intPlotNum
%
% Plot cell number or region numbers
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function intPlotNum( data, x_, y_ , FLAGS, ID_LIST )
% intPlotNum Plots cell number or region numbers
for kk = 1:data.regs.num_regs
    rr = data.regs.props(kk).Centroid;
    
    if isfield( data.regs, 'ignoreError' )
        ignoreError = data.regs.ignoreError(kk);
    else
        ignoreError = 0;
    end
    
    
    if ignoreError
        cc = 'g';
    elseif data.regs.error.r(kk)
        cc = 'r';
    else
        cc = 'w';
    end
    
    if FLAGS.v_flag == 1
        if isfield( data.regs, 'ID' ) && ismember( data.regs.ID(kk), ID_LIST )
            text( rr(1)+x_, rr(2)+y_, ['\fontsize{11}',num2str(data.regs.ID(kk))],...
                'Color', cc,...
                'FontWeight', 'Bold',...
                'HorizontalAlignment','Center',...
                'VerticalAlignment','Middle');
            title('Cell ID');
        end
        
        
    elseif FLAGS.v_flag == 0
        text( rr(1)+x_, rr(2)+y_, ['\fontsize{11}',num2str(kk)],...
            'Color', cc,...
            'Color', cc,...
            'FontWeight', 'normal',...
            'HorizontalAlignment','Center',...
            'VerticalAlignment','Middle');
        title('Region Number');
        
    else
        text( rr(1)+x_, rr(2)+y_, ['\fontsize{11}',num2str(data.regs.age(kk))],...
            'Color', cc,...
            'Color', cc,...
            'FontWeight', 'normal',...
            'HorizontalAlignment','Center',...
            'VerticalAlignment','Middle');
        title('Region Number');
        
    end
    
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intPlotSpot
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function intPlotSpot( data, x_, y_, FLAGS, clist, CONST )

if isfield( data, 'CellA' ) && ~isempty( data.CellA ) && ...
        (isfield( data.CellA{1}, 'locus1') || (isfield( data.CellA{1}, 'locus2')))
    for kk = 1:data.regs.num_regs
        
        % only plot spots in the cell that are gated.
        if ~FLAGS.v_flag || ismember(data.regs.ID(kk), clist.data(:,1))
            
            if isfield( data.CellA{kk}, 'locus1')
                num_spot = numel( data.CellA{kk}.locus1);
                for mm = 1:num_spot
                    r = data.CellA{kk}.locus1(mm).r;
                    
                    if data.CellA{kk}.locus1(mm).score > CONST.getLocusTracks.FLUOR1_MIN_SCORE
                        %plot( r(1)+x_, r(2)+y_, num2str(data.CellA{kk}.locus1(mm).score, '%0.0f'), 'Color', 'k');
                        plot( r(1)+x_, r(2)+y_, 'g.' );
                        
                    else
                        %text( r(1)+x_, r(2)+y_, num2str(data.CellA{kk}.locus1(mm).score, '%0.0f'), 'Color','k' );
                        %plot( r(1)+x_, r(2)+y_, 'go');
                    end
                end
                
            end
            if isfield( data.CellA{kk}, 'locus2')
                num_spot = numel( data.CellA{kk}.locus2);
                for mm = 1:num_spot
                    r = data.CellA{kk}.locus2(mm).r;
                    
                    if data.CellA{kk}.locus2(mm).score > CONST.getLocusTracks.FLUOR2_MIN_SCORE
                        plot( r(1)+x_, r(2)+y_, 'r.' );
                        %text( r(1)+x_+2, r(2)+y_+2, ...
                        %    num2str(data.CellA{kk}.locus2(mm).score,'%2.1g'), ...
                        %    'Color',  'r' );
                        
                    else
                        plot( r(1)+x_, r(2)+y_, 'ro','MarkerSize',3,'Color',[0.3,0.0,0]  );
                        %text( r(1)+x_+2, r(2)+y_+2,...
                        %    num2str(data.CellA{kk}.locus2(mm).score,'%2.1g'), ...
                        %    'Color', [0.6,0.0,0]  );
                    end
                    
                    
                end
                
            end
        end
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intPlotLink
%
% show the pole positions and connect daughter cells to each other
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function intPlotLink( data, x_, y_ )
% intPlotLink shows pole positions and connects daughter cells to each other
for kk = 1:data.regs.num_regs
    rr1 = data.regs.props(kk).Centroid;
    
    ID       = data.regs.ID(kk);
    sisterID = data.regs.sisterID(kk);
    
    if sisterID
        ind = find( data.regs.ID == sisterID );
        if numel(ind)>1
            ind = ind(1)
        end
    else
        ind = [];
    end
    
    
    
    if isfield( data, 'CellA' )
        
        try
            tmp = data.CellA{kk};
            r = tmp.coord.r_center;
            xaxisx = r(1) + [0,tmp.length(1)*tmp.coord.e1(1)]/2;
            xaxisy = r(2) + [0,tmp.length(1)*tmp.coord.e1(2)]/2;
            yaxisx = r(1) + [0,tmp.length(2)*tmp.coord.e2(1)]/2;
            yaxisy = r(2) + [0,tmp.length(2)*tmp.coord.e2(2)]/2;
            old_pole = r + tmp.length(1)*tmp.coord.e1*tmp.pole.op_ori/2;
            new_pole = r - tmp.length(1)*tmp.coord.e1*tmp.pole.op_ori/2;
            un1_pole = r + tmp.length(1)*tmp.coord.e1/2;
            un2_pole = r - tmp.length(1)*tmp.coord.e1/2;
        catch
            'hi';
        end
        
        
        % plot( [r(1),un1_pole(1)], [r(2),un1_pole(2)], 'r' );
        
        if tmp.pole.op_ori
            plot( old_pole(1)+x_, old_pole(2)+y_, 'ro','MarkerSize',6);
            plot( new_pole(1)+x_, new_pole(2)+y_, 'bo','MarkerSize',6);
        else
            plot( un1_pole(1)+x_, un1_pole(2)+y_, 'wo','MarkerSize',4);
            plot( un2_pole(1)+x_, un2_pole(2)+y_, 'wo','MarkerSize',4);
        end
        
        if ~isempty(ind) && ID && tmp.pole.op_ori
            if ID < sisterID
                tmps = data.CellA{ind};
                
                rs = tmps.coord.r_center;
                
                new_pole_s = rs - tmps.length(1)*tmps.coord.e1*tmps.pole.op_ori/2;
                
                plot( [new_pole(1),new_pole_s(1)]+x_, [new_pole(2),new_pole_s(2)]+y_, 'w-');
            end
        end
        
        
    else
        
    end
    
end
end


function [xx,yy] = intGetImSize( data, FLAGS )

if isfield( data, 'regs' )
    ss = size(data.regs.regs_label);
    
    
    
    if FLAGS.T_flag
        tmp_props = regionprops( data.regs.regs_label, 'BoundingBox' );
        pad = 10;
        
        yymin_ = ceil(tmp_props(1).BoundingBox(2))-pad;
        yymax_ = yymin_ + ceil(tmp_props(1).BoundingBox(4))-1+2*pad;
        xxmin_ = ceil(tmp_props(1).BoundingBox(1))-pad;
        xxmax_ = xxmin_ + ceil(tmp_props(1).BoundingBox(3))-1+2*pad;
        
        
        num_segs = max(data.regs.regs_label(:));
        
        
        
        for ii = 2:num_segs
            
            yymin = ceil(tmp_props(ii).BoundingBox(2))-pad;
            yymax = yymin + ceil(tmp_props(ii).BoundingBox(4))-1+2*pad;
            xxmin = ceil(tmp_props(ii).BoundingBox(1))-pad;
            xxmax = xxmin + ceil(tmp_props(ii).BoundingBox(3))-1+2*pad;
            
            yymin_ = min( [yymin_, yymin] );
            yymax_ = max( [yymax_, yymax] );
            xxmin_ = min( [xxmin_, xxmin] );
            xxmax_ = max( [xxmax_, xxmax] );
            
            
        end
        
        
        
        yy = max([1,yymin_]):min([ss(1),yymax_]);
        xx = max([1,xxmin_]):min([ss(2),xxmax_]);
    else
        xx = 1:ss(2);
        yy = 1:ss(1);
    end
else
    ss = size(data.phase);
    xx = 1:ss(2);
    yy = 1:ss(1);
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intFixFlags( FLAGS )
%
% sets default flag values.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function FLAGS = intFixFlags( FLAGS )
% intFixFlags  sets default flag values.

if ~isfield(FLAGS, 't_flag');
    'there is no filed t_flag'
    FLAGS.t_flag = 0;
end

if ~isfield(FLAGS, 'lyse_flag');
    'there is no filed lyse_flag'
    FLAGS.lyse_flag = 0;
end

if ~isfield(FLAGS,'m_flag');
    'there is no filed m_flag'
    FLAGS.m_flag = 0;
end

if ~isfield(FLAGS, 'c_flag');
    'there is no filed c_flag'
    FLAGS.c_flag = 0;
end

if ~isfield(FLAGS, 'P_flag');
    'there is no filed P_flag'
    FLAGS.P_flag = 0;
end

if ~isfield(FLAGS, 'v_flag' );
    'there is no filed v_flag'
    FLAGS.v_flag = 0;
end

if ~isfield(FLAGS, 'f_flag');
    'there is no filed f_flag'
    FLAGS.f_flag = 0;
end

if ~isfield(FLAGS, 's_flag');
    'there is no filed s_flag'
    FLAGS.s_flag = 0;
end

if ~isfield(FLAGS, 'T_flag');
    'there is no filed T_flag'
    FLAGS.T_flag = 0;
end

if ~isfield(FLAGS, 'p_flag');
    'there is not file p_flag'
    FLAGS.p_flag = 0;
end
FLAGS.link_flag = FLAGS.s_flag || FLAGS.t_flag;

end

function outline = intDoOutline( map )

persistent sqrStrel;

if isempty( sqrStrel );
    sqrStrel = strel('square',3);
end

outline = 2*double(imdilate( map, sqrStrel ))-double(map);
end


function outline = intDoOutline2( map )

persistent sqrStrel;

if isempty( sqrStrel );
    sqrStrel = strel('square',3);
end

outline = double(imdilate( map, sqrStrel ))-double(map);
end