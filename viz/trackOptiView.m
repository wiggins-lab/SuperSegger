function trackOptiView(dirname,file_filter,err_flag)
% trackOptiView provides visulization of the segmented data.
%
% It has a lot of options such as :
% f : Toggle between phase and fluorescence view
% x# :  Switch xy dir #
% t  : Show Cell Numbers
% r  : Show/Hide Region Outlines
% o  : Show Consensus
% K  : Kymograph Mosaic
% h# : Tower for Cell #
% g  : Make Gate
% Clear : Clear all Gates
% c  : Reset Plot to Default View'
% s  : Show Fluor Foci
% #  : Go to Frame Number #
% CC : Use Complete Cell Cycles
% F : Find Cell Number #
% p  : Show/Hide Cell Poles
% H# : Show Kymograph for Cell #
% Z  : Cell Towers Mosaic
% G  : Gate All Cell Files
% Movie : Export Movie Frames
%
% INPUT :
%       dirname : directory that contains file segemented by supeSegger
%       file_filter : used to obtain the contents (deafult .err file)
%       err_flag : if 1, displays errors found in frame, default 0
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

%% Load Constants and Initialize Flags

hf = figure(1);
clf;
%set( hf, 'Color', [0.1,0.1,0.1] );

mov = struct;
CONST = [];
touch_list = [];


if nargin<2 || isempty(file_filter);
    file_filter = '*err.mat';
end

if nargin<3 || isempty(err_flag);
    err_flag = 0;
end

FLAGS.err_flag = err_flag;


if ~exist('strip_flag');
    strip_flag = 1;
end

% Add slash to the file name if it doesn't exist
if(nargin<1 || isempty(dirname))
    
    dirname=uigetdir()
    dirname=[dirname,filesep];
else
    if dirname(end)~=filesep
        dirname=[dirname,filesep];
    end
end

D_FLAG = [];

n_char    = numel(dirname);
seg_pos   = strfind( dirname, ['seg',filesep]);

if (n_char - seg_pos) == (numel(['seg',filesep])-1)
    disp( 'seg mode' );
    D_FLAG = SD_FLAG;
else
    if exist( [dirname,filesep,'raw_im'],'dir')
        D_FLAG = AD_FLAG;
    else
        D_FLAG = ND_FLAG;
    end
end

dirname0 = dirname;


% load flags if they already exist to maintain state between launches
filename_flags = [dirname0,'.trackOptiView.mat'];
if  (D_FLAG == AD_FLAG) && exist( filename_flags, 'file' )
    load(filename_flags);
else
    FLAGS = intSetDefaultFlags();
    
    error_list = [];
    nn = 1;
    dirnum = 1;
end

contents = [];

% Load info from one of the xy directories. dirnum tells you which one. If
% you quit the program in an xy dir, it goes to that xy dir.
clist = [];
if D_FLAG == AD_FLAG
    contents_xy =dir([dirname, 'xy*']);
    
    % Load up the aska set name from the file header.mat
    setHeaderFileName = [dirname,'header.mat'];
    if exist( setHeaderFileName, 'file' );
        setHeader = load( setHeaderFileName );
        setHeader = setHeader.header;
    else
        setHeader = [];
    end
    
    try
        dircons = [dirname0,'consensus',filesep];
        mkdir( dircons );
    end
    
    num_xy = numel(contents_xy);
    if ~num_xy
        disp('no xy dirs');
        return;
    else
        if isdir([dirname0,contents_xy(dirnum).name,filesep,'seg_full'])
            dirname = [dirname0,contents_xy(dirnum).name,filesep,'seg_full',filesep];
        else
            dirname = [dirname0,contents_xy(dirnum).name,filesep,'seg',filesep];
        end
        
        dirname_cell = [dirname0,contents_xy(dirnum).name,filesep,'cell',filesep];
        dirname_xy = [dirname0,contents_xy(dirnum).name,filesep];
        
        % Open clist if it exists
        clist_name = [dirname0,contents_xy(dirnum).name,filesep,'clist.mat'];
        if exist( clist_name, 'file' )
            clist = load([dirname0,contents_xy(dirnum).name,filesep,'clist.mat']);
        else
            clist = [];
        end
        
        ixy = intGetNum( contents_xy(dirnum).name );
        header = ['xy',num2str(ixy),': '];
        
    end
    nameInfo = [];
elseif D_FLAG == ND_FLAG
    [nameInfo] = getDirStruct( dirname0 );
    num_xy = numel(nameInfo.nxy);
    header = ['xy',num2str(dirnum),': '];
    
end


FLAGS.D_flag  = D_FLAG;

if (D_FLAG == AD_FLAG) || (D_FLAG == SD_FLAG)
    contents=dir([dirname, file_filter]);
    num_im = length(contents);
else
    num_im = numel(nameInfo.nt);
end


try
    CONST = load([dirname0,'CONST.mat']);
    if isfield( CONST, 'CONST' )
        CONST = CONST.CONST;
    end
catch
    disp(['Exiting. Can''t load CONST file. Make sure there is a CONST.mat file at the root', ...
        'level of the data directory.']);
    return
end

if nn > num_im
    nn = num_im;
end


runFlag = (nn<=num_im);
first_flag = 1;

% This flag controls whether you reload from file
resetFlag = true;
FLAGS.e_flag = 0 ;

%% Run the main loop... and run it while the runFlag is true.
while runFlag
    
    % load current frame
    if resetFlag
        resetFlag = false;
        [data_r, data_c, data_f] = intLoadData( dirname, ...
            D_FLAG, contents, nn, num_im, nameInfo, clist, dirnum);
    end
    
    if ~first_flag
        tmp_axis = axis;
    else
        try
            imshow( data_c.phase );
        end
        
    end

    showDA4new( data_c, data_r, data_f, FLAGS, clist, CONST);

    
    if FLAGS.c_flag && ~first_flag
        axis( tmp_axis );
    end
    first_flag = false;
    
    
    
    % Main Menu
    disp('-----------------------------------------------------------');
    disp('SuperSegger Data Viewer');
    disp(' ');
    disp('q  : To quit                    c  : Reset Plot to Default View');
    disp('f  : Toggle Phase/Fluor         s  : Show Fluor Foci           ');
    disp('x# : Switch xy dir #            #  : Go to Frame Number #      ');
    disp('t  : Show Cell Numbers          CC : Use Complete Cell Cycles ');
    disp('r  : Show/Hide Region Outlines  F# : Find Cell Number #       ');
    disp('o  : Show Consensus             p  : Show/Hide Cell Poles      ');
    disp('K  : Kymograph Mosaic           H# : Show Kymograph for Cell #');
    disp('h# : Tower for Cell #           Z  : Cell Towers Mosaic        ');
    disp('g  : Make Gate                  G  : Gate All Cell Files       ');
    disp('Clear : Clear all Gates         Movie : Export Movie Frames   ');
    disp(' ');
    disp('              k : Enter debugging mode                      ');
    disp('-----------------------------------------------------------')
    disp(' ');
    
    % if you loaded segmented data
    if D_FLAG ~= ND_FLAG
        % show the master error list.
        if FLAGS.err_flag
            if isempty(error_list)
                error_list = trackOptiGetErrorListDisk( dirname, [] );
            end
            disp(error_list);
        end
        % show errors in this frame.
        if FLAGS.e_flag
            intDispError( data_c, FLAGS );
        end
    end
    
    if ~isempty( touch_list );
        disp('Warning! Frames touched. Run re-link.');
        touch_list
    end
    
    
    disp([header, 'Frame num [1...',num2str(num_im),']: ',num2str(nn)]);
    
    c = input(':','s')
    
    % LIST OF COMMANDS  
    if isempty(c)
        % do nothing
    
    elseif c(1) == 'q' % Quit Command
        if D_FLAG == AD_FLAG
            try
                save( [dirname0,contents_xy(dirnum).name,filesep,'clist.mat'],'-STRUCT','clist');
            catch
                disp('Error saving clist file.');
            end
        end
        runFlag = 0  ;
                
    elseif strcmp(c,'CC') % Toggle Between Full Cell Cycles
        CONST.view.showFullCellCycleOnly = ~CONST.view.showFullCellCycleOnly ;
        if CONST.view.showFullCellCycleOnly
            disp('Only including complete Cell Cycles (press any key)')
            pause
        else
            disp('Including Incomplete Cell Cycles (press any key)')
            pause
        end
           
    elseif c(1) == 'F' % Find Single Cells        
        if numel(c) > 1
            find_num = floor(str2num(c(2:end)));
            if FLAGS.v_flag
                regnum = find( data_c.regs.ID == find_num);
                
                if ~isempty( regnum )
                    plot(data_c.CellA{regnum}.coord.r_center(1),...
                        data_c.CellA{regnum}.coord.r_center(2), ...
                        'yx','MarkerSize',100);
                else
                    disp('coundt fidn that cell');
                end
                
            else
                if (find_num <= data_c.regs.num_regs) && (find_num >0)
                    plot(data_c.CellA{find_num}.coord.r_center(1),...
                        data_c.CellA{find_num}.coord.r_center(2), ...
                        'yx','MarkerSize',100);
                else
                    disp( 'Out of range' );
                end
            end
            
            input('Press any key','s');
            
        end
                
    elseif c(1) == 'x' % Change xy positions
        if D_FLAG ~= SD_FLAG
            
            if numel(c)>1
                c = c(2:end);
            else
                for ll = 1:num_xy
                    if D_FLAG ~= ND_FLAG
                        disp( [num2str(ll),': ',contents_xy(ll).name] );
                    else
                        disp( [num2str(ll),': xy',num2str(nameInfo.nxy(ll))] );
                    end
                end
                c = input(':','s')
            end
            ll_ = floor(str2num(c));
            
            if ~isempty(ll_) && (ll_>=1) && (ll_<=num_xy)
                if D_FLAG ~= ND_FLAG
                    
                    
                    if D_FLAG == AD_FLAG
                        try
                            save( [dirname0,contents_xy(dirnum).name,filesep,'clist.mat'],'-STRUCT','clist');
                        catch
                            disp( 'Error writing clist file.');
                        end
                    end
                    
                    dirnum = ll_;
                    
                    if isdir([dirname0,contents_xy(dirnum).name,filesep,'seg_full'])
                        dirname = [dirname0,contents_xy(ll_).name,filesep,'seg_full',filesep];
                    else
                        dirname = [dirname0,contents_xy(ll_).name,filesep,'seg',filesep];
                    end
                    
                    dirname_cell = [dirname0,contents_xy(ll_).name,filesep,'cell',filesep];
                    dirname_xy = [dirname0,contents_xy(ll_).name,filesep];
                    
                    ixy = intGetNum( contents_xy(dirnum).name );
                    header = ['xy',num2str(ixy),': '];
                    
                    contents=dir([dirname, file_filter]);
                    error_list = [];
                    
                    
                    clist = load([dirname0,contents_xy(ll_).name,filesep,'clist.mat']);
                else
                    dirnum = nameInfo.nxy(ll_);
                    header = ['xy',num2str(dirnum),': '];
                    
                end
            end
            resetFlag = true;
        else
            disp( 'Not supported in this mode.' );
        end
        
        
    elseif c(1) == 'r' % Show/Hide Region Outlines
        FLAGS.P_flag = ~FLAGS.P_flag;
               
    elseif strcmp(c,'c') % Reset Plot to Default View
        FLAGS.c_flag = ~FLAGS.c_flag;
        clf;
        first_flag = 1;
               
    elseif c(1) == 'f'  % Toggle Between Fluorescence and Phase Images
        FLAGS.f_flag = ~FLAGS.f_flag;
              
    elseif c(1) == 'g' % choose characteristics and values to gate cells       
        disp('Choose gating characteristic')
        disp(clist.def')
        cc = input('Gate Number(s) [ ] :','s') ;
        tmp_clist = gateMake(clist,str2num(cc)) ;
        
        clist = tmp_clist ;
        clf;
        first_flag = 1;
              
    elseif strcmp(c,'Clear')  % Clear All Gates
        clist.gate = [] ;
        clf;
        first_flag = 1;
              
    elseif c(1) == 'G'   % moves gated cell Files to a different directory
        header = 'trackOptiView: ';       
        trackOptiGateCellFiles(dirname,dirname_cell,CONST, header, clist);
            
    elseif c(1) == 'C' % Gate All XY Positions
        if D_FLAG == AD_FLAG
                       
            if ~isfield( clist, 'gate' );
                clist.gate = [];
            end
            
            for ll_ = 1:num_xy
                filename = [dirname0,contents_xy(ll_).name,filesep,'clist.mat'];
                
                clist_tmp = gate(load( filename ));
                if  ll_ == 1
                    clist_comp =clist_tmp;
                else
                    clist_comp.data = [clist_comp.data; clist_tmp.data];
                end
            end
            
            save( [dirname0,'clist_comp.mat'], '-STRUCT', 'clist_comp' );
            
        else
            disp('Not supported');
        end
                       
    elseif c(1) == 't' % Show Cell Numbers
        FLAGS.t_flag = ~FLAGS.t_flag;
                
    elseif c(1) == 's' % Show Fluorescent Foci Fits
        FLAGS.s_flag = ~FLAGS.s_flag;
               
    elseif c(1) == 'p'  % Show Cell Poles
        FLAGS.p_flag = ~FLAGS.p_flag;
                
    elseif c(1) == 'k' % Enter Debugging Mode
        tmp_axis = axis;
        disp('Type "return" to exit debugging mode')
        keyboard
        resetFlag = true;
        clf;
        axis( tmp_axis );
        
        
    elseif c(1) == 'K' % Make Kymograph Mosaic for All Cells
        if D_FLAG == AD_FLAG
            tmp_axis = axis;
            clf;
            makeKymoMosaic( dirname_cell, CONST );           
            disp('press enter to continue.');
            pause;
            axis(tmp_axis);
        else
            disp( 'Not supported in this mode.' );
        end
        
    elseif c(1) == 'Z' %  Show Cell Towers for All Cells
        if D_FLAG == AD_FLAG
            tmp_axis = axis;
            clf;
                       
            if numel(c) > 1
                ll_ = floor(str2num(c(2:end)));
            else
                ll_ = [];
            end
            
            makeFrameStripeMosaic( [dirname_cell], CONST, ll_,true );
            axis equal
            
            disp('press enter to continue.');
            pause;
            axis(tmp_axis);
        else
            disp( 'Not supported in this mode.' );
        end
        
        
    elseif c(1) == 'o' % Show existant consensus for this XY or calculate new one        
        intCons(dirname0, contents_xy(ixy), dircons, setHeader, CONST)%
                
    elseif c(1) == 'Y' % Calculate Consensus for all XY
        
        tmp_axis = axis;
        clf;     
        
        parfor iii = 1:num_xy                       
            try
                intCons(dirname0, contents_xy(iii), dircons, setHeader, CONST)
            catch
                disp( ['Failed on: ', contents_xy(iii).name] );
            end
            
        end
        
        
        FLAGS__.v_flag = 1;
        FLAGS__.m_flag = 0;
        FLAGS__.t_flag = 1;
        FLAGS__.T_flag = 0;
        FLAGS__.ID_flag = 1;
        FLAGS__.P_flag = 1;
        FLAGS__.e_flag = 0;
        FLAGS__.f_flag = 1;
        FLAGS__.s_flag = 1;
        FLAGS__.p_flag = 0;
        FLAGS__.c_flag = 1;
        FLAGS__.lyse_flag = 0;
        FLAGS__.err_flag = 0;
        FLAGS__.D_flag = 0;
        
        for iii = 1:num_xy
            
            try
                iii
                nn__ = 10;
                
                if isdir([dirname0,contents_xy(iii).name,filesep,'seg_full'])
                    dirname__ = [dirname0,contents_xy(iii).name,filesep,'seg_full',filesep];
                else
                    dirname__ = [dirname0,contents_xy(iii).name,filesep,'seg',filesep];
                end
                
                dirname_cell__ = [dirname0,contents_xy(iii).name,filesep,'cell',filesep];
                dirname_xy__ = [dirname0,contents_xy(iii).name,filesep];
                
                ixy__ = intGetNum( contents_xy(iii).name );
                header__ = ['xy',num2str(ixy),': '];
                
                contents__=dir([dirname__, file_filter]);
                error_list = [];
                
                clist__ = load([dirname0,contents_xy(iii).name,filesep,'clist.mat']);
                nameInfo__ = getDirStruct( dirname0 );
                
                [data_r__, data_c__, data_f__] = intLoadData( dirname__, ...
                    D_FLAG, contents__, nn__, num_im, nameInfo__, clist__, iii);
                            
                im_tmp = showDA4new( data_c__, data_r__, data_f__, FLAGS__, clist__, CONST);
                imwrite( im_tmp, [dircons, 'field_', setHeader, '_', num2str(ixy__,'%02d'), '.tif'], 'tif' );
            catch ME
                printError(ME);
                disp(['error with ',num2str(iii)]);
            end
        end
        
        figure(1);       
        axis equal
               
        figure(1);
        axis(tmp_axis);
        
        
    elseif c(1) == 'h' % Cell Tower for Single Cell
        
        if D_FLAG == AD_FLAG
            
            if numel(c) > 1
                comma_pos = findstr(c,',');
                
                if isempty(comma_pos)
                    ll_ = floor(str2num(c(2:end)));
                    xdim__ = [];
                else
                    ll_ = floor(str2num(c(2:comma_pos(1))));
                    xdim__ = floor(str2num(c(comma_pos(1):end)));
                end
                
                padStr = getPadSize( dirname_cell );
                
                if ~isempty( padStr )
                    data_cell = [];
                    filename_cell_C = [dirname_cell,'Cell',num2str(ll_,padStr),'.mat']
                    filename_cell_c = [dirname_cell,'cell',num2str(ll_,padStr),'.mat']
                    
                    if exist(filename_cell_C, 'file' )
                        filename_cell = filename_cell_C;
                    elseif exist(filename_cell_c, 'file' )
                        filename_cell = filename_cell_c;
                    else
                        filename_cell = [];
                    end
                    
                    if isempty( filename_cell )
                        disp( ['Files: ',filename_cell_C,' and ',filename_cell_c,' do not exist.']);
                    else
                        try
                            data_cell = load( filename_cell );
                        catch
                            disp(['Error loading: ', filename_cell] );
                        end
                        
                        if ~isempty( data_cell )
                            tmp_axis = axis;
                            clf;
                            im_tmp = makeFrameMosaic(data_cell, CONST, xdim__);
                            disp('Press enter to continue');
                            pause;
                            axis(tmp_axis);
                        end
                        
                    end
                end
            end
        else
            disp( 'Not supported in this mode.' );
        end
        
        
    elseif c(1) == 'H' % Show Kymograph for Single Cell
        
        if D_FLAG == AD_FLAG
            
            if numel(c) > 1
                ll_ = floor(str2num(c(2:end)));
                
                padStr = getPadSize( dirname_cell );
                
                if ~isempty( padStr )
                    data_cell = [];
                    filename_cell_C = [dirname_cell,'Cell',num2str(ll_,padStr),'.mat']
                    filename_cell_c = [dirname_cell,'cell',num2str(ll_,padStr),'.mat']
                    
                    if exist(filename_cell_C, 'file' )
                        filename_cell = filename_cell_C;
                    elseif exist(filename_cell_c, 'file' )
                        filename_cell = filename_cell_c;
                    else
                        filename_cell = [];
                    end
                    
                    if isempty( filename_cell )
                        disp( ['Files: ',filename_cell_C,' and ',filename_cell_c,' do not exist.']);
                    else
                        try
                            data_cell = load( filename_cell );
                        catch
                            disp(['Error loading: ', filename_cell] );
                        end
                        
                        if ~isempty( data_cell )
                            tmp_axis = axis;
                            clf;
                            makeKymographC(data_cell, 1, CONST );
                            ylabel('Long Axis (pixels)');
                            xlabel('Time (frames)' );
                            disp('Press enter to continue');
                            pause;
                            axis(tmp_axis);
                        end
                        
                    end
                end
            end
        else
            disp( 'Not supported in this mode.' );
        end
        
       
    elseif strcmp(c,'Movie')  % Make Time-Lapse Images for Movies
        setAxis = axis;
        nn_old = nn;       
        z_pad = ceil(log(num_im)/log(10));

        movdir = 'mov';
        if ~exist( movdir, 'dir' )
            mkdir( movdir );
        end
        file_tmp = ['%0',num2str(z_pad),'d'];
        
        for nn = 1:num_im
            
            [data_r, data_c, data_f] = intLoadData( dirname, ...
                D_FLAG, contents, nn, num_im, nameInfo, clist, dirnum);
            
            %clf;
            tmp_im = showDA4new( data_c,data_r, data_f, FLAGS, clist, CONST);
            %axis(setAxis);
            
            drawnow;
            disp( ['Frame number: ', num2str(nn)] );
            
            %tmp_im = frame2im(getframe);
            imwrite( tmp_im, [movdir,filesep,'mov',sprintf(file_tmp,nn),'.tif'], 'TIFF', 'Compression', 'none' );
            
        end
        nn = nn_old;
        resetFlag = true;
        

        
    %% DEVELOPER TOOLS : Use at your own risk   
    elseif c(1) == 'e' % Show Error List
        FLAGS.e_flag = ~FLAGS.e_flag;
               
    elseif c(1) == 'v'  % Toggle between cell view and region view
        FLAGS.v_flag = ~FLAGS.v_flag;       
      
    elseif strcmp(c,'editSegs')  % Edit Segments
        segsTLEdit( dirname, nn);
        
    elseif strcmp(c, 'relink') % Re-Link
        delete([dirname_cell,'*.mat']);
        delete([dirname,'*trk.mat*']);
        delete([dirname,'*err.mat*']);
        delete([dirname,'.trackOpti*']);
        delete([dirname_xy,'clist.mat']);        
        % Re-Run trackOpti
        skip = 1;
        CLEAN_FLAG = false;
        header = 'trackOptiView: ';
        trackOpti(dirname_xy,skip,CONST, CLEAN_FLAG, header);   
    
    elseif c(1) == 'n'; % pick region and ignore error      
        if FLAGS.T_flag
            disp( 'Tight flag must be off');
        else           
            x = floor(ginput(1));
            
            if ~isempty(x)
                ii = data_c.regs.regs_label(x(2),x(1));
                tmp_axis = axis();
                               
                if ~ii
                    disp('missed region');
                else
                    
                    if isfield( data_c.regs, 'ignoreError' )
                        disp(['Picked region ',num2str(ii)]);                                             
                        data_c.regs.ignoreError(ii) = 1;                        
                        save([dirname,contents(nn  ).name],'-STRUCT','data_c');
                    else                        
                        disp( 'Ignore error not implemented for your version of trackOpti.');                        
                    end
                end
            end
            
        end
        
        
    elseif strcmp(c,'link'); % Reset Linking in Current Frame
        
        if FLAGS.T_flag
            disp( 'Tight flag must be off');
        else                      
            disp('pick region to reset linking in the current frame');            
            x = floor(ginput(1));
            
            if ~isempty(x)
                ii = data_c.regs.regs_label(x(2),x(1));
                tmp_axis = axis();
                
                
                if ~ii
                    disp('missed region');
                else
                    disp(['Picked region ',num2str(ii)]);
                    showDA4new( data_f,data_c, data_f, FLAGS, clist, CONST);
                    axis( tmp_axis );
                    
                    disp( 'Click on linked cell(s). press enter to return');
                    x = floor(ginput());
                    
                    ss = size(x);
                    
                    list_of_regs = [];
                    
                    for hh = 1:ss(1);
                        
                        jj = data_f.regs.regs_label(x(hh,2),x(hh,1));
                        if jj
                            list_of_regs = [list_of_regs, jj];
                        end
                    end
                    
                    if ~isempty(list_of_regs)
                        
                        %list_of_regs
                        
                        
                        data_c.regs.ol.f{ii}    = zeros(2, 5);
                        
                        nnn = min([5,numel(list_of_regs)]);
                        
                        data_c.regs.ol.f{ii}(1,1:nnn) = 1;
                        data_c.regs.ol.f{ii}(2,1:nnn) = list_of_regs(1:nnn);
                        data_c.regs.map.f{ii}   = list_of_regs;
                        data_c.regs.error.f(ii) = double(numel(list_of_regs)>1);
                        data_c.regs.ignoreError(ii) = 1;
                        
                        for kk = list_of_regs
                            
                            data_f.regs.ol.r{kk}     = zeros(2,5);
                            
                            data_f.regs.ol.r{kk}(1,1)= 1/numel(list_of_regs);
                            data_f.regs.ol.r{kk}(2,1)= ii;
                            
                            data_f.regs.dA.r(kk)     = 1/numel(list_of_regs);
                            data_f.regs.map.r{kk}    = ii;
                            data_f.regs.error.r(kk)  = double(numel(list_of_regs)>1);
                            data_f.regs.ignoreError(kk) = 1;
                        end
                        
                        % Save files....
                        
                        save([dirname,contents(nn  ).name],'-STRUCT','data_c');
                        save([dirname,contents(nn+1).name],'-STRUCT','data_f');
                        
                    end
                end
            end
        end
        
        
        
    elseif strcmp(c,'errRez'); % ReRun Error Resolution and  linking code trackOpti
        ctmp = input('Are you sure you want to re-run error resolution? (y/n): ','s');
        
        if ismember(ctmp(1),'yY')
            % Erase all stamp files after .trackOptiSetEr.mat
            contents_stamp = dir( [dirname,filesep,'.trackOpti*'] );
            num_stamp = numel( contents_stamp );
            
            for iii = 1:num_stamp               
                if isempty( strfind( contents_stamp(iii).name,...
                        '.trackOptiLink.mat'  ) ) && ...
                        isempty( strfind( contents_stamp(iii).name,...
                        '.trackOptiErRes1.mat') ) && ...
                        isempty( strfind( contents_stamp(iii).name,...
                        '.trackOptiSetEr.mat' ) )
                    if ispc
                        eval(['!del ',dirname,filesep,...
                            contents_stamp(iii).name]);
                    else
                        eval(['!\rm ',dirname,filesep,...
                            contents_stamp(iii).name]);
                    end
                    
                end
            end
            
            if ispc
                eval(['!del ',dirname_cell,'*.mat']);
                eval(['!del ',dirname_xy,'clist.mat']);
            else
                eval(['!\rm ',dirname_cell,'*.mat']);
                eval(['!\rm ',dirname_xy,'clist.mat']);
            end
            
            % Re-Run trackOpti
            skip = 1;
            CLEAN_FLAG = false;
            header = 'trackOptiView: ';
            trackOpti(dirname_xy,skip,CONST, CLEAN_FLAG, header);
            
        end
        
    else
        % we assume that it is a number for a frame change.
        tmp_nn = str2num(c);
        if ~isempty(tmp_nn)
            nn = tmp_nn;
            if nn > num_im;
                nn = num_im;
            elseif nn< 1
                nn = 1;
            end
        end
        resetFlag = true;
        
    end
    
end

try
    save(filename_flags, 'FLAGS', 'nn', 'dirnum', 'error_list' );
catch
    disp('Error saving flag preferences.');
end

end


% END OF MAIN FUNCTION (trackOptiView)


%% INTERNAL FUNCTIONS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% loaderInternal
%
% Load Date and put in outline fields.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function data = loaderInternal( filename, clist )
data = load( filename );
ss = size( data.phase );

if isfield( data, 'mask_cell' )
    data.outline =  xor(bwmorph( data.mask_cell, 'dilate' ), data.mask_cell);
end


if isempty( clist )
    
else
    clist = gate(clist);
    
    data.cell_outline = false(ss);
    
    %tic
    if isfield( data, 'regs' ) && isfield( data.regs, 'ID' )
        
        ind = find(ismember(data.regs.ID,clist.data(:,1)));
        
        %     for ii = ind
        %         [xx,yy] = getBBpad(data.regs.props(ii).BoundingBox,ss,1);
        %
        %         mask_tmp = data.regs.regs_label(yy,xx)==ii;
        %         data.cell_outline(yy,xx) = or( data.cell_outline(yy,xx), ...
        %             xor(bwmorph( mask_tmp, 'dilate' ),...
        %             mask_tmp));
        %     end
        
        mask_tmp = ismember( data.regs.regs_label, ind );
        
        data.cell_outline = xor(bwmorph( mask_tmp, 'dilate' ), mask_tmp);
        
    end
end
%toc

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% getDirStruct
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [nameInfo] = getDirStruct( dirname )

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
contents = dir( [dirname,filesep,'*.tif'] );

nt  = [];
nc  = [];
nxy = [];
nz  = [];

num_im = numel(contents);

for i = 1:num_im;
    nameInfo = ReadFileName( contents(i).name );
    
    nt  = [nt,  nameInfo.npos(1,1)];
    nc  = [nc,  nameInfo.npos(2,1)];
    nxy = [nxy, nameInfo.npos(3,1)];
    nz  = [nz,  nameInfo.npos(4,1)];
end

nt  = sort(unique(nt));
nc  = sort(unique(nc));
nxy = sort(unique(nxy));
nz  = sort(unique(nz));

xyPadSize = floor(log(max(nxy))/log(10))+1;
padString = ['%0',num2str(xyPadSize),'d'];

num_xy = numel(nxy);
num_c  = numel(nc);
num_z  = numel(nz);
num_t  = numel(nt);


nameInfo.nt  = nt;
nameInfo.nc  = nc;
nameInfo.nxy = nxy;
nameInfo.nz  = nz;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% getPadSize
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function padStr = getPadSize( dirname )

contents = dir([dirname,'*ell*.mat']);

if numel(contents) == 0
    disp('No cell files' );
    padStr = []
else
    num_num = sum(ismember(contents(1).name,'1234567890'));
    padStr = ['%0',num2str(num_num),'d'];
end

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intGetNum
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function ixy = intGetNum( str_xy )
ixy = str2num(str_xy(ismember(str_xy, '0123456789' )));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intLoadData
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [data_r, data_c, data_f] = intLoadData( dirname, ...
    D_FLAG, contents, nn, num_im, nameInfo, clist, ixy)


if (D_FLAG == AD_FLAG) || (D_FLAG == SD_FLAG)
    
    %'start'
    
    if (nn ==1) && (1 == num_im)
        data_r = [];
        data_c = loaderInternal([dirname,contents(nn  ).name], clist);
        data_f = [];
    elseif nn == 1;
        data_r = [];
        data_c = loaderInternal([dirname,contents(nn  ).name], clist);
        data_f = [];
        %data_f = loaderInternal([dirname,contents(nn+1).name], clist);
        %data_ff= loaderInternal([dirname,contents(nn+2).name]);
    elseif nn == num_im
        %data_r = loaderInternal([dirname,contents(nn-1).name], clist);
        data_r = [];
        data_c = loaderInternal([dirname,contents(nn  ).name], clist);
        data_f = [];
        %data_ff= [];
    elseif nn == num_im-1
        %data_r = loaderInternal([dirname,contents(nn-1).name], clist);
        data_r = [];
        data_c = loaderInternal([dirname,contents(nn  ).name], clist);
        data_f = [];
        %data_f = loaderInternal([dirname,contents(nn+1).name], clist);
        %data_ff= [];
    else
        
        if 1
            data_r = loaderInternal([dirname,contents(nn-1).name], clist);
            data_f = loaderInternal([dirname,contents(nn+1).name], clist);
        else
            data_r = [];
            data_f = [];
        end
        data_c = loaderInternal([dirname,contents(nn  ).name], clist);
        %data_ff= loaderInternal([dirname,contents(nn+1).name]);
    end
    
    %'finish'
    
else
    
    data_f = [];
    data_r = [];
    data_c = [];
    
    % it  = nameInfo.npos(1,1);
    % ic  = nameInfo.npos(2,1);
    % ixy = nameInfo.npos(3,1);
    % iz  = nameInfo.npos(4,1);
    
    nameInfo.npos(1,1) = nameInfo.nt(nn);
    nameInfo.npos(3,1) = nameInfo.nxy(ixy);
    nameInfo.npos(2,1) = 1;
    nameInfo.npos(4,1) = 1;
    
    name = [dirname,MakeFileName(nameInfo)];
    
    
    data_c.phase = imread(name);
    for ic = nameInfo.nc(2:end)
        
        nameInfo.npos(2,1) = nameInfo.nc(ic);
        name = [dirname,MakeFileName(nameInfo)];
        
        tmp = imread(name);
        data_c = setfield( data_c, ['fluor',num2str(ic-1)], tmp );
    end
end





end

% Do directory handling
% Sense whether trackOptiView is being launched with an align of seg
% directory.
function val = AD_FLAG()
val = 0;
end
function val = SD_FLAG()
val = 1;
end
function val = ND_FLAG()
val = 2;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intDispError
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function intDispError( data_c, FLAGS )

for kk = 1:data_c.regs.num_regs
    if isfield(data_c,'regs') &&...
            isfield(data_c.regs, 'error') && ...
            isfield(data_c.regs.error,'label') && ...
            ~isempty( data_c.regs.error.label{kk} )
        if FLAGS.v_flag && isfield( data_c.regs, 'ID' )
            disp(  ['Cell: ', num2str(data_c.regs.ID(kk)), ', ', ...
                data_c.regs.error.label{kk}] );
        else
            disp(  [ data_c.regs.error.label{kk}] );
        end
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intSetDefaultFlags
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function FLAGS = intSetDefaultFlags()

FLAGS.v_flag  = 1;
FLAGS.m_flag  = 0;
FLAGS.t_flag  = 0;
FLAGS.T_flag  = 0;
FLAGS.ID_flag = 1;
FLAGS.P_flag  = 1;
FLAGS.e_flag  = 0;
FLAGS.f_flag  = 0;
FLAGS.s_flag  = 1;
FLAGS.p_flag  = 0;
FLAGS.c_flag  = 1;
FLAGS.lyse_flag = false;
FLAGS.err_flag = false;

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intSetDefaultFlags
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function intCons(dirname0, contents_xy, dircons, setHeader, CONST)
%try

ixy = intGetNum( contents_xy.name );
header = ['xy',num2str(ixy),': '];

if exist([dircons, 'consColor_', setHeader, '_', num2str(ixy,'%02d'), '.tif'])
    disp('Consensus Already Calculated')
    imColor = imread([dircons, 'consColor_', setHeader, '_', num2str(ixy,'%02d'), '.tif']);
    figure(1)
    clf
    imshow(imColor);
    disp('Press any key to continue')
    pause
    
else
    
    disp('No Images Found.')
    disp('Calculate New Consensus?')
    d = input('[y/n]:','s');
    
    if strcmp(d,'y')
        
        if isdir([dirname0,contents_xy.name,filesep,'seg_full'])
            dirname = [dirname0,contents_xy.name,filesep,'seg_full',filesep];
        end
        
        dirname_cell = [dirname0,contents_xy.name,filesep,'cell',filesep];
        
        disp( ['Doing ',num2str(ixy)] );
        
        %makeFrameStripeMosaicCenter( [dirname_cell], CONST, ll_ );
        %[imTot, imColor, imBW, imInv, kymo, kymoMask, I ] = ...
        %    makeFrameStripeMosaicCenterMag( [dirname_cell], CONST, [], 0, 0 );
        %[imTot, imColor, imBW, imInv, kymo, kymoMask, I ] = ...
        %    makeFrameStripeMosaicCenter2( [dirname_cell], CONST, ll_ );
        [imTot, imColor, imBW, imInv, kymo, kymoMask, I, jjunk, jjunk, imTot10 ] = ...
            makeConsIm( [dirname_cell], CONST, [], [], false );
        
        figure(1)
        clf
        imshow(imColor)
        
        disp('Press any key to continue')
        pause
        
        if ~isempty( imTot )
            imwrite( imBW,    [dircons, 'consBW_',    setHeader, '_', num2str(ixy,'%02d'), '.tif'], 'tif' );
            imwrite( imColor, [dircons, 'consColor_', setHeader, '_', num2str(ixy,'%02d'), '.tif'], 'tif' );
            imwrite( imInv,   [dircons, 'consInv_',   setHeader, '_', num2str(ixy,'%02d'), '.tif'], 'tif' );
            imwrite( imTot10,   [dircons, 'typical_',   setHeader, '_', num2str(ixy,'%02d'), '.tif'], 'tif' );
            
            %figure(99);
            %print( '-depsc', [dircons, 'dyn', num2str(ixy,'%02d'), '.eps'] );
            
            save( [dircons, 'fits', num2str(ixy,'%02d'), '.mat'], 'I' );
        else
            
            disp( ['Found no cells in ', dirname_cell, '.'] );
        end
        
    else
        
        return
        
    end
    %catch
    %disp( ['Error ',num2str(ixy)] );
    
end
end
