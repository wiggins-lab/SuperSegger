function im = showSeggerImage( data, data_r, data_f, FLAGS, clist, CONST, gui_fig)
% showSeggerImage : produces the superSeggerViewer image according to clist and
% flags. If the clist has a gate it outlines cells passing the gate.
%
% Colors : green are cells without errors, red are cells with error flags
% reverse or forward, or lysed cells, blue are cells that came from a good
% division, if error or not observed (?), or had a succesfful divison.
%
% INPUT :
%         data : current frame data (*err usually data)
%         data_r : reverse frame data
%         data_f : forward frame data
%         FLAGS : controls what is displays, for more information look at fixFlags
%         clist : list of cell files, could have a gate field.
%         CONST : segmentation constants
%
%
% OUTPUT :
%         im : trackOptiView outlined image
%
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou, Paul Wiggins, Connor Brennan.
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

iptsetpref('imshowborder','tight');
iptsetpref('ImshowInitialMagnification','fit');

if ~exist('CONST','var') || isempty(CONST)
    disp ('No constants loaded - loading 60XEcLb');
    CONST = loadConstants(60,0);
end

if ~isfield(CONST.view, 'falseColorFlag' )
    CONST.view.falseColorFlag = false;
end

if nargin<4
    FLAGS = [];
end

FLAGS.axis = axis;

if ~exist('gui_fig','var') || isempty(gui_fig)
    gui_fig = [];
    clf;
end

% fix are any missing flags
FLAGS = intFixFlags( FLAGS );

% if there is a clist enables look only cells included in the clist
if exist('clist','var') && ~isempty( clist );
    clist = gate( clist );
    ID_LIST = clist.data(:,1);
    ID_LIST = ID_LIST(logical(ID_LIST));
else
    clist = [];
    if isfield(data, 'regs') && isfield( data.regs, 'ID' );
        ID_LIST = data.regs.ID;
    else
        ID_LIST = [];
    end
end


[xx,yy] = intGetImSize( data, FLAGS );
mask_full = data.mask_cell;
im = makeIm( data, FLAGS, ID_LIST, CONST );

if FLAGS.m_flag % mask flag : shows reverse, forward, current, and masked image view
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
        cat(3, 0.5*ag(mask_full_r(yy,xx)>0),...
        0.5*ag(mask_full(yy,xx)>0),...
        0.5*ag(mask_full_f(yy,xx)>0))];
end

if isempty(gui_fig)
    imshow(im)
else
    axes(gui_fig);
    imshow(im);
    FLAGS.axis = axis;
end
hold on;


b = gca; legend(b,'off');

if FLAGS.P_flag && FLAGS.legend
    hold on;
    dark_blue = [20 20 199]/255;
    light_blue = [20 97 199]/255;
    cyan = [36 113 125]/255;
    green = [18 95 63]/255;
    purple = [105 60 106]/255;
    ha(1) = plot(nan,nan,'o','MarkerSize',10,'MarkerEdgeColor',green,'MarkerFaceColor',green);
    ha(2) = plot(nan,nan,'o','MarkerSize',10,'MarkerEdgeColor',dark_blue,'MarkerFaceColor',dark_blue);
    ha(3) = plot(nan,nan,'o','MarkerSize',10,'MarkerEdgeColor',light_blue,'MarkerFaceColor',light_blue);
    ha(4) = plot(nan,nan,'o','MarkerSize',10,'MarkerEdgeColor',purple,'MarkerFaceColor',purple);
    ha(5) = plot(nan,nan,'-r');
    
    hhh = legend(ha',{'No birth', 'No division', 'Full cell cycle', 'Errors','Dividing'},...
        'Location','NorthEast',...
        ... %'BestOutside',
        'Orientation','vertical');
    set( hhh, 'EdgeColor', [ 0,   0,   0],...
        'Color',     [ 0.8, 0.8, 0.8],...
        'TextColor', [ 0,   0,   0] );
    
end

% Displays linking information
if FLAGS.showLinks
    intPlotLinks(data, data_r, data_f, -xx(1)+1, -yy(1)+1, FLAGS, ID_LIST, CONST );
    hold on;
end

% annotates spots, cell numbers and poles
if ~FLAGS.m_flag
    doAnnotation( data, -xx(1)+1, -yy(1)+1 );
else
    doAnnotation( data, -xx(1)+xx(end)-xx(1)+1, -yy(1)+1 );
    doAnnotation( data_r , -xx(1)+1, -yy(1)+1);
    doAnnotation( data_f , -xx(1)+1, -yy(1)+yy(end)-yy(1)+1 );
    doFrameMerge( -xx(1)+xx(end)-xx(1)+1+1, -yy(1)+yy(end)-yy(1)+1+1);
end




    function doAnnotation( data_, x_, y_ )
        % doAnnotation : annotates spots, cell numbers and poles
        if ~isempty(data_)
            if FLAGS.ID_flag == 1 % plots cell numbers
                intPlotNum( data_ , x_, y_, FLAGS, ID_LIST );
            elseif FLAGS.regionScores % plots region scores
                intPlotScores( data_ , x_, y_, FLAGS );
            end
            
            % plots spots, only if we are at fluorescence view
            if FLAGS.f_flag && FLAGS.s_flag && isfield(data_,'CellA')
                intPlotSpot( data_, x_, y_, FLAGS, ID_LIST, CONST );
            end
            
            % plots poles
            if FLAGS.p_flag
                intPlotPole( data_, x_, y_, FLAGS);
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


function im = makeIm( data, FLAGS, ID_LIST, CONST )
% makeIm puts together the image if data is segmented
% but not the text/pole/other labels.
% INPUT :
% data : is a loaded seg or trk file with region info
% FLAGS : are the flags used for image plotting
% ID_LIST : are the ids of cells selected through a clist
% CONST : are the segmentation constants

persistent colormap_;
if isempty( colormap_ )
    colormap_ = colormap( 'jet' );
end

% get the image size
ss = size(data.phase);


% if the phase image exists use this as the background, else use the cell
% masks
phase_level = FLAGS.phase_level;
if isfield(data,'phase') && FLAGS.phase_flag
    back = phase_level * ag(data.phase);
    im = cat(3,back,back,back);
else
    mask = phase_level * ag(~data.mask_cell);
    im = cat(3, mask,mask,mask);
end


% this code highlights the lysed cells
if isfield( data, 'regs' ) && isfield( data.regs, 'lyse' ) && FLAGS.lyse_flag
    is_lyse = and( or( data.regs.lyse.errorColor1bCum, ...
        data.regs.lyse.errorColor2bCum), data.regs.lyse.errorShapeCum);
    lyse_im = intDoOutline2(ismember( ...
        data.regs.regs_label,find(is_lyse)));
else
    lyse_im = zeros( ss );
end



% if you are in fluorescence mode (f_flag) draw the fluor channels
if FLAGS.composite
    nc = numel(find(~cellfun('isempty',strfind(fieldnames(data),'fluor'))));
    
    for i = 1 : nc
        im = updateFluorImage(data, im, i, FLAGS, CONST);
    end
    
elseif FLAGS.f_flag > 0
    im = updateFluorImage(data, im, FLAGS.f_flag, FLAGS, CONST);
end

if FLAGS.Outline_flag  % it just outlines the cells
    if FLAGS.cell_flag && isfield(data,'cell_outline')
        im(:,:,:) = im(:,:,:) + cat(3,0.4*ag(data.cell_outline),0.4*ag(data.cell_outline),0.5*ag(data.cell_outline));
    elseif isfield(data,'outline')
        im(:,:,:) = im(:,:,:) + cat(3,0.3*ag(data.outline),0.3*ag(data.outline),0.5*ag(data.outline));
    elseif isfield(data,'mask_cell')% no outline field (not loaded through super segger viewer)
        data.outline = xor(bwmorph( data.mask_cell,'dilate'), data.mask_cell);
        im(:,:,:) = im(:,:,:) + cat(3,0.3*ag(data.outline),0.3*ag(data.outline),0.5*ag(data.outline));
    end
    
elseif FLAGS.P_flag  % if P_flag is true, it shows the regions with color.
    
    if ~isfield( data,'regs') || ~isfield( data.regs, 'ID') % no cell ids - seg files
        
        blueChannel = 0.3*(data.mask_cell);
        reg_color = uint8( 255*cat(3, 0*blueChannel,blueChannel,blueChannel));
        im = reg_color + im;
        
    else
        
        if isfield( data.regs, 'ignoreError' )
            ignoreErrorV = data.regs.ignoreError;
        else
            ignoreErrorV = 0*data.reg.divide;
        end
        
        % cells in the ID list and in this region
        % if v_flag is off, all cells are in is_in_cell_V
        cells_In_Frame   = ismember( data.regs.ID, ID_LIST);
        cellBorn = or(and(data.regs.birthF,data.regs.stat0),data.regs.divide);
        
        % cells with ehist & error current->reverse or ignoreError
        map_error_ind = find(and(cells_In_Frame,or(and(data.regs.ehist,...
            data.regs.error.r),ignoreErrorV)));
        map_err_rev  = double(ismember( data.regs.regs_label, map_error_ind ));
        
        % cells with ehist in this frame, but no error current->reverse or ignoreError
        map_ehist_in_frame_ind = find(and(cells_In_Frame,or(and(data.regs.ehist,...
            ~data.regs.error.r),ignoreErrorV)));
        map_ehist_in_frame  = double(ismember( data.regs.regs_label, map_ehist_in_frame_ind ));
        
        
        % cells without error history
        map_no_err_ind =  find(and(cells_In_Frame,or(~data.regs.ehist,ignoreErrorV)));
        map_no_err  = double(ismember( data.regs.regs_label, map_no_err_ind));
        
        % in list, cell was not born in this frame with good division or divided
        % but stat0==2 : succesfful division was observed
        map_stat0_2_ind = find(and(cells_In_Frame,data.regs.stat0==2));
        map_stat0_2 = double(ismember( data.regs.regs_label,map_stat0_2_ind ));
        
        % outline the ones that were just born with stat0 == 2
        map_stat0_2O_ind = find(and(cells_In_Frame,and(cellBorn,data.regs.stat0==2)));
        map_stat0_2_Outline = intDoOutline2(ismember(data.regs.regs_label, map_stat0_2O_ind));
        
        
        % in list, cell was not born in this frame with good division or divided
        % stat0==1 : cell was result of succesfful division
        map_stat0_1_ind  = find(and(cells_In_Frame,data.regs.stat0==1));
        map_stat0_1  = double( ismember( data.regs.regs_label,map_stat0_1_ind ));
        
        % outline the ones that were just born with stat0 == 1
        map_stat0_1O_ind = find(and(cells_In_Frame,and(cellBorn,data.regs.stat0==1)));
        map_stat0_1_Outline = intDoOutline2(ismember(data.regs.regs_label, map_stat0_1O_ind));
        
        
        % in list, cell was not born in this frame with good division or divided
        % stat0 == 0  : cell has errors, or division not observed
        map_stat0_0_ind = find(and(cells_In_Frame,data.regs.stat0==0));
        map_stat0_0 = double(ismember( data.regs.regs_label, map_stat0_0_ind ));
        
        % outline the ones that were just born with stat0 == 1
        map_stat0_0O_ind = find(and(cells_In_Frame,and(cellBorn,data.regs.stat0==0)));
        map_stat0_0_Outline = intDoOutline2(ismember(data.regs.regs_label, map_stat0_0O_ind));
        
        
        
        redChannel =  double(lyse_im)+0.5*(0.7*(map_err_rev)+1.1*(map_ehist_in_frame)+.7*(map_stat0_2_Outline+map_stat0_1_Outline +map_stat0_0_Outline));
        greenChannel =  0.3*(map_no_err) - 0.2*(map_stat0_1)+0.2*(map_stat0_0);
        blueChannel = 0.7*(map_stat0_2)+ 0.6*(map_stat0_1)+0.3*(map_stat0_0);
        
        reg_color = uint8( 255*cat(3, redChannel,greenChannel,blueChannel));
        
        im = reg_color + im;
        
    end
    %% colors :
    % baby-blue : no errors, stat0=2 cells
    % tirquaz :  stat0 = 1 cells
    % deep green : stat0 = 0 cells
    % pink : has error in reverse frame
    % purple : has error in forward frame
    % red outlines : dividing or has just divided
    
end

end


function im = updateFluorImage(data, im, channel, FLAGS, CONST)

fluorName =  ['fluor',num2str(channel)];

fluorName =  ['fluor',num2str(channel)];
flbgName =  ['fl',num2str(channel),'bg'];
if isfield(data, fluorName )
    if ~isfield (CONST.view,'fluorColor')
        CONST.view.fluorColor = {'g','r','b'};
    end
    
    curColor = getRGBColor( CONST.view.fluorColor{channel});
    
    if FLAGS.filt && isfield( data, [fluorName,'_filtered'] )
        fluor_tmp =  data.([fluorName,'_filtered']);
    else
        fluor_tmp = data.(fluorName);
        if isfield( data, 'fl1bg' )
            fluor_tmp = fluor_tmp - data.(flbgName);
            fluor_tmp( fluor_tmp< 0 ) = 0;
        else
            fluor_tmp = fluor_tmp-mean(fluor_tmp(:));
            fluor_tmp( fluor_tmp< 0 ) = 0;
        end
    end
    
    if isfield( CONST.view, 'LogView' ) && CONST.view.LogView && ~FLAGS.composite
        fluor_tmp =   ag( double(fluor_tmp).^.6 );
    end
    
    
    minner = medfilt2( fluor_tmp, [2,2], 'symmetric' );
    maxxer = max( minner(:));
    minner = min( minner(:));
    if CONST.view.falseColorFlag
        im = im + doColorMap( ag(fluor_tmp,minner,maxxer), uint8(255*jet(256)) );
    else
        imFluor = 0.8*ag(fluor_tmp,minner,maxxer);
        im(:,:,1) = im(:,:,1) + curColor(1) * imFluor;
        im(:,:,2) = im(:,:,2) + curColor(2) * imFluor;
        im(:,:,3) = im(:,:,3) + curColor(3) * imFluor;
    end
    
    
end
end


function intPlotScores( data, x_, y_ , FLAGS )
% intPlotNum : Plot cell number or region numbers

counter = 200; % max amount of cell numbers to be plotted
kk = 0; % counter for regions
while (counter > 0 && kk < data.regs.num_regs)
    % disp(counter)
    kk = kk + 1;
    rr = data.regs.props(kk).Centroid;
    
    if isfield( data.regs, 'ignoreError' )
        ignoreError = data.regs.ignoreError(kk);
    else
        ignoreError = 0;
    end
    
    score = 1 - (data.regs.scoreRaw(kk) + 50) / 100;
    
    colorMap = spring(256);
    colorIndex = floor(min(score, 1) * 255) + 1;
    
    xpos = rr(1)+x_;
    ypos = rr(2)+y_;
    
    if (FLAGS.axis(1)<xpos) && (FLAGS.axis(2)>xpos) && ...
            (FLAGS.axis(3)<ypos) && (FLAGS.axis(4)>ypos)
        
        counter = counter - 1;
        
        text( xpos, ypos, ['\fontsize{11}',num2str(data.regs.scoreRaw(kk), 2)],...
            'Color', [colorMap(colorIndex, 1), colorMap(colorIndex, 2), colorMap(colorIndex, 3)],...
            'FontWeight', 'normal',...
            'HorizontalAlignment','Center',...
            'VerticalAlignment','Middle');
        title('Region Scores');
    end
    
end
end

function intPlotNum( data, x_, y_ , FLAGS, ID_LIST )
% intPlotNum : Plot cell number or region numbers

counter = 1000; % max amount of cell numbers to be plotted
kk = 0; % counter for regions
xpos_id =[];
ypos_id = [];
str_id = {};
color = [];
while (counter > 0 && kk < data.regs.num_regs)
    % disp(counter)
    kk = kk + 1;
    rr = data.regs.props(kk).Centroid;
    
    if isfield( data.regs, 'ignoreError' )
        ignoreError = data.regs.ignoreError(kk);
    else
        ignoreError = 0;
    end
    
    setRed = false;
    if isfield (data.regs, 'error') && data.regs.error.r(kk)
        setRed = true;
    end
    
    xpos = rr(1)+x_;
    ypos = rr(2)+y_;
    
    if (FLAGS.axis(1)<xpos) && (FLAGS.axis(2)>xpos) && ...
            (FLAGS.axis(3)<ypos) && (FLAGS.axis(4)>ypos)
        
        counter = counter - 1;
        if FLAGS.cell_flag == 1 && isfield( data.regs, 'ID' )
            xpos_id = [xpos_id;xpos];
            ypos_id = [ypos_id;ypos];
            if setRed
                str_id{end+1} = ['{\color{red}',num2str(data.regs.ID(kk)),'}'];
            else
                str_id{end+1} = num2str(data.regs.ID(kk));
            end
            
        else % region view cell_flag is 0
            xpos_id = [xpos_id;xpos];
            ypos_id = [ypos_id;ypos];
            if setRed
                str_id{end+1} = ['{\color{red}',num2str(kk),'}'];
            else
                str_id{end+1} = num2str(num2str(kk));
            end
        end
    end
    
end


if FLAGS.cell_flag == 1 && isfield( data.regs, 'ID' )
    hhh = title('Cell ID');
    set(hhh, 'Color', [0,0,0] );
    text( xpos_id, ypos_id,str_id,...
        'color','w',...
        'FontWeight', 'Bold',...
        'HorizontalAlignment','Center',...
        'VerticalAlignment','Middle',...
        'FontSize', 8);
else
    hhh = title('Region Number');
    set(hhh, 'Color', [0,0,0] );
    text( xpos_id, ypos_id,str_id,...
        'color','w',...
        'HorizontalAlignment','Center',...
        'VerticalAlignment','Middle',...
        'FontSize', 8);
end
end

function intPlotSpot( data, x_, y_, FLAGS, ID_LIST, CONST )
% intPlotSpot : plots each foci in the cells


if isfield( data, 'CellA' ) && ~isempty( data.CellA ) && ...
        (isfield( data.CellA{1}, 'locus1') || (isfield( data.CellA{1}, 'locus2')))
    
    counter1 = 0;
    counter2 = 0;
    maxCounter1 = 500;
    maxCounter2 = 500;
    locus_1_txt = {};
    locus1_x = [];
    locus1_y = [];
    locus_2_txt = {};
    locus2_x = [];
    locus2_y = [];
    for kk = 1:data.regs.num_regs
        % only plot spots in the cell that are gated.
        if (~FLAGS.cell_flag || ismember(data.regs.ID(kk), ID_LIST))
            % locus 1
            if isfield( data.CellA{kk}, 'locus1') &&  ( FLAGS.f_flag == 1 );
                num_spot = numel( data.CellA{kk}.locus1);
                mm = 0;
                while mm < num_spot && counter1 < maxCounter1
                    mm = mm + 1;
                    r = data.CellA{kk}.locus1(mm).r;
                    text_ = [num2str(data.CellA{kk}.locus1(mm).score, '%0.1f')];
                    if data.CellA{kk}.locus1(mm).score > CONST.getLocusTracks.FLUOR1_MIN_SCORE
                        xpos = r(1)+x_;
                        ypos = r(2)+y_;
                        if (FLAGS.axis(1)<xpos) && (FLAGS.axis(2)>xpos) && ...
                                (FLAGS.axis(3)<ypos) && (FLAGS.axis(4)>ypos)
                            counter1 = counter1 + 1;
                            locus_1_txt{end+1} = [num2str(data.CellA{kk}.locus1(mm).score, '%0.1f')];
                            locus1_x = [locus1_x;xpos];
                            locus1_y = [locus1_y;ypos];
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
                    if data.CellA{kk}.locus2(mm).score > CONST.getLocusTracks.FLUOR2_MIN_SCORE && ...
                            data.CellA{kk}.locus2(mm).b < 3
                        xpos = r(1)+x_;
                        ypos = r(2)+y_;
                        if (FLAGS.axis(1)<xpos) && (FLAGS.axis(2)>xpos) && ...
                                (FLAGS.axis(3)<ypos) && (FLAGS.axis(4)>ypos)
                            counter2 = counter2 + 1;
                            locus_2_txt{end+1} = [num2str(data.CellA{kk}.locus2(mm).score, '%0.1f')];
                            locus2_x = [locus2_x;xpos];
                            locus2_y = [locus2_y;ypos];
                        end
                    end
                end
            end
        end
    end
    
    
    text( locus2_x+1, locus2_y, locus_2_txt, 'Color', [1,0.5,0.5]);
    plot( locus2_x, locus2_y, '.', 'Color', [1,0.5,0.5]);
    
    text( locus1_x+1, locus1_y, locus_1_txt, 'Color', [0.5,1,0.5]);
    plot( locus1_x, locus1_y, '.', 'Color', [0.5,1,0.5]);
    
end
end

function intPlotLinks( data, data_r, data_f, x_, y_, FLAGS, ID_LIST, CONST )
% intPlotLinks : plots the links to the next and previous frames

dataHasIds = isfield( data, 'regs' ) && isfield( data.regs,'ID' );
dataRHasIds = ~isempty(data_r) && isfield( data_r, 'regs' ) && isfield( data_r.regs,'ID' );
dataFHasIds = ~isempty(data_f) && isfield( data_f, 'regs' ) && isfield( data_f.regs,'ID' );

%Plot reverse links
if dataHasIds
    colorMap = hsv(10);
    
    counter = 0;
    maxCounter = 500;
    
    for kk = 1:data.regs.num_regs
        % only plot links in the cell that are gated.
        if data.regs.ID(kk) ~= 0 && (~FLAGS.cell_flag || ismember(data.regs.ID(kk), ID_LIST))
            previousRegion = [];
            nextRegion = [];
            
            if dataRHasIds && data.regs.ID(kk) ~= 0
                previousRegion = find(data_r.regs.ID == data.regs.ID(kk));
                
                if previousRegion == 0
                    previousRegion = [];
                end
            end
            if dataFHasIds && data.regs.ID(kk) ~= 0
                nextRegion = find(data_f.regs.ID == data.regs.ID(kk));
                
                if nextRegion == 0
                    nextRegion = [];
                end
            end
            
            color = colorMap(mod(kk, 10) + 1, :);
            valid = 0;
            
            if ~isempty(previousRegion)
                X = [data_r.regs.props(previousRegion).Centroid(1) + x_, data.regs.props(kk).Centroid(1) + x_];
                Y = [data_r.regs.props(previousRegion).Centroid(2) + y_, data.regs.props(kk).Centroid(2) + y_];
                
                plot(X, Y, 'Color', color);
                
                valid = 1;
            else
                if data.regs.age(kk) == 1
                    motherRegion = [];
                    
                    if dataRHasIds && data.regs.motherID(kk) ~= 0
                        motherRegion = find(data_r.regs.ID == data.regs.motherID(kk));
                        
                        if motherRegion == 0
                            motherRegion = [];
                        end
                    end
                    
                    if ~isempty(motherRegion)
                        if FLAGS.showMothers == 1
                            X = [data_r.regs.props(motherRegion).Centroid(1) + x_, data.regs.props(kk).Centroid(1) + x_];
                            Y = [data_r.regs.props(motherRegion).Centroid(2) + y_, data.regs.props(kk).Centroid(2) + y_];
                            
                            plot(X, Y, 'Color', color);
                        end
                        
                        valid = 1;
                    else
                        valid = 0;
                    end
                end
            end
            
            if ~isempty(nextRegion)
                X = [data_f.regs.props(nextRegion).Centroid(1) + x_, data.regs.props(kk).Centroid(1) + x_];
                Y = [data_f.regs.props(nextRegion).Centroid(2) + y_, data.regs.props(kk).Centroid(2) + y_];
                plot(X, Y, 'Color', color);
                plot(X(1), Y(1), 's', 'Color', color);
            else
                if data.regs.deathF(kk)
                    daughterRegions = [];
                    
                    if dataFHasIds && data.regs.ID(kk) ~= 0
                        daughterRegions = find(data_f.regs.motherID == data.regs.ID(kk));
                        
                        if min(daughterRegions) == 0
                            daughterRegions = [];
                        end
                    end
                    
                    if ~isempty(daughterRegions)
                        if FLAGS.showDaughters == 1
                            for i = 1:numel(daughterRegions)
                                X = [data_f.regs.props(daughterRegions(i)).Centroid(1) + x_, data.regs.props(kk).Centroid(1) + x_];
                                Y = [data_f.regs.props(daughterRegions(i)).Centroid(2) + y_, data.regs.props(kk).Centroid(2) + y_];
                                
                                plot(X, Y, 'Color', color);
                                plot(X(1), Y(1), 's', 'Color', color);
                            end
                        end
                    else
                        valid = 0;
                    end
                else
                    valid = 0;
                end
            end
            
            X =  data.regs.props(kk).Centroid(1) + x_;
            Y =  data.regs.props(kk).Centroid(2) + y_;
            if valid == 0
                plot(X, Y, 'x', 'Color', color);
            else
                plot(X, Y, 'o', 'Color', color);
            end
        end
        
        counter = counter + 1;
        if counter >= maxCounter
            break;
        end
    end
end
end

function intPlotPole( data, x_, y_,FLAGS )
% intPlotPole shows pole positions and connects daughter cells to each other
if ~isfield(data,'CellA')
    disp ('Showing poles is not supported in this mode (seg files)');
    return;
else
    for kk = 1:data.regs.num_regs
        
        rr1 = data.regs.props(kk).Centroid;
        ID  = data.regs.ID(kk);
        sisterID = data.regs.sisterID(kk);
        
        if sisterID
            ind = find(data.regs.ID == sisterID);
            if numel(ind)>1
                ind = ind(1);
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
                
                if tmp.pole.op_ori
                    old_pole = r + tmp.length(1)*tmp.coord.e1*tmp.pole.op_ori/2;
                    new_pole = r - tmp.length(1)*tmp.coord.e1*tmp.pole.op_ori/2;
                else
                    old_pole = r + tmp.length(1)*tmp.coord.e1/2;
                    new_pole = r - tmp.length(1)*tmp.coord.e1/2;
                end
            catch ME
                printError(ME);
            end
            
            
            if (FLAGS.axis(1)<r(1)) && (FLAGS.axis(2)>r(1)) && ...
                    (FLAGS.axis(3)<r(2)) && (FLAGS.axis(4)>r(2))
                
                line = plot([r(1),new_pole(1)], [r(2),new_pole(2)], 'r' );
                
                p_old = plot( old_pole(1)+x_, old_pole(2)+y_, 'ro','MarkerSize',6);
                p_new = plot( new_pole(1)+x_, new_pole(2)+y_, 'r*','MarkerSize',6);
                
                
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
    if FLAGS.legend
        legend([p_old,p_new,line],{'Old Pole', 'New pole','Sisters'},'location','BestOutside');
    end
end
end


function [xx,yy] = intGetImSize( data, FLAGS )
% intGetImSize : gets size of regions labels  and fills up xx and yy
% from 1 to the size of the image.


if isfield( data, 'regs' )
    ss = size(data.regs.regs_label);
    
    if FLAGS.T_flag % tight flag
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
% Outline_flag
% ID_flag
% lyse_flag
% m_flag
% c_flag

if ~isfield(FLAGS, 'legend');
    disp('there is no flag field legend');
    FLAGS.legend = 1;
end

if ~isfield(FLAGS, 'Outline_flag');
    disp('there is no flag field Outline_flag');
    FLAGS.Outline_flag = 0;
end
if ~isfield(FLAGS, 'ID_flag');
    disp('there is no flag field ID_flag');
    FLAGS.ID_flag = 1;
end

if ~isfield(FLAGS, 'lyse_flag');
    disp('there is no flag field lyse_flag')
    FLAGS.lyse_flag = 0;
end

if ~isfield(FLAGS,'m_flag');
    disp('there is no flag field m_flag')
    FLAGS.m_flag = 0;
end

if ~isfield(FLAGS, 'c_flag');
    disp('there is no flag field c_flag')
    FLAGS.c_flag = 0;
end

if ~isfield(FLAGS, 'P_flag');
    disp('there is no flag field P_flag')
    FLAGS.P_flag = 1;
end


if ~isfield(FLAGS, 'phase_flag');
    disp('there is no flag field P_flag')
    FLAGS.phase_flag = 1;
end

if ~isfield(FLAGS, 'phase_level');
    disp('there is no flag field P_flag')
    FLAGS.phase_level = 1;
end

if ~isfield(FLAGS, 'cell_flag' );
    disp('there is no flag field cell_flag')
    FLAGS.cell_flag = 0;
end

if ~isfield(FLAGS, 'f_flag');
    disp('there is no flag field f_flag')
    FLAGS.f_flag = 0;
end

if ~isfield(FLAGS, 's_flag');
    disp('there is no flag field s_flag')
    FLAGS.s_flag = 0;
end

if ~isfield(FLAGS, 'T_flag');
    disp('there is no flag field T_flag')
    FLAGS.T_flag = 0;
end

if ~isfield(FLAGS, 'filt')
    disp('there is not field filt_flag')
    FLAGS.filt = [0,0,0];
end

if ~isfield(FLAGS, 'p_flag');
    disp('there is not field p_flag')
    FLAGS.p_flag = 0;
end

if ~isfield(FLAGS,'composite')
    disp('there is not field composite')
    FLAGS.composite  = 0;
end


if ~isfield(FLAGS, 'showLinks');
    disp('there is not field showLinks')
    FLAGS.showLinks = 0;
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