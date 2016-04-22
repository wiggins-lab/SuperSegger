function varargout = viewer(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @viewer_OpeningFcn, ...
    'gui_OutputFcn',  @viewer_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

function show_cell_no_Callback(hObject, eventdata, handles)
updateImage(hObject, handles)

function show_cell_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cell_numbers_Callback(hObject, eventdata, handles)
updateImage(hObject, handles)

function cell_poles_Callback(hObject, eventdata, handles)
updateImage(hObject, handles)

function complete_cell_cycles_Callback(hObject, eventdata, handles)
updateImage(hObject, handles)

function directory_Callback(hObject, eventdata, handles)
initImage(hObject, handles);

function directory_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function false_color_Callback(hObject, eventdata, handles)
updateImage(hObject, handles)

function filtered_fluorescence_Callback(hObject, eventdata, handles)
updateImage(hObject, handles)

function FLAGS = fixFlags(FLAGS)
if ~isfield(FLAGS,'cell_flag')
    FLAGS.cell_flag  = 1;
end
if ~isfield(FLAGS,'m_flag')
    FLAGS.m_flag  = 0;
end
if ~isfield(FLAGS,'ID_flag')
    FLAGS.ID_flag  = 0;
end
if ~isfield(FLAGS,'T_flag')
    FLAGS.T_flag  = 0;
end
if ~isfield(FLAGS,'P_flag')
    FLAGS.P_flag  = 0;
end
if ~isfield(FLAGS,'Outline_flag')
    FLAGS.Outline_flag  = 1;
end
if ~isfield(FLAGS,'e_flag')
    FLAGS.e_flag  = 0;
end
if ~isfield(FLAGS,'f_flag')
    FLAGS.f_flag  = 0;
end
if ~isfield(FLAGS,'p_flag')
    FLAGS.p_flag  = 0;
end
if ~isfield(FLAGS,'s_flag')
    FLAGS.s_flag  = 1;
end
if ~isfield(FLAGS,'c_flag')
    FLAGS.c_flag  = 1;
end
if ~isfield(FLAGS,'P_val')
    FLAGS.P_val  = 0.2;
end
if ~isfield(FLAGS,'filt')
    FLAGS.filt  = 1;
end
if ~isfield(FLAGS,'lyse_flag')
    FLAGS.lyse_flag  = 0;
end
if ~isfield(FLAGS,'regionScores')
    FLAGS.regionScores  = 1;
end

function fluor_foci_scores_Callback(hObject, eventdata, handles)
updateImage(hObject, handles)

function show_frame_no_Callback(hObject, eventdata, handles)
updateImage(hObject, handles)

function show_frame_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function imageFolder_ClickedCallback(hObject, eventdata, handles)
handles.directory.String = uigetdir;
initImage(hObject, handles);

function [data_r, data_c, data_f] = intLoadData(dirname, contents, nn, num_im, clist)
if (nn ==1) && (1 == num_im) % 1 frame only
    data_r = [];
    data_c = loaderInternal([dirname,contents(nn).name], clist);
    data_f = [];
elseif nn == 1;  % first frame
    data_r = [];
    data_c = loaderInternal([dirname,contents(nn).name], clist);
    data_f = [];
elseif nn == num_im || nn == num_im-1 % last or before last frame
    data_r = [];
    data_c = loaderInternal([dirname,contents(nn).name], clist);
    data_f = [];
else
    data_r = loaderInternal([dirname,contents(nn-1).name], clist);
    data_f = loaderInternal([dirname,contents(nn+1).name], clist);
    data_c = loaderInternal([dirname,contents(nn).name], clist);
end

function data = loaderInternal(filename, clist)
data = load(filename);
ss = size(data.phase);
if isfield(data, 'mask_cell')
    data.outline = xor(bwmorph(data.mask_cell, 'dilate'), data.mask_cell);
end
if isempty(clist)
    disp ('Clist is empty, can not load any files');
else
    clist = gate(clist);
    data.cell_outline = false(ss);
    if isfield(data, 'regs') && isfield( data.regs, 'ID')
        ind = find(ismember(data.regs.ID, clist.data(:,1))); % get ids of cells in clist
        mask_tmp = ismember(data.regs.regs_label, ind); % get the masks of cells in clist
        data.cell_outline = xor(bwmorph(mask_tmp, 'dilate'), mask_tmp);
    end
end

function log_view_Callback(hObject, eventdata, handles)
updateImage(hObject, handles)

function outline_cells_Callback(hObject, eventdata, handles)
updateImage(hObject, handles)

function region_outlines_Callback(hObject, eventdata, handles)
updateImage(hObject, handles)

function initImage(hObject, handles)
dirname = handles.directory.String;
file_filter = '';
CONST = [];
if nargin<2 || isempty(file_filter);
    if numel(dir([dirname,filesep,'xy1',filesep,'seg',filesep,'*err.mat']))~=0
        file_filter = '*err.mat';
    else
        file_filter = '*seg.mat';
    end
end
if(nargin<1 || isempty(dirname)) % Add slash to the file name if it doesn't exist
    dirname = uigetdir();
end
dirname = fixDir(dirname);
dirname0 = dirname;
dirSave = [dirname, 'trackOptiView', filesep];
if ~exist(dirSave, 'dir')
    mkdir(dirSave);
else
    if exist([dirSave, 'dataImArray.mat'], 'file')
        load([dirSave, 'dataImArray'], 'dataImArray');
    end
end
filename_flags = [dirname0,'.trackOptiView.mat']; % load flags if they already exist to maintain state between launches
FLAGS = [];
if exist( filename_flags, 'file' )
    load(filename_flags);
    FLAGS = fixFlags(FLAGS);
else
    FLAGS = fixFlags(FLAGS);
    nn = 1;
    dirnum = 1;
end
if strcmp(file_filter,'*seg.mat')
    FLAGS.cell_flag = 0;
end
contents_xy = dir([dirname, 'xy*']);
num_xy = numel(contents_xy);
if num_xy
    if isdir([dirname0,contents_xy(dirnum).name,filesep,'seg_full'])
        handles.dirname_seg = [dirname0,contents_xy(dirnum).name,filesep,'seg_full',filesep];
    else
        handles.dirname_seg = [dirname0,contents_xy(dirnum).name,filesep,'seg',filesep];
    end
    handles.dirname_cell = [dirname0, contents_xy(dirnum).name, filesep, 'cell', filesep];
    dirname_xy = [dirname0, contents_xy(dirnum).name, filesep];
    clist_name = [dirname0, contents_xy(dirnum).name, filesep, 'clist.mat']; % Open clist if it exists
    if exist( clist_name, 'file' )
        handles.clist = load([dirname0,contents_xy(dirnum).name,filesep,'clist.mat']);
    else
        handles.clist = [];
    end
end
handles.contents = dir([handles.dirname_seg, file_filter]);
handles.num_im = length(handles.contents);
if exist([dirname0, 'CONST.mat'], 'file')
    CONST = load([dirname0, 'CONST.mat']);
    if isfield(CONST, 'CONST')
        CONST = CONST.CONST;
    end
end
FLAGS.e_flag = 0;
handles.FLAGS = FLAGS;
handles.CONST = CONST;
handles.dirSave = dirSave;
updateImage(hObject, handles)

function updateImage(hObject, handles)
FLAGS = handles.FLAGS;
CONST = handles.CONST;
if str2double(handles.show_frame_no.String) > handles.num_im
    handles.show_frame_no.String = num2str(handles.num_im);
end
FLAGS.ID_flag = handles.cell_numbers.Value;
CONST.view.showFullCellCycleOnly = handles.complete_cell_cycles.Value;
CONST.view.falseColorFlag = handles.false_color.Value;
FLAGS.filt = handles.filtered_fluorescence.Value;
FLAGS.s_flag = handles.fluor_foci_scores.Value;
FLAGS.p_flag = handles.cell_poles.Value;
CONST.view.LogView = handles.log_view.Value;
FLAGS.P_flag = handles.region_outlines.Value;
FLAGS.Outline_flag = handles.outline_cells.Value;
[data_r, data_c, data_f] = intLoadData(handles.dirname_seg, handles.contents, ...
    str2double(handles.show_frame_no.String), handles.num_im, handles.clist);
showSeggerImage(data_c, data_r, data_f, FLAGS, handles.clist, CONST, handles.axes1);
if ~isempty(handles.show_cell_no.String);
    if str2double(handles.show_cell_no.String) > 0;
        if FLAGS.cell_flag;
            regnum = find( data_c.regs.ID == str2double(handles.show_cell_no.String));
            if ~isempty( regnum );
                plot(data_c.CellA{regnum}.coord.r_center(1), ...
                    data_c.CellA{regnum}.coord.r_center(2), 'yx','MarkerSize',50);
            else
                disp('couldn''t find that cell');
            end
        else
            if (str2double(handles.show_cell_no.String) <= data_c.regs.num_regs) && (str2double(handles.show_cell_no.String) > 0)
                plot(data_c.CellA{str2double(handles.show_cell_no.String)}.coord.r_center(1), ...
                    data_c.CellA{str2double(handles.show_cell_no.String)}.coord.r_center(2), 'yx','MarkerSize',50);
            else
                disp( 'Out of range' );
            end
        end
    end
end
guidata(hObject, handles);

function varargout = viewer_OutputFcn(hObject, eventdata, handles)

function viewer_OpeningFcn(hObject, eventdata, handles, varargin)
handles.directory.String = getappdata(0, 'dirname');
initImage(hObject, handles);

function channel_Callback(hObject, eventdata, handles) %
disp('toggling between phase and fluorescence');
FLAGS.f_flag = str2num(c(2));

function channel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function consensus_kymograph_Callback(hObject, eventdata, handles)
if ~exist('dataImArray','var') || isempty(dataImArray)
    [dataImArray] = makeConsensusArray( handles.dirname_cell, handles.CONST, 5, [], handles.clist);
    save ([handles.dirSave,'dataImArray'],'dataImArray');
else
    disp('dataImArray already calculated');
end
[kymo,kymoMask,~,~ ] = makeConsensusKymo(dataImArray.imCellNorm, dataImArray.maskCell , 1 );
disp('press enter to continue.');
pause;

function kymograph_no_Callback(hObject, eventdata, handles) %
if numel(c) > 3
    ll_ = floor(str2num(c(4:end)));
    padStr = getPadSize( dirname_cell );
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
            catch
                disp(['Error loading: ', filename_cell] );
            end
            if ~isempty( data_cell )
                tmp_axis = axis;
                clf;
                makeKymographC(data_cell, 1, CONST,[],FLAGS.filt);
                ylabel('Long Axis (pixels)');
                xlabel('Time (frames)' );
                disp('Press enter to continue');
                pause;
                axis(tmp_axis);
            end
        end
    end
else
    disp ('Please enter a number next to kym');
end

function kymograph_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function mosaic_kymograph_Callback(hObject, eventdata, handles)
tmp_axis = axis;
clf;
makeKymoMosaic( handles.dirname_cell, handles.CONST );
disp('press enter to continue.');
pause;
axis(tmp_axis);

function movie_cell_no_Callback(hObject, eventdata, handles)

function movie_cell_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function save_figure_Callback(hObject, eventdata, handles)
figNum = str2double(input('Figure number :','s')) ;
filename = input('Filename :','s') ;
savename = sprintf('%s/%s', handles.dirSave, filename);
saveas(figNum,(savename),'fig');
print(figNum,'-depsc',[(savename),'.eps'])
saveas(figNum,(savename),'png');
disp (['Figure ', num2str(figNum) ,' is saved in eps, fig and png format at ',savename]);

function show_consensus_Callback(hObject, eventdata, handles)
if ~exist('dataImArray','var') || isempty(dataImArray)
    [dataImArray] = makeConsensusArray( handles.dirname_cell, handles.CONST, 5, [], handles.clist);
    save ([handles.dirSave, 'dataImArray'],'dataImArray');
else
    disp('dataImArray already calculated');
end
[imMosaic, imColor, imBW, imInv, imMosaic10 ] = makeConsensusImage( dataImArray, handles.CONST, 5, 4, 0);
%figure(1)
%clf
imshow(imColor, 'Parent', handles.axes1)
disp('press enter to continue.');
pause;

function show_movie_Callback(hObject, eventdata, handles) %
setAxis = axis;
nn_old = nn;
z_pad = ceil(log(num_im)/log(10));
movdir = 'mov';
if ~exist( movdir, 'dir' )
    mkdir( movdir );
end
file_tmp = ['%0',num2str(z_pad),'d'];
for nn = 1:num_im
    [data_r, data_c, data_f] = intLoadData( dirname_seg, ...
        contents, nn, num_im, clist);
    tmp_im =  showSeggerImage( data_c, data_r, data_f, FLAGS, clist, CONST);
    drawnow;
    disp( ['Frame number: ', num2str(nn)] );
    imwrite( tmp_im, [movdir,filesep,'mov',sprintf(file_tmp,nn),'.tif'], 'TIFF', 'Compression', 'none' );
end
nn = nn_old;
resetFlag = true;

function tower_all_cells_Callback(hObject, eventdata, handles) % 
tmp_axis = axis;
clf;
if numel(c) > 1
    ll_ = floor(str2num(c(2:end)));
else
    ll_ = [];
end
makeFrameStripeMosaic([handles.dirname_cell], handles.CONST, ll_, true );
axis equal
disp('press enter to continue.');
pause;
axis(tmp_axis);

function tower_cell_no_Callback(hObject, eventdata, handles) % 
if numel(c) > 3
    comma_pos = findstr(c,',');
    if isempty(comma_pos)
        ll_ = floor(str2num(c(4:end)));
        xdim__ = [];
    else
        ll_ = floor(str2num(c(4:comma_pos(1))));
        xdim__ = floor(str2num(c(comma_pos(1):end)));
    end
    padStr = getPadSize( dirname_cell );
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
                tmp_axis = axis;
                clf;
                im_tmp = makeFrameMosaic(data_cell, CONST, xdim__);
                disp('Press enter to continue');
                pause;
                axis(tmp_axis);
            end
        end
    end
else
    disp ('Please enter a number next to twr');
end

function tower_cell_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function xy_directory_Callback(hObject, eventdata, handles) %
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
        contents=dir([dirname_seg, file_filter]);
        error_list = [];
        clist = load([dirname0,contents_xy(ll_).name,filesep,'clist.mat']);
        resetFlag = true;
    else
        disp ('Incorrect number for xy position');
    end
else
    disp ('Number of xy position missing');
end

function xy_directory_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
