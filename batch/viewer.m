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

function viewer_OpeningFcn(hObject, eventdata, handles, varargin)

function updateImage(handles)
dirname = handles.directory.String;
hej = handles.axes1;
file_filter = '';
hf = figure(1);
clf;
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
% for calculations that take time like the consensus array
% you can save the array in a folder so that it is loaded from there
% instead of calculated repeatedly.
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
% Load info from one of the xy directories. dirnum tells you which one. If
% you quit the program in an xy dir, it goes to that xy dir.
contents_xy = dir([dirname, 'xy*']);
num_xy = numel(contents_xy);
if ~num_xy
    disp('There are no xy dirs. Choose a different directory.');
    return;
else
    if isdir([dirname0,contents_xy(dirnum).name,filesep,'seg_full'])
        dirname_seg = [dirname0,contents_xy(dirnum).name,filesep,'seg_full',filesep];
    else
        dirname_seg = [dirname0,contents_xy(dirnum).name,filesep,'seg',filesep];
    end
    clist_name = [dirname0,contents_xy(dirnum).name,filesep,'clist.mat']; % Open clist if it exists
    if exist( clist_name, 'file' )
        clist = load([dirname0,contents_xy(dirnum).name,filesep,'clist.mat']);
    else
        clist = [];
    end
end
contents = dir([dirname_seg, file_filter]);
num_im = length(contents);
if exist([dirname0, 'CONST.mat'], 'file')
    CONST = load([dirname0, 'CONST.mat']);
    if isfield(CONST, 'CONST')
        CONST = CONST.CONST;
    end
else
    disp(['Exiting. Can''t load CONST file. Make sure there is a CONST.mat file at the root', ...
        'level of the data directory.']);
end
if nn > num_im % nn : current frame
    nn = num_im;
end
FLAGS.e_flag = 0;
[data_r, data_c, data_f] = intLoadData(dirname_seg, contents, str2double(handles.frame_no.String), num_im, clist);
showSeggerImage(data_c, data_r, data_f, FLAGS, clist, CONST, hej);
close(1);

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

function [data_r, data_c, data_f] = intLoadData(dirname, contents, nn, num_im, clist)
if (nn ==1) && (1 == num_im) % 1 frame only
    data_r = [];
    data_c = loaderInternal([dirname,contents(nn).name], clist);
    data_f = [];
elseif nn == 1;  % first frame
    data_r = [];
    data_c = loaderInternal([dirname,contents(nn).name], clist);
    data_f = [];
elseif nn == num_im ||  nn == num_im-1 % last or before last frame
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

function varargout = viewer_OutputFcn(hObject, eventdata, handles)

function outline_cells_Callback(hObject, eventdata, handles)

function false_color_Callback(hObject, eventdata, handles)

function fluor_foci_scores_Callback(hObject, eventdata, handles)

function cell_poles_Callback(hObject, eventdata, handles)
FLAGS.p_flag = ~FLAGS.p_flag;
updateImage(handles)

function complete_cell_cycles_Callback(hObject, eventdata, handles)
flagsStates.CCState = handles.complete_cell_cycles.Value;
updateImage(handles)

function log_view_Callback(hObject, eventdata, handles)
flagsStates.logState = handles.log_view.Value;
updateImage(handles)

function cell_numbers_Callback(hObject, eventdata, handles)
FLAGS.ID_flag = ~FLAGS.ID_flag;
updateImage(handles)

function region_outlines_Callback(hObject, eventdata, handles)
flagsStates.regionScores = handles.region_outlines.Value;
updateImage(handles)

function filtered_fluorescence_Callback(hObject, eventdata, handles)

function frame_no_Callback(hObject, eventdata, handles)

function frame_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cell_no_Callback(hObject, eventdata, handles)

function cell_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function directory_Callback(hObject, eventdata, handles)

function directory_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function imageFolder_ClickedCallback(hObject, eventdata, handles)
handles.directory.String = uigetdir;

function frame_no_go_Callback(hObject, eventdata, handles)
updateImage(handles)

function cell_no_go_Callback(hObject, eventdata, handles)
        if numel(c) > 1
            find_num = floor(str2num(c(2:end)));
            if FLAGS.cell_flag
                regnum = find( data_c.regs.ID == find_num);
                
                if ~isempty( regnum )
                    plot(data_c.CellA{regnum}.coord.r_center(1),...
                        data_c.CellA{regnum}.coord.r_center(2), ...
                        'yx','MarkerSize',50);
                else
                    disp('couldn''t find that cell');
                end
                
            else
                if (find_num <= data_c.regs.num_regs) && (find_num >0)
                    plot(data_c.CellA{find_num}.coord.r_center(1),...
                        data_c.CellA{find_num}.coord.r_center(2), ...
                        'yx','MarkerSize',50);
                else
                    disp( 'Out of range' );
                end
            end            
            input('Press any key','s');            
        end        

function directory_go_Callback(hObject, eventdata, handles)
updateImage(handles)