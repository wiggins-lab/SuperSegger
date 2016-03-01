function im = showSeggerImage( data, data_r, data_f, FLAGS, clist, CONST)
% showSeggerImage : produces the trackOptiView image according to clist and
% flags. If the clist has a gate it outlines cells passing the gate.
%
% INPUT :
%         data : current frame data (*err usually data)
%         data_r : reverse frame data
%         data_f : forward frame data
%         FLAGS : see below
%         clist : list of cell files, could have a gate field.
%         CONST : segmentation constants
%
%   FLAGS :
%         P_Flag : shows regions
%         ID_flag : shows the cell numbers
%         lyse_flag : outlines cell that lysed
%         m_flag : shows mask
%         c_flag : ? does absolutely nothing
%         v_flag : shows cells outlines
%         f_flag : shows flurescence image
%         s_flag : shows the foci and their score
%         T_flag : ? something related to regions
%         p_flag : shows pole positions and connects daughter cells to each other
%
% OUTPUT :
%         im : trackOptiView outlined image
%
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


FLAGS.axis = axis;
clf;

% fix are any missing flags
FLAGS = intFixFlags( FLAGS );


% if there is a clist enables look only cells included in the clist
if ~isempty( clist );
    %clist = gate( clist );
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
mask_full = data.mask_cell;
im = makeIm( data, FLAGS, ID_LIST, CONST );

if FLAGS.m_flag % mask flag
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
        cat(3, 0.5*autogain(mask_full_r(yy,xx)>0),...
        0.5*autogain(mask_full(yy,xx)>0),...
        0.5*autogain(mask_full_f(yy,xx)>0))];
end

imshow(im);
hold on;

if ~FLAGS.m_flag
    doAnnotation( data, -xx(1)+1, -yy(1)+1 );
else
    doAnnotation( data, -xx(1)+xx(end)-xx(1)+1, -yy(1)+1 );
    doAnnotation( data_r , -xx(1)+1, -yy(1)+1);
    doAnnotation( data_f , -xx(1)+1, -yy(1)+yy(end)-yy(1)+1 );
    doFrameMerge( -xx(1)+xx(end)-xx(1)+1+1, -yy(1)+yy(end)-yy(1)+1+1);
end

    function doAnnotation( data_, x_, y_ )
        if ~isempty(data_)
            if FLAGS.ID_flag
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
                    if isfield(data.regs,'ID') && data.regs.ID(kk)
                        ID  = data.regs.ID(kk);
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
                    
                catch ME
                    printEroor(ME);
                end
            end
            
        end
    end


end

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


function im = makeIm( data, FLAGS, ID_LIST, CONST )
% makeIm puts together the image if data is segmented
% but not the text/pole/other labels.

persistent colormap_;
if isempty( colormap_ )
    colormap_ = colormap( 'jet' );
end

% get the image size
ss = size(data.phase);


% if the phase image exists use this as the background, else use the cell
% masks
if isfield(data,'phase');
    back = autogain(data.phase);
    im = cat(3,back,back,back);
else
    im = 0*cat(3, ...
        autogain(data.mask_cell),...
        autogain(data.mask_cell),...
        autogain(data.mask_cell));
end


% this code highlights the lysed cells
if isfield( data.regs, 'lyse' ) && FLAGS.lyse_flag
    is_lyse    = and( or( data.regs.lyse.errorColor1bCum, ...
        data.regs.lyse.errorColor2bCum), data.regs.lyse.errorShapeCum);
    lyse_im = intDoOutline2(ismember( ...
        data.regs.regs_label,find(is_lyse)));
else
    lyse_im = zeros( ss );
end


% if you are in fluorescence mode (f_flag ==true) then just draw the fluor
% channels but not the regions.
if FLAGS.f_flag > 0
    im = 0.3*im;
    im = FLAGS.P_val*im;
    
    if FLAGS.P_flag
        if FLAGS.v_flag
            im(:,:,3) = im(:,:,3) + 0.5*ag(data.cell_outline);
        else
            im(:,:,3) = im(:,:,3) + 0.5*ag(data.outline);
        end
    end
    
    % make the background subtracted fluor
    if isfield( data, 'fluor1' ) && ( FLAGS.f_flag == 1 );
        
        if FLAGS.filt && isfield( data, 'flour1_filtered' )
            fluor1 =  data.flour1_filtered;
        else
            fluor1 = data.fluor1;
            if isfield( data, 'fl1bg' )
                fluor1 = fluor1 - data.fl1bg;
                fluor1( fluor1< 0 ) = 0;
            else
                fluor1 = fluor1-mean(fluor1(:));
                fluor1( fluor1< 0 ) = 0;
            end
            
        end
    else
        fluor1 = 0*data.phase;
    end
    
    if isfield( data, 'fluor2' )  && ( FLAGS.f_flag == 2 );        
        if FLAGS.filt && isfield( data, 'flour2_filtered' )
            fluor2 =  data.flour2_filtered;
        else
            fluor2 = data.fluor2;
            if isfield( data, 'fl2bg' )
                fluor2 = fluor2 - data.fl2bg;
                fluor2( fluor2< 0 ) = 0;
            else
                fluor2 = fluor2-mean(fluor2(:));
                fluor2( fluor2< 0 ) = 0;
            end
        end
    else
        fluor2 = 0*data.phase;
    end
    
    if isfield( CONST.view, 'LogView' ) && CONST.view.LogView
        fluor1 =   ag( double(fluor1).^.6 );
        fluor2 =   ag( double(fluor2).^.6 );
    end
    
    
    if isfield( data, 'fluor1')
        minner = medfilt2( fluor1, [2,2], 'symmetric' );
        maxxer = max( minner(:));
        minner = min( minner(:));
        if CONST.view.falseColorFlag
            im = doColorMap( ag(fluor1,minner,maxxer), uint8(255*jet(256)) );
            if FLAGS.P_flag
                if FLAGS.v_flag
                    im = im + 0.2*cat(3,ag(data.cell_outline),ag(data.cell_outline),ag(data.cell_outline));
                else
                    im = im + 0.2*cat(3,ag(data.outline),ag(data.outline),ag(data.outline));
                end
            end
        else
            im(:,:,2) = 0.8*ag(fluor1,minner,maxxer) + im(:,:,2);
        end
    end
        
    if isfield( data, 'fluor2' )
        if FLAGS.filt && isfield( data, 'flour2_filtered' )
            fluor2 =  data.flour2_filtered;
        end
        im(:,:,1) = im(:,:,1) + 0.8*ag( fluor2 );
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

function intPlotNum( data, x_, y_ , FLAGS, ID_LIST )
% intPlotNum : Plot cell number or region numbers

counter = 200; % max amount of cell numbers to be plotted
kk = 1; % counter for regions
while (counter > 0 && kk < data.regs.num_regs)
    
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
    
    xpos = rr(1)+x_;
    ypos = rr(2)+y_;
    
    if (FLAGS.axis(1)<xpos) && (FLAGS.axis(2)>xpos) && ...
            (FLAGS.axis(3)<ypos) && (FLAGS.axis(4)>ypos)
        
        counter = counter - 1;
        if FLAGS.v_flag == 1 % cell view
            if isfield( data.regs, 'ID' ) && ismember( data.regs.ID(kk), ID_LIST )
                text( xpos, ypos, ['\fontsize{11}',num2str(data.regs.ID(kk))],...
                    'Color', cc,...
                    'FontWeight', 'Bold',...
                    'HorizontalAlignment','Center',...
                    'VerticalAlignment','Middle');
                title('Cell ID');
            end
            
            
        elseif FLAGS.v_flag == 0 % region view
            text( xpos, ypos, ['\fontsize{11}',num2str(kk)],...
                'Color', cc,...
                'Color', cc,...
                'FontWeight', 'normal',...
                'HorizontalAlignment','Center',...
                'VerticalAlignment','Middle');
            title('Region Number');
            
        else
            text( xpos, ypos, ['\fontsize{11}',num2str(data.regs.age(kk))],...
                'Color', cc,...
                'Color', cc,...
                'FontWeight', 'normal',...
                'HorizontalAlignment','Center',...
                'VerticalAlignment','Middle');
            title('Region Number');
            
        end
        kk = kk + 1;
    end
    
end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%

%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function intPlotSpot( data, x_, y_, FLAGS, clist, CONST )
% intPlotSpot : plots each foci in the cells


if isfield( data, 'CellA' ) && ~isempty( data.CellA ) && ...
        (isfield( data.CellA{1}, 'locus1') || (isfield( data.CellA{1}, 'locus2')))
    
    counter1 = 0;
    counter2 = 0;
    maxCounter1 = 500;
    maxCounter2 = 500;
    
    for kk = 1:data.regs.num_regs
        % only plot spots in the cell that are gated.
        if ~FLAGS.v_flag || ismember(data.regs.ID(kk), clist.data(:,1))
            
            % locus 1
            if isfield( data.CellA{kk}, 'locus1') &&  ( FLAGS.f_flag == 1 );
                num_spot = numel( data.CellA{kk}.locus1);
                mm = 0;
                while mm < num_spot && counter1 < maxCounter1
                    mm = mm + 1;
                    r = data.CellA{kk}.locus1(mm).r;
                    text_ = [num2str(data.CellA{kk}.locus1(mm).score, '%0.1f')];
                    if data.CellA{kk}.locus1(mm).score > CONST.getLocusTracks.FLUOR1_MIN_SCORE && ...
                            data.CellA{kk}.locus1(mm).b < 3
                        xpos = r(1)+x_;
                        ypos = r(2)+y_;
                        if (FLAGS.axis(1)<xpos) && (FLAGS.axis(2)>xpos) && ...
                                (FLAGS.axis(3)<ypos) && (FLAGS.axis(4)>ypos)
                            counter1 = counter1 + 1;
                            text( xpos+1, ypos, text_, 'Color', [0.5,1,0.5]);
                            plot( xpos, ypos, '.', 'Color', [0.5,1,0.5] );
                        end
                    end
                end
            end
            
            % locus 2
            if isfield( data.CellA{kk}, 'locus2') && (FLAGS.f_flag == 2 )
                num_spot = numel( data.CellA{kk}.locus2);
                mm = 0;
                while mm < num_spot && counter2 < maxCounter2
                    mm = mm + 1;
                    r = data.CellA{kk}.locus2(mm).r;
                    text_ = [num2str(data.CellA{kk}.locus2(mm).score, '%0.1f')];
                    if data.CellA{kk}.locus2(mm).score > CONST.getLocusTracks.FLUOR2_MIN_SCORE && ...
                            data.CellA{kk}.locus2(mm).b < 3
                        xpos = r(1)+x_;
                        ypos = r(2)+y_;
                        if (FLAGS.axis(1)<xpos) && (FLAGS.axis(2)>xpos) && ...
                                (FLAGS.axis(3)<ypos) && (FLAGS.axis(4)>ypos)
                            counter2 = counter2 + 1;
                            text( r(1)+x_+1, r(2)+y_, text_, 'Color',  [1,0.5,0.5]);
                            plot( r(1)+x_, r(2)+y_, '.',  'Color', [1,0.5,0.5]);
                        end
                    end
                end
            end
        end
    end
end

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
                catch ME
                    printError(ME);
                end
                
                plot( [r(1),un1_pole(1)], [r(2),un1_pole(2)], 'r' );
                
                if tmp.pole.op_ori
                    plot( old_pole(1)+x_, old_pole(2)+y_, 'w.','MarkerSize',6);
                    plot( new_pole(1)+x_, new_pole(2)+y_, 'w*','MarkerSize',6);
                else
                    plot( un1_pole(1)+x_, un1_pole(2)+y_, 'wo','MarkerSize',3);
                    plot( un2_pole(1)+x_, un2_pole(2)+y_, 'wo','MarkerSize',3);
                end
                
                if ~isempty(ind) && ID && tmp.pole.op_ori
                    if ID < sisterID
                        tmps = data.CellA{ind};
                        rs = tmps.coord.r_center;
                        new_pole_s = rs - tmps.length(1)*tmps.coord.e1*tmps.pole.op_ori/2;
                        plot( [new_pole(1),new_pole_s(1)]+x_, [new_pole(2),new_pole_s(2)]+y_, 'w-');
                    end
                end
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

    function FLAGS = intFixFlags( FLAGS )
        % intFixFlags :  sets default flag values if the value is missing.
        
        if ~isfield(FLAGS, 'ID_flag');
            disp('there is no filed ID_flag');
            FLAGS.ID_flag = 0;
        end
        
        if ~isfield(FLAGS, 'lyse_flag');
            disp('there is no filed lyse_flag')
            FLAGS.lyse_flag = 0;
        end
        
        if ~isfield(FLAGS,'m_flag');
            disp('there is no filed m_flag')
            FLAGS.m_flag = 0;
        end
        
        if ~isfield(FLAGS, 'c_flag');
            disp('there is no filed c_flag')
            FLAGS.c_flag = 0;
        end
        
        if ~isfield(FLAGS, 'P_flag');
            disp('there is no filed P_flag')
            FLAGS.P_flag = 0;
        end
        
        if ~isfield(FLAGS, 'v_flag' );
            disp('there is no filed v_flag')
            FLAGS.v_flag = 0;
        end
        
        if ~isfield(FLAGS, 'f_flag');
            disp('there is no filed f_flag')
            FLAGS.f_flag = 0;
        end
        
        if ~isfield(FLAGS, 's_flag');
            disp('there is no filed s_flag')
            FLAGS.s_flag = 0;
        end
        
        if ~isfield(FLAGS, 'T_flag');
            disp('there is no filed T_flag')
            FLAGS.T_flag = 0;
        end
        
        if ~isfield(FLAGS, 'filt')
            disp('there is not filed filt_flag')
            FLAGS.filt = [0,0,0];
        end
        
        if ~isfield(FLAGS, 'p_flag');
            disp('there is not file p_flag')
            FLAGS.p_flag = 0;
        end
        FLAGS.link_flag = FLAGS.s_flag || FLAGS.ID_flag;
        
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