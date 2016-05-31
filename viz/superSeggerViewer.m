function superSeggerViewer(dirname)
% superSeggerViewer : interactive visulization of the segmented data.
% It displays a menu from which the user can make choices and vizualize or
% analyze the segmented data.
%
% important notes :
% - it saves a file in the directory named .trackOptiView.mat where it
% saves the flags from the previous launch
% - it uses the clist which can be gated to only show cells that pass specific
% criteria. it outlines and analyzes only cells that pass the gate, to display
% the full dataset the gate needs to be deleted.
%
%
%
% INPUT :
%       dirname : main directory that contains files segemented by supeSegger
%       it must be the directory that has raw_im and xy1 etc folders.
%       It can be run from the seg file directly but some functions that require
%       cell files will not work.
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

%% Load Constants and Initialize Flags

global canUseErr;
hf = figure(1);
clf;
mov = struct;
CONST = [];
touch_list = [];
setHeader =[];

% Add slash to the file name if it doesn't exist
if(nargin<1 || isempty(dirname))
    dirname=uigetdir();
end

dirname = fixDir(dirname);
dirname0 = dirname;

% load flags if they already exist to maintain state between launches
filename_flags = [dirname0,'.superSeggerViewer.mat'];
FLAGS = [];
if exist( filename_flags, 'file' )
    load(filename_flags);
    FLAGS = fixFlags(FLAGS);
else
    FLAGS = fixFlags(FLAGS);
    error_list = [];
    nn = 1;
    dirnum = 1;
end

% Load info from one of the xy directories. dirnum tells you which one. If
% you quit the program in an xy dir, it goes to that xy dir.
clist = [];
contents_xy =dir([dirname, 'xy*']);
num_xy = numel(contents_xy);
direct_contents = dir([dirname, '*seg.mat']);


if num_xy~=0
    if isdir([dirname0,contents_xy(dirnum).name,filesep,'seg_full'])
        dirname_seg = [dirname0,contents_xy(dirnum).name,filesep,'seg_full',filesep];
    else
        dirname_seg = [dirname0,contents_xy(dirnum).name,filesep,'seg',filesep];
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
else
    if numel(direct_contents) == 0
        disp('There are no xy dirs. Choose a different directory.');
        return;
    else % loading from the seg directory directly
        dirname_cell = dirname;
        dirname_xy = dirname;
        dirname_seg = dirname;
        ixy = 1;
        header = ['seg',num2str(ixy),': '];
    end
end

if exist([dirname0,'CONST.mat'],'file')
    CONST = load([dirname0,'CONST.mat']);
    if isfield( CONST, 'CONST' )
        CONST = CONST.CONST;
    end
else
    disp(['Exiting. There is a CONST.mat file at the root', ...
        'level of the data directory. Loading default 60XEcLB']);
    CONST = loadConstants(60,0);
end

contents=dir([dirname_seg, '*seg.mat']);
num_im = length(contents);

if (num_im == 0)
    error('No files found in the seg directory');
end

% for calculations that take time like the consensus array
% you can save the array in a folder so that it is loaded from there
% instead of calculated repeatedly.
dirSave = [dirname,'superSeggerViewer',filesep];
if ~exist(dirSave,'dir')
    mkdir(dirSave);
else
    if exist([dirSave,'dataImArray.mat'],'file')
        load ([dirSave,'dataImArray'],'dataImArray');
    end
end

runFlag = (nn<=num_im);

% This flag controls whether you reload from file
first_flag = true;
resetFlag = true;
FLAGS.e_flag = 0 ;

%% Run the main loop... and run it while the runFlag is true.
while runFlag
    figure(1);
    
    contents=dir([dirname_seg, '*seg.mat']);
    num_segs = length(contents);
    
    contents=dir([dirname_seg, '*err.mat']);
    num_errs = length(contents);
    
    num_im = max(num_segs, num_errs);
    
    %Use region IDs if cells IDs unavailable
    if nn > num_errs || FLAGS.useSegs
        canUseErr = 0;
        contents=dir([dirname_seg, '*seg.mat']);
    else
        canUseErr = 1;
        contents=dir([dirname_seg, '*err.mat']);
    end
    
    % load current frame
    if resetFlag
        resetFlag = false;
        [data_r, data_c, data_f] = intLoadDataViewer( dirname_seg, ...
            contents, nn, num_im, clist, FLAGS);
    end
    
    clean_axis = [0 , 1 , 0  ,1];
    
    if ~first_flag && all(axis~=clean_axis)
        tmp_axis = axis;
    else % if first time - load image to get the axis
        clf;
        imshow(data_c.phase);
        tmp_axis = axis;
        first_flag = false;
    end
    
    %Force flags to required values when data is unavailable
    forcedFlags = FLAGS;
    forcedFlags.cell_flag = forcedFlags.cell_flag & shouldUseErrorFiles(FLAGS);
    %Force cell flag to 0 when err files not present
    
    showSeggerImage( data_c, data_r, data_f, forcedFlags, clist, CONST, []);
    flagsStates = intSetStateStrings(FLAGS,CONST);
    
    axis(tmp_axis);
    
    
    % Main Menu
    disp('------------------------------SuperSegger Data Viewer-------------------------------------');
    disp('-------------------------------------Main Menu--------------------------------------------');
    disp(['q  : To quit                                  reset : Reset axis to default   ']);
    disp(['x# : Switch xy directory from ', num2str(ixy), '               #  : Go to Frame Number #']);
    disp('----------------------------------Display Options-----------------------------------------');
    disp(['    Region info: ', num2str(num_segs), ' frames.   Cell info: ', num2str(num_errs), ' frames.   Current frame: ', num2str(nn)]);
    if ~FLAGS.cell_flag
        fprintf(2, 'Displaying region data.\n');
    end
    if FLAGS.useSegs
        fprintf(2, 'Using seg files. Displaying region IDs instead of cell IDs.\n');
    elseif ~canUseErr
        fprintf(2, 'No cell info for this frame. Displaying region IDs instead.\n');
    end
    disp(' ');
    disp(['id  : Show/Hide Cell Numbers ', [flagsStates.idState],'            seg : Use seg files ', flagsStates.useSegs]);
    disp(['r  : Show/Hide Region Outlines ', [flagsStates.rState],'          rs  : Show/Hide Region scores ', [flagsStates.regionScores]]);
    disp(['p  : Show/Hide Cell Poles ', flagsStates.pState,'               outline  : Outline cells ', flagsStates.vState]);
    disp(['f#  : Change channel ', [flagsStates.fState],'                  s  : Show Fluor Foci Scores ', [flagsStates.sState]]);
    disp(['filter : Filtered fluorescence ',flagsStates.filtState,'          CC : Use Complete Cell Cycles ', flagsStates.CCState] );
    disp(['falseCol : False Color ', flagsStates.falseColState,'                  log : Log View ', flagsStates.logState ]);
    disp(['find# : Find Cell Number #']);
    disp('-------------------------------------Link Options-----------------------------------------');
    if ~canUseErr || FLAGS.useSegs
        fprintf(2, 'Cell information must be availble to use this feature.\n');
    end
    if ~canUseErr
        fprintf(2, 'Please complete the linking phase of superSegger\n');
    end
    if FLAGS.useSegs
        fprintf(2, 'Please enable use of err files (seg command)\n');
    end
    disp(['link  : Show Linking Information               mother : Show mothers ', flagsStates.showMothers]);
    disp(['daughter  : Show daughters ', flagsStates.showDaughters]);
    disp('-----------------------------------Output Options-----------------------------------------');
    disp(['con  : Show Consensus                         cKym : Show consensus kymograph']);
    disp(['kymAll : Mosaic Kymograph of all cells        kym# : Show Kymograph for Cell #']);
    disp(['twrAll : Towers of all cells                  twr# : Tower for Cell #']);
    disp(['movie : Movie of this xy position             movie#  : Movie of # cell']);
    disp(['save : Save Figure #']);
    disp('-------------------------------------Gate Options-----------------------------------------');
    if ~isempty(clist)
        disp(['    Clist: ', [dirname0,contents_xy(dirnum).name,filesep,'clist.mat']]);
    else
        fprintf(2, 'No clist loaded, these commands will not work.\n');
    end
    disp(' ');
    disp(['g  : Make Gate                                G  : Create xy-combined clist, gated.']);
    disp(['moveG  : Move gated cells                     clear : Clear all Gates ']);
    disp(['hist : Histogram of clist quantity            hist2 : Plotting two clist quantities ']);
    disp('-------------------------------------Debug Options----------------------------------------');
    disp('k : Enter debugging mode');
    disp('------------------------------------------------------------------------------------------');
    disp(' ');
    if FLAGS.e_flag
        intDispError( data_c, FLAGS );
    end
    if ~isempty( touch_list );
        disp('Warning! Frames touched. Run re-link.');
        touch_list;
    end
    
    disp([header, 'Frame num [1...',num2str(num_im),']: ',num2str(nn)]);
    
    %pause;
    c = input(':','s');
    
    % LIST OF COMMANDS
    if isempty(c)
        % do nothing
        
    elseif strcmpi (c,'falseCol') % false color view
        if ~isfield( CONST,'view') || ...
                ~isfield( CONST.view,'falseColorFlag')|| isempty( CONST.view.falseColorFlag )
            CONST.view.falseColorFlag = true;
        else
            CONST.view.falseColorFlag = ~CONST.view.falseColorFlag;
        end
        
    elseif  strcmpi(c,'log') % log view
        if ~isfield( CONST, 'view' ) || ~isfield( CONST.view, 'LogView' ) || ...
                isempty( CONST.view.LogView )
            CONST.view.LogView = true;
        else
            CONST.view.LogView = ~CONST.view.LogView;
        end
        
    elseif strcmpi(c,'q') % Quit Command
        if exist('clist','var') && ~isempty(clist)
            save( [dirname0,contents_xy(dirnum).name,filesep,'clist.mat'],'-STRUCT','clist');
        else
            disp('Error saving clist file.');
        end
        runFlag = 0  ;
        
    elseif strcmpi(c,'CC') % Toggle Between Full Cell Cycles
        CONST.view.showFullCellCycleOnly = ~CONST.view.showFullCellCycleOnly ;
        
        if CONST.view.showFullCellCycleOnly
            figure(2);
            clist = gateMake( clist, 9, [1.1 inf] ); % stat0 above 1
            close(2);
            disp('Only showing complete Cell Cycles')
            resetFlag = 1;
        else
            figure(2);
            clist = gateStrip ( clist, 9 ); % clear stat0 gate
            close(2);
            disp('Showing incomplete Cell Cycles')
            resetFlag = 1;
        end
    elseif strcmpi(c,'hist') % choose characteristics and values to gate cells
        disp('Choose histogram characteristic')
        disp(clist.def')
        cc = str2double(input('Characteristic [ ] :','s')) ;
        figure(2);
        clf;
        gateHist(clist,cc);
        
    elseif strcmpi(c,'hist2') % choose characteristics and values to gate cells
        disp('Choose histogram characteristic')
        cc1 = str2double(input('Characteristic 1 [ ] :','s')) ;
        cc2 = str2double(input('Characteristic 2 [ ] :','s')) ;
        figure(2);
        clf;
        gateHistDot(clist, [cc1 cc2]);
        
    elseif strcmpi(c,'save') % choose characteristics and values to gate cells
        figNum = str2double(input('Figure number :','s')) ;
        filename = input('Filename :','s') ;
        savename = sprintf('%s/%s',dirSave,filename);
        saveas(figNum,(savename),'fig');
        print(figNum,'-depsc',[(savename),'.eps'])
        saveas(figNum,(savename),'png');
        disp (['Figure ', num2str(figNum) ,' is saved in eps, fig and png format at ',savename]);
        
    elseif numel(c) >= 4 && strcmpi(c(1:4), 'find') % Find Single Cells as F(number), an X appears on the iamge wehre the cell is
        if numel(c) > 4
            find_num = floor(str2double(c(5:end)));
            if FLAGS.cell_flag && shouldUseErrorFiles(FLAGS)
                regnum = find( data_c.regs.ID == find_num);
                
                if ~isempty( regnum )
                    plot(data_c.regs.props(regnum).Centroid(1),...
                        data_c.regs.props(regnum).Centroid(2), ...
                        'yx','MarkerSize',50);
                else
                    disp('couldn''t find that cell');
                end
            else
                if (find_num <= data_c.regs.num_regs) && (find_num >0)
                    plot(data_c.regs.props(find_num).Centroid(1),...
                        data_c.regs.props(find_num).Centroid(2), ...
                        'yx','MarkerSize',50);
                else
                    disp( 'Out of range' );
                end
            end
            input('Press any key','s');
        else
            disp ('Please provide cell number');
        end
        
    elseif strcmpi(c(1),'x')   % Change xy positions
        
        if numel(c)>1
            c = c(2:end);
            ll_ = floor(str2num(c));
            
            if ~isempty(ll_) && (ll_>=1) && (ll_<=num_xy)
                try
                    save( [dirname0,contents_xy(dirnum).name,filesep,'clist.mat'],'-STRUCT','clist');
                catch ME
                    printError(ME);
                    disp( 'Error writing clist file.');
                end
                
                dirnum = ll_;
                dirname_seg = [dirname0,contents_xy(ll_).name,filesep,'seg',filesep];
                dirname_cell = [dirname0,contents_xy(ll_).name,filesep,'cell',filesep];
                dirname_xy = [dirname0,contents_xy(ll_).name,filesep];
                ixy = intGetNum( contents_xy(dirnum).name );
                header = ['xy',num2str(ixy),': '];
                contents=dir([dirname_seg, '*seg.mat']);
                error_list = [];
                clist = load([dirname0,contents_xy(ll_).name,filesep,'clist.mat']);
                resetFlag = true;
            else
                disp ('Incorrect number for xy position');
            end
            
        else
            disp ('Number of xy position missing');
            
        end
        
    elseif strcmpi(c,'r')  % Show/Hide Region Outlines
        FLAGS.P_flag = ~FLAGS.P_flag;
        FLAGS.Outline_flag = 0;
        
    elseif strcmpi(c,'outline') % Show/Hide Region Outlines
        FLAGS.Outline_flag = ~FLAGS.Outline_flag;
        
    elseif strcmpi(c,'reset') % Reset axis to default
        first_flag = true;
        resetFlag = 1;
        
    elseif numel(c) == 2 && c(1) == 'f' && isnum(c(2)) % Toggle Between Fluorescence and Phase Images
        disp('toggling between phase and fluorescence');
        f = 0;
        while true
            if isfield(data_c, ['fluor' num2str(f+1)] )
                f = f+1;
            else
                break
            end
        end
        c = round(str2double(c(2)));
        if isnan(c) || c < 0 || c > f
            FLAGS.f_flag = 0;
        else
            FLAGS.f_flag = c;
        end
        
    elseif strcmpi(c, 'filter') % Toggle Between filtered and unfiltered
        disp('filtering');
        FLAGS.filt = ~ FLAGS.filt;
        
    elseif strcmpi(c,'g') % choose characteristics and values to gate cells
        disp('Choose gating characteristic')
        disp(clist.def')
        cc = input('Gate Number(s) [ ] :','s') ;
        figure(2)
        clist = gateMake(clist,str2num(cc)) ;
        resetFlag = 1;
        
    elseif strcmpi(c,'Clear')  % Clear All Gates
        tmp_axis = axis;
        clist.gate = [] ;
        clf;
        resetFlag = 1;
        axis( tmp_axis );
        
    elseif strcmpi(c,'MoveG')   % moves gated cell files to a different directory
        header = 'trackOptiView: ';
        trackOptiGateCellFiles( dirname_cell, clist);
        
    elseif strcmpi(c, 'Gtot')
        % creates a clist for all xy positions, gated from loaded clist.
        if ~isfield( clist, 'gate' )
            clist.gate = [];
        end
        
        for ll_ = 1:num_xy
            filename = [dirname0,contents_xy(ll_).name,filesep,'clist.mat'];
            clist_tmp = gate(load(filename ));
            if  ll_ == 1
                clist_comp =clist_tmp;
            else
                clist_comp.data = [clist_comp.data; clist_tmp.data];
            end
        end
        
        save( [dirname0,'clist_comp.mat'], '-STRUCT', 'clist_comp' );
        
        
    elseif strcmpi(c,'id') % Show Cell Numbers
        FLAGS.ID_flag = ~FLAGS.ID_flag;
        if FLAGS.ID_flag
            FLAGS.regionScores = 0;
        end
        
    elseif strcmpi(c,'s') % Show Fluorescent Foci score values
        FLAGS.s_flag = ~FLAGS.s_flag;
        
    elseif numel(c) > 1 && c(1) == 's' && all(isnum(c(2:end))) % Toggle Between Fluorescence and Phase Images
        disp(['showing foci with scores higher than  ', c(2:end)]);
        FLAGS.s_flag = 1;
        CONST.getLocusTracks.FLUOR1_MIN_SCORE = str2double(c(2:end));
        
    elseif strcmpi(c,'p')  % Show Cell Poles
        FLAGS.p_flag = ~FLAGS.p_flag;
        
    elseif strcmpi(c,'k') % Enter Debugging Mode
        tmp_axis = axis;
        disp('Press "continue" on the editor tab to exit debugging mode')
        keyboard
        clf;
        axis( tmp_axis );
        
    elseif strcmpi(c,'KymAll') % Make Kymograph Mosaic for All Cells
        tmp_axis = axis;
        clf;
        makeKymoMosaic( dirname_cell, CONST );
        disp('press enter to continue.');
        pause;
        axis(tmp_axis);
        
    elseif strcmpi(c,'twrAll') %  Show Cell Towers for All Cells
        tmp_axis = axis;
        clf;
        
        if numel(c) > 1
            ll_ = floor(str2num(c(2:end)));
        else
            ll_ = [];
        end
        
        makeFrameStripeMosaic([dirname_cell], CONST, ll_,true );
        axis equal
        
        disp('press enter to continue.');
        pause;
        axis(tmp_axis);
        
    elseif strcmpi(c,'con') % Show existant consensus for this XY or calculate new one
        % it uses the current clist if datImArray has not been recalculated
        % before
        skip = 5;
        mag = 4;
        fnum = 1;
        alreadyExistsImArray = exist('dataImArray','var') && ~isempty(dataImArray);
        if alreadyExistsImArray
            answer = input(' dataImArray already calculated - recalculate? [y/n]:','s');
        end
        
        if ~alreadyExistsImArray || strcmpi(answer,'y')
            [dataImArray] = makeConsensusArray( dirname_cell, CONST, skip,mag,fnum);
            save ([dirSave,'dataImArray'],'dataImArray');
        end
        
        [imMosaic, imColor, imBW, imInv, imMosaic10 ] = makeConsensusImage( dataImArray,CONST,skip,mag,0);
        figure(2)
        clf
        imshow(imColor)
        disp('press enter to continue.');
        pause;
        
    elseif strcmpi(c,'cKym') % Show existant consensus for this XY or calculate new one
        skip = 5;
        mag = 4;
        fnum = 1;
        alreadyExistsImArray = exist('dataImArray','var') && ~isempty(dataImArray);
        if alreadyExistsImArray
            answer = input(' dataImArray already calculated - recalculate? [y/n]:','s');
        end
        
        if ~alreadyExistsImArray || strcmpi(answer,'y')
            [dataImArray] = makeConsensusArray( dirname_cell, CONST, skip,mag,fnum);
            save ([dirSave,'dataImArray'],'dataImArray');
        end
        
        
        [kymo,kymoMask] = makeConsensusKymo(dataImArray.imCellNorm, dataImArray.maskCell , 1);
        disp('press enter to continue.');
        pause;
    elseif numel(c)>2 && strcmpi(c(1:3),'twr') % Cell Tower for Single Cell
        
        if numel(c) > 3
            comma_pos = findstr(c,',');
            
            if isempty(comma_pos)
                ll_ = floor(str2num(c(4:end)));
                xdim__ = [];
            else
                ll_ = floor(str2num(c(4:comma_pos(1))));
                xdim__ = floor(str2num(c(comma_pos(1):end)));
            end
            
            padStr = getPadSize( dirname_cell, [] );
            
            if ~isempty( padStr )
                data_cell = [];
                filename_cell_C = [dirname_cell,'Cell',num2str(ll_,padStr),'.mat'];
                filename_cell_c = [dirname_cell,'cell',num2str(ll_,padStr),'.mat'];
                
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
                    catch ME
                        printError(ME);
                        disp(['Error loading: ', filename_cell] );
                    end
                    
                    if ~isempty( data_cell )
                        figure(2);
                        clf;
                        im_tmp = makeFrameMosaic(data_cell, CONST, xdim__);
                    end
                    
                end
            end
        else
            disp ('Please enter a number next to twr');
        end
        
    elseif numel(c)>2 && strcmpi(c(1:3),'kym') % Show Kymograph for Single Cell
        
        if numel(c) > 3
            num = floor(str2num(c(4:end)));
            data_cell = loadCellData(num,dirname_cell, []);
            
            if ~isempty( data_cell )
                figure(2);
                clf;
                makeKymographC(data_cell, 1, CONST,[],FLAGS.filt);
                ylabel('Long Axis (pixels)');
                xlabel('Time (frames)' );
                disp('Press enter to continue');
            end
        else
            disp ('Please enter a number next to kym');
        end
        
    elseif numel(c)>5 && strcmpi(c(1:5),'movie') % movie for single Cell
        if numel(c) > 5
            num = floor(str2double(c(6:end)));
            [data_cell,cell_name] = loadCellData(num,dirname_cell, []);
            if ~isempty(data_cell)
                mov = makeCellMovie(data_cell);
                disp('Save movie?')
                d = input('[y/n]:','s');
                if strcmpi(d,'y')
                    saveFilename = [dirSave,cell_name(1:end-4),'.avi'];
                    disp (['Saving movie at ',saveFilename]);
                    v = VideoWriter(saveFilename);
                    open(v)
                    writeVideo(v,mov)
                    close(v)
                end
            end
        end
        
    elseif strcmpi(c,'movie')  % Make Time-Lapse Images for Movies
        
        tmp_axis = axis;
        
        clear mov;
        mov.cdata = [];
        mov.colormap = [];
        
        for ii = 1:num_im
            [data_r, data_c, data_f] = intLoadDataViewer( dirname_seg, ...
                contents, ii, num_im, clist, FLAGS);
            tmp_im =  showSeggerImage( data_c, data_r, data_f, FLAGS, clist, CONST, []);
            axis(tmp_axis);
            drawnow;
            mov(ii) = getframe;
            disp( ['Frame number: ', num2str(ii)] );
        end
        
        
        disp('Save movie?')
        d = input('[y/n]:','s');
        if strcmpi(d,'y')
            name = input('filename:','s');
            saveFilename = [dirSave,name,'.avi'];
            disp (['Saving movie at ',saveFilename]);
            v = VideoWriter(saveFilename);
            v.FrameRate = 2; % frames per second
            open(v)
            writeVideo(v,mov)
            close(v)
        end
        
        resetFlag = true;
        
    elseif strcmpi(c,'e')
        % Show Error List
        FLAGS.e_flag = ~FLAGS.e_flag;
        
    elseif strcmpi(c,'rs') % Toggle display of region scores
        FLAGS.regionScores = ~FLAGS.regionScores;
        if FLAGS.regionScores
            FLAGS.ID_flag = 0;
        end
        
    elseif strcmpi(c,'seg') % Toggle display of region scores
        FLAGS.useSegs = ~FLAGS.useSegs;
        resetFlag = true;
        
        %% DEVELOPER FUNCTIONS : Use at your own risk
    elseif strcmpi(c,'link')  % Show links
        FLAGS.showLinks = ~FLAGS.showLinks;
        resetFlag = true;
        
    elseif strcmpi(c,'mother')  % Show links
        FLAGS.showMothers = ~FLAGS.showMothers;
        
    elseif strcmpi(c,'daughter')  % Show links
        FLAGS.showDaughters = ~FLAGS.showDaughters;
        
    elseif strcmpi(c,'editSegs')  % Edit Segments, allows to turn on and off segments
        disp('Are you sure you want to edit the segments?')
        d = input('[y/n]:','s');
        if strcmpi(d,'y')
            segsTLEdit(dirname_seg, nn, CONST);
        end
        
    elseif strcmpi(c, 'relink') % Re-Link - relinks the cells after modifications in segments
        disp('Are you sure you want to relink and remake the cell files?')
        d = input('[y/n]:','s');
        if strcmpi(d,'y')
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
        end
    else % we assume that it is a number for a frame change.
        tmp_nn = str2num(c);
        if ~isempty(tmp_nn)
            nn = tmp_nn;
            if nn > num_im;
                nn = num_im;
            elseif nn< 1
                nn = 1;
            end
            resetFlag = true;
        else % not a number - command not found
            disp ('Command not found');
        end
    end
end

try
    save(filename_flags, 'FLAGS', 'nn', 'dirnum', 'error_list' );
catch
    disp('Error saving flag preferences.');
end

end


% END OF MAIN FUNCTION (superSeggerViewer)

% INTERNAL FUNCTIONS
function [nameInfo] = getDirStruct( dirname )

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

function ixy = intGetNum( str_xy )
ixy = str2num(str_xy(ismember(str_xy, '0123456789' )));
end

function intDispError( data_c, FLAGS )
% intDispError
for kk = 1:data_c.regs.num_regs
    if isfield(data_c,'regs') &&...
            isfield(data_c.regs, 'error') && ...
            isfield(data_c.regs.error,'label') && ...
            ~isempty( data_c.regs.error.label{kk} )
        if FLAGS.cell_flag && shouldUseErrorFiles(FLAGS) && isfield( data_c.regs, 'ID' )
            disp(  ['Cell: ', num2str(data_c.regs.ID(kk)), ', ', ...
                data_c.regs.error.label{kk}] );
        else
            disp(  [ data_c.regs.error.label{kk}] );
        end
    end
end
end


function flagsStates = intSetStateStrings(FLAGS,CONST)
% intSetStateStrings : sets default flags for when the program begins
flagsStates.vState = '(on) ';
flagsStates.mState = '(on) ';
flagsStates.idState = '(on) ';
flagsStates.TState = '(on) ';
flagsStates.PState ='(on) ';
flagsStates.pState ='(off) ';
flagsStates.rState = '(on) ';
flagsStates.eState = '(on) ';
flagsStates.fState = '(Fluor)';
flagsStates.CCState ='(on) ';
flagsStates.PValState = '';
flagsStates.lyseState = '';
flagsStates.sState = '(on) ';

if ~FLAGS.cell_flag
    flagsStates.vState = '(off)';
end

if ~FLAGS.Outline_flag
    flagsStates.vState = '(off)';
end

if ~FLAGS.m_flag
    flagsStates.mState = '(off)';
end

if ~FLAGS.ID_flag
    flagsStates.idState = '(off)';
end

if ~FLAGS.T_flag
    flagsStates.TState = '(off)';
end

if ~FLAGS.P_flag % regions
    flagsStates.rState = '(off)';
end
if ~FLAGS.e_flag
    flagsStates.eState = '(off)';
end

if ~FLAGS.f_flag
    flagsStates.fState = '(Phase)';
end

if ~FLAGS.s_flag
    flagsStates.sState = '(off)';
end
if ~FLAGS.p_flag
    flagsStates.pState = '(off)';
end
if ~CONST.view.showFullCellCycleOnly
    flagsStates.CCState= '(off)';
end
if ~FLAGS.lyse_flag
    flagsStates.lyseState = '(off)';
end
flagsStates.falseColState = '(on) ';
if ~CONST.view.falseColorFlag
    flagsStates.falseColState= '(off)';
end

flagsStates.logState = '(on) ';
if ~CONST.view.LogView
    flagsStates.logState = '(off)';
end

flagsStates.filtState = '(on) ';
if ~FLAGS.filt
    flagsStates.filtState = '(off)';
end

flagsStates.regionScores = '(on) ';
if ~FLAGS.regionScores
    flagsStates.regionScores = '(off)';
end

flagsStates.useSegs = '(on) ';
if ~FLAGS.useSegs
    flagsStates.useSegs = '(off)';
end


flagsStates.showLinks = '(on) ';
if ~FLAGS.showLinks
    flagsStates.showLinks = '(off)';
end

flagsStates.showDaughters = '(on) ';
if ~FLAGS.showDaughters
    flagsStates.showDaughters = '(off)';
end

flagsStates.showMothers = '(on) ';
if ~FLAGS.showMothers
    flagsStates.showMothers = '(off)';
end

end


function intCons(dirname0, contents_xy, setHeader, CONST)
xyDir = [dirname0,contents_xy.name,filesep];
dircons = [xyDir,'/consensus/']

if ~exist(dircons,'dir')
    mkdir(dircons);
end

ixy = intGetNum( contents_xy.name );
header = ['xy',num2str(ixy),': '];

if exist([dircons, 'consColor_', setHeader, '_', num2str(ixy,'%02d'), '.tif'],'file')
    disp('Consensus Already Calculated')
    imColor = imread([dircons, 'consColor_', setHeader, '_', num2str(ixy,'%02d'), '.tif']);
    figure(1)
    clf
    imshow(imColor);
    disp('Press any key to continue')
    pause;
else
    
    disp('No Images Found.')
    disp('Calculate New Consensus?')
    d = input('[y/n]:','s');
    
    if strcmpi(d,'y')
        if isdir([dirname0,contents_xy.name,filesep,'seg_full'])
            dirname = [dirname0,contents_xy.name,filesep,'seg_full',filesep];
        end
        
        dirname_cell = [dirname0,contents_xy.name,filesep,'cell',filesep];
        disp( ['Doing ',num2str(ixy)] );
        skip = 1;
        mag = 4;
        [dataImArray] = makeConsensusArray( [dirname_cell], CONST, skip, mag, [] );
        [imMosaic, imColor, imBW, imInv, imMosaic10 ] = makeConsensusImage( dataImArray,CONST,skip,mag,0);
        
        figure(1)
        clf
        imshow(imColor)
        
        if ~isempty( imMosaic10 )
            disp('Save consensus images?')
            d = input('[y/n]:','s');
            % this just saves the consensus images.
            if strcmpi(d,'y')
                save([dircons,'consensus'],'imMosaic', 'imColor', 'imBW', 'imInv', 'imMosaic10');
                imwrite( imBW,    [dircons, 'consBW_',    setHeader, '_', num2str(ixy,'%02d'), '.tif'], 'tif' );
                imwrite( imColor, [dircons, 'consColor_', setHeader, '_', num2str(ixy,'%02d'), '.tif'], 'tif' );
                imwrite( imInv,   [dircons, 'consInv_',   setHeader, '_', num2str(ixy,'%02d'), '.tif'], 'tif' );
                imwrite( imMosaic10,   [dircons, 'typical_',   setHeader, '_', num2str(ixy,'%02d'), '.tif'], 'tif' );
            end
        else
            disp( ['Found no cells in ', dirname_cell, '.'] );
        end
        
    else
        
        return
        
    end
end
end
