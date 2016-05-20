function varargout = superSeggerViewerGui(varargin)
% superSeggerViewerGui : gui used to visualize the results of segmentation
% and use the superSegger analysis tools.
%
% Copyright (C) 2016 Wiggins Lab
% Written by Silas Boye Nissen, Connor Brennan, Stella Stylianidou.
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

gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @superSeggerViewerGui_OpeningFcn, ...
    'gui_OutputFcn',  @superSeggerViewerGui_OutputFcn, ...
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

function disable_all_panels (hObject,handles)
set(findall(handles.gate_options_text, '-property', 'enable'), 'enable', 'off')
set(findall(handles.output_options_text, '-property', 'enable'), 'enable', 'off')
set(findall(handles.display_options_text, '-property', 'enable'), 'enable', 'off')
set(findall(handles.link_options_text, '-property', 'enable'), 'enable', 'off')

handles.go_to_frame_no.Enable = 'off';
handles.previous.Enable = 'off';
handles.next.Enable = 'off';
handles.switch_xy_directory.Enable = 'off';
handles.max_cell_no.Enable = 'off';

function enable_all_panels (hObject,handles)
set(findall(handles.gate_options_text, '-property', 'enable'), 'enable', 'on')
set(findall(handles.output_options_text, '-property', 'enable'), 'enable', 'on')
set(findall(handles.display_options_text, '-property', 'enable'), 'enable', 'on')
set(findall(handles.link_options_text, '-property', 'enable'), 'enable', 'on')

handles.go_to_frame_no.Enable = 'on';
handles.previous.Enable = 'on';
handles.next.Enable = 'on';
handles.switch_xy_directory.Enable = 'on';
handles.max_cell_no.Enable = 'on';

function initImage(hObject, handles) % Not updated
global dataImArray;
% initialize
enable_all_panels(hObject,handles)
handles.FLAGS = [];
handles.dirnum = [];
handles.dirSave = [];
handles.dirname0 = [];
handles.contents_xy = [];
handles.clist = [];
handles.num_xy = 0;
handles.num_errs = 0;
handles.canUseErr = 0;
guidata(hObject, handles);

if (nargin<1 || isempty(handles.image_directory.String))
    handles.image_directory.String = pwd;
end
dirname = handles.image_directory.String;

% Ends in xy directory
index = regexp(dirname, [filesep, 'xy.[', filesep, ']*$']);
if index > 0
    dirname = dirname(1:index - 1);
end

handles.image_directory.String = dirname;

file_filter = '';
CONST = [];
axis tight
cla;

dirname = fixDir(dirname);
dirname0 = dirname;
dirSave = [dirname, 'superSeggerViewer', filesep];

% flags
filename_flags = [dirname0,'.superSeggerViewer.mat'];
FLAGS = [];

if exist( filename_flags, 'file' )
    load(filename_flags);
    FLAGS = fixFlags(FLAGS);
else
    FLAGS = fixFlags(FLAGS);
    dirnum = 1;
end

contents_xy = dir([dirname, 'xy*']);
handles.num_xy = numel(contents_xy);
direct_contents_seg = dir([dirname, '*seg.mat']);
direct_contents_err = dir([dirname, '*err.mat']);


if handles.num_xy~=0
    if isdir([dirname0,contents_xy(dirnum).name,filesep,'seg_full'])
        handles.dirname_seg = [dirname0,contents_xy(dirnum).name,filesep,'seg_full',filesep];
    else
        handles.dirname_seg = [dirname0,contents_xy(dirnum).name,filesep,'seg',filesep];
    end
    handles.dirname_cell = [dirname0, contents_xy(dirnum).name, filesep, 'cell', filesep];
    clist_name = [dirname0, contents_xy(dirnum).name, filesep, 'clist.mat'];
    if exist( clist_name, 'file' )
        handles.clist = load([dirname0,contents_xy(dirnum).name,filesep,'clist.mat']);
    else
        handles.clist = [];
    end
else
    if numel(direct_contents_err) == 0 &&  numel(direct_contents_seg) == 0   % no images found abort.
        cla(handles.axes1)
        handles.message.String = ['There are no xy dirs. Choose a different directory.'];
        disable_all_panels(hObject,handles);
        return;
    else % loading from the seg directory directly
        handles.dirname_cell = dirname;
        handles.dirname_seg  = dirname;
        dirnum = 1;
        if numel(direct_contents_err) == 0
            handles.use_seg_files.Value = 1;
        end
    end
end

if nargin<2 || isempty(file_filter);
    if numel(dir([handles.dirname_seg,filesep,'*err.mat']))~=0
        file_filter = '*err.mat';
    else
        file_filter = '*seg.mat';
    end
end

if ~exist(dirSave, 'dir')
    mkdir(dirSave);
else
    if exist([dirSave, 'dataImArray.mat'], 'file')
        load([dirSave, 'dataImArray'],'dataImArray');
        
    end
end


FLAGS.cell_flag = 1; %This is handled by useSegs now
handles.channel.String = num2str(FLAGS.f_flag);
handles.cell_numbers.Value = FLAGS.ID_flag;
handles.cell_poles.Value = FLAGS.p_flag;
handles.outline_cells.Value = FLAGS.Outline_flag;
handles.fluor_foci_scores.Value = FLAGS.s_flag;
handles.filtered_fluorescence.Value = FLAGS.filt;
handles.region_outlines.Value = FLAGS.P_flag;
handles.region_scores.Value = FLAGS.regionScores;
handles.use_seg_files.Value = FLAGS.useSegs;
handles.show_daughters.Value = FLAGS.showDaughters;
handles.show_mothers.Value = FLAGS.showMothers;
handles.show_linking.Value = FLAGS.showLinks;
if exist('nn','var');
    handles.go_to_frame_no.String = num2str(nn);
else
    handles.go_to_frame_no.String = '1';
end

handles.kymograph_cell_no.String = '';
handles.movie_cell_no.String = '';
handles.tower_cell_no.String = '';
handles.max_cell_no.String = '';
handles.find_cell_no.String = '';

handles.contents = dir([handles.dirname_seg, file_filter]);
handles.num_im = length(handles.contents);
handles.use_seg_files.Value = FLAGS.useSegs;

if exist([dirname0, 'CONST.mat'], 'file')
    CONST = load([dirname0, 'CONST.mat']);
    if isfield(CONST, 'CONST')
        CONST = CONST.CONST;
    end
end

handles.CONST = CONST;
handles.FLAGS = FLAGS;
handles.dirnum = dirnum;
handles.dirSave = dirSave;
handles.dirname0 = dirname0;
handles.contents_xy = contents_xy;
handles.filename_flags = filename_flags;
handles.num_xy = 1;
handles.FLAGS.f_flag = 0;
handles.channel.String = 0;

if isempty(handles.clist)
    set(findall(handles.gate_options_text, '-property', 'enable'), 'enable', 'off')
else
    set(findall(handles.gate_options_text, '-property', 'enable'), 'enable', 'on')
    handles.make_gate.String = handles.clist.def';
    handles.histogram_clist.String = handles.clist.def';
    if isfield(handles.clist,'def3d')
        handles.time_clist.String = handles.clist.def3d';
    end
end
handles.go_to_frame_no_text.String = ['Go to frame # (max ' num2str(handles.num_im) ')'];
updateImage(hObject, handles)


function update_all_gui_vals (handles)

handles.contents = dir([handles.dirname_seg, file_filter]);
handles.num_im = length(handles.contents);


function updateImage(hObject, handles)
delete(get(handles.axes1, 'Children'))
handles.previous.Enable = 'off';
handles.next.Enable = 'off';
if ~isempty(handles.FLAGS)
    
    FLAGS = handles.FLAGS;
    dirnum = handles.dirnum;
    handles.message.String = '';
    nn = str2double(handles.go_to_frame_no.String);
    if nn > 1
        handles.previous.Enable = 'on';
    end
    if nn < handles.num_im
        handles.next.Enable = 'on';
    end
    
    if  ~isempty(handles.clist) && ~isempty(handles.clist.gate)
        handles.gate_text.String = 'Gates:';
        cell_gates = struct2cell(handles.clist.gate);
        for i=1:length(cell_gates(2,1,:));
            handles.gate_text.String = strcat(handles.gate_text.String, [num2str(cell_gates{2,1,i}) ',']);
        end
        handles.gate_text.String = handles.gate_text.String(1:end-1);
    else
        handles.gate_text.String = '';
    end
    if ~isempty(handles.clist)
        handles.clist_text.String = ['Clist: ' handles.dirname0,handles.contents_xy(handles.dirnum).name,filesep,'clist.mat'];
    else
        handles.clist_text.String = 'No clist loaded, these commands will not work';
    end
    handles.err_seg.String = ['No. of err. files: ' num2str(length(dir([handles.dirname_seg, '*err.mat']))) char(10) 'No. of seg. files: ' num2str(length(dir([handles.dirname_seg, '*seg.mat'])))];
    handles.num_errs = length(dir([handles.dirname_seg, '*err.mat']));
    
    %Use region IDs if cells IDs unavailable
    if nn > handles.num_errs || FLAGS.useSegs
        handles.canUseErr = 0;
        handles.contents=dir([handles.dirname_seg, '*seg.mat']);
    else
        handles.canUseErr = 1;
        handles.contents=dir([handles.dirname_seg, '*err.mat']);
    end
    
    %Force flags to required values when data is unavailable
    forcedFlags = FLAGS;
    forcedFlags.cell_flag = forcedFlags.cell_flag & shouldUseErrorFiles(FLAGS, handles.canUseErr);
    %Force cell flag to 0 when err files not present
       
    delete(findall(findall(gcf, 'Type', 'axe'), 'Type', 'text'))
    [handles.data_r, handles.data_c, handles.data_f] = intLoadDataViewer(handles.dirname_seg, handles.contents, ...
        nn, handles.num_im, handles.clist, forcedFlags);
    showSeggerImage(handles.data_c, handles.data_r, handles.data_f, forcedFlags, handles.clist, handles.CONST, handles.axes1);
    save(handles.filename_flags, 'FLAGS', 'nn', 'dirnum' );
    guidata(hObject, handles);
    find_cell_no(handles);
end


% messages
handles.message.String = '';
if handles.FLAGS.p_flag
    handles.message.String = [handles.message.String,'| * : new poles, o : old poles |'];
end
if handles.FLAGS.P_flag
    handles.message.String = [handles.message.String,'| Red outlines : dividing, Green : no birth or division observed, Tirquaz : birth , Blue : both birth and division, Purple : errors |'];
end

if handles.num_errs == 0
    handles.use_seg_files.Value = 1;
    makeInactive(handles.use_seg_files);
else
    makeActive(handles.use_seg_files);
end

handles.switch_xy_directory_text.String = ['Switch xy (', num2str(handles.num_xy), ')'];

f = 0;
while true
    if isfield(handles,'data_c') && isfield(handles.data_c, ['fluor' num2str(f+1)] )
        f = f+1;
    else
        break
    end
end
handles.channel_text.String = ['Channel (', num2str(f), ')'];

% Has cell files loaded
if areCellsLoaded(handles)
    makeActiveInput(handles.kymograph_cell_no);
    makeActiveInput(handles.movie_cell_no);
    makeActiveInput(handles.tower_cell_no);
    makeActive(handles.consensus_kymograph);
    makeActive(handles.mosaic_kymograph);
    makeActive(handles.show_consensus);
    makeActive(handles.tower_cells);
    
else
    handles.kymograph_cell_no.String = '';
    makeInactiveInput(handles.kymograph_cell_no);
    handles.movie_cell_no.String = '';
    makeInactiveInput(handles.movie_cell_no);
    handles.tower_cell_no.String = '';
    makeInactiveInput(handles.tower_cell_no);
    makeInactive(handles.consensus_kymograph);
    makeInactive(handles.mosaic_kymograph);
    makeInactive(handles.show_consensus);
    makeInactive(handles.tower_cells);
end

if handles.FLAGS.f_flag >= 1 % Flour 
    makeActive(handles.log_view);
    makeActive(handles.false_color);
    
    if shouldUseErrorFiles(handles.FLAGS, handles.canUseErr)
        makeActive(handles.fluor_foci_scores);
        makeActive(handles.filtered_fluorescence);
    else
        makeInactive(handles.fluor_foci_scores);
        makeInactive(handles.filtered_fluorescence);
    end
else
    makeInactive(handles.log_view);
    makeInactive(handles.fluor_foci_scores);
    makeInactive(handles.filtered_fluorescence);
    makeInactive(handles.false_color);
end

if shouldUseErrorFiles(handles.FLAGS, handles.canUseErr)
    makeActive(handles.cell_poles);
    makeActive(handles.complete_cell_cycles);
    
    if handles.FLAGS.showLinks
        makeActive(handles.show_daughters);
        makeActive(handles.show_mothers);
    else
        makeInactive(handles.show_daughters);
        makeInactive(handles.show_mothers);
    end
    
    makeActive(handles.show_linking);
    
else
    makeInactive(handles.cell_poles);
    makeInactive(handles.complete_cell_cycles);
    
    makeInactive(handles.show_daughters);
    makeInactive(handles.show_mothers);
    makeInactive(handles.show_linking);
    
end

function save_figure_ClickedCallback(hObject, eventdata, handles) % Do not save complete figure!
[filename, pathName] = uiputfile('image.fig', 'Save current image', handles.dirSave);

if ~isempty(strfind(filename, '.'))
    filename = filename(1:(max(strfind(filename, '.')) - 1));
end

if filename ~= 0
    fh = figure('visible', 'off');
    copyobj(handles.axes1, fh);
    savename = sprintf('%s/%s',pathName,filename);
    saveas(fh,(savename),'fig');
    print(fh,'-depsc',[(savename),'.eps'])
    saveas(fh,(savename),'png');
    handles.message.String = ['Figure is saved in eps, fig, and png format at ',savename];
    close(fh);
end

function select_image_directory_ClickedCallback(hObject, eventdata, handles)
folderName = uigetdir;

if folderName ~= 0
    handles.image_directory.String = folderName;
    initImage(hObject, handles);
end

function varargout = superSeggerViewerGui_OutputFcn(hObject, eventdata, handles)

function superSeggerViewerGui_OpeningFcn(hObject, eventdata, handles, varargin)
handles.image_directory.String = pwd;
set(handles.figure1, 'units', 'normalized', 'position', [0 0 1 1])
initImage(hObject, handles);


% Main menu

function image_directory_Callback(hObject, eventdata, handles)
initImage(hObject, handles);

function image_directory_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function go_to_frame_no_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    c = round(str2double(handles.go_to_frame_no.String));
    if c > handles.num_im
        handles.go_to_frame_no.String = num2str(handles.num_im);
    elseif isnan(c) || c < 1;
        handles.go_to_frame_no.String = '1';
    else
        handles.go_to_frame_no.String = num2str(c);
    end
    updateImage(hObject, handles)
end

function go_to_frame_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function next_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.go_to_frame_no.String = num2str(str2double(handles.go_to_frame_no.String)+1);
    go_to_frame_no_Callback(hObject, eventdata, handles);
end

function figure1_KeyPressFcn(hObject, eventdata, handles)
if strcmpi(eventdata.Key,'leftarrow')
	previous_Callback(hObject, eventdata, handles);
end
if strcmpi(eventdata.Key,'rightarrow')
	next_Callback(hObject, eventdata, handles);
end

function previous_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.go_to_frame_no.String = num2str(str2double(handles.go_to_frame_no.String)-1);
    go_to_frame_no_Callback(hObject, eventdata, handles);
end

function max_cell_no_Callback(hObject, eventdata, handles)
handles.CONST.view.maxNumCell = round(str2double(handles.max_cell_no.String));
handles.max_cell_no.String = num2str(round(str2double(handles.max_cell_no.String)));
updateImage(hObject, handles);

function max_cell_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function switch_xy_directory_Callback(hObject, eventdata, handles) % Not tested
if ~isempty(handles.FLAGS)
    ll_ = round(str2double(handles.switch_xy_directory.String));
    dirname0 = handles.dirname0;
    if isnumeric(ll_)
        handles.switch_xy_directory.String = num2str(ll_);
        if ~isempty(ll_) && (ll_ >= 1) && (ll_ <= handles.num_xy)
            try
                save( [dirname0,contents_xy(handles.dirnum).name,filesep,'clist.mat'],'-STRUCT','clist');
            catch ME
                printError(ME);
                handles.message.String = 'Error writing clist file';
            end
            dirnum = ll_;
            dirname_seg = [dirname0,handles.contents_xy(ll_).name,filesep,'seg',filesep];
            dirname_cell = [dirname0,handles.contents_xy(ll_).name,filesep,'cell',filesep];
            dirname_xy = [dirname0,handles.contents_xy(ll_).name,filesep];
            ixy = sscanf( handles.contents_xy(dirnum).name, 'xy%d' );
            header = ['xy',num2str(ixy),': '];
            contents = dir([dirname_seg, '*seg.mat']);
            error_list = [];
            clist = load([dirname0,handles.contents_xy(ll_).name,filesep,'clist.mat']);
            resetFlag = true;
        else
            handles.message.String = 'Incorrect number for xy position';
        end
    else
        handles.message.String = 'Number of xy position missing';
    end
end

function switch_xy_directory_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Display options

function channel_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    f = 0;
    while true
        if isfield(handles,'data_c') && isfield(handles.data_c, ['fluor' num2str(f+1)] )
            f = f+1;
        else
            break
        end
    end
    c = round(str2double(handles.channel.String));
    if isnan(c) || c < 0 || c > f
        handles.channel.String = '0';
    else
        handles.channel.String = num2str(c);
    end
    handles.FLAGS.f_flag = c;
    updateImage(hObject, handles)
end

function channel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function find_cell_no_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    updateImage(hObject, handles)
end

function find_cell_no(handles)
if ~isempty(handles.FLAGS)
    c = round(str2double(handles.find_cell_no.String));
    maxIndex = handles.data_c.regs.num_regs;
    if areCellsLoaded(handles)
        maxIndex = max(handles.data_c.regs.ID);
    end
    if isnan(c) || c < 1 || c >= maxIndex
        handles.find_cell_no.String = '';
    else
        handles.find_cell_no.String = num2str(c);
        if handles.FLAGS.cell_flag && shouldUseErrorFiles(handles.FLAGS, handles.canUseErr)
            regnum = find(handles.data_c.regs.ID == c);
            if ~isempty(regnum)
                plot(handles.data_c.regs.props(regnum).Centroid(1),...
                    handles.data_c.regs.props(regnum).Centroid(2),'yx','MarkerSize',50);
            else
                handles.message.String = 'Couldn''t find that cell number';
            end
        else
            if c <= handles.data_c.regs.num_regs
                plot(handles.data_c.regs.props(c).Centroid(1),...
                    handles.data_c.regs.props(c).Centroid(2),'yx','MarkerSize',50);
            end
        end
    end
end

function find_cell_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cell_numbers_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.ID_flag = handles.cell_numbers.Value;
    if handles.FLAGS.ID_flag
        handles.FLAGS.regionScores = 0;
        handles.region_scores.Value = 0;
    end
    updateImage(hObject, handles)
end

function cell_poles_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.p_flag = handles.cell_poles.Value;
    updateImage(hObject, handles)
end

function complete_cell_cycles_Callback(hObject, eventdata, handles) % Not working
if ~isempty(handles.FLAGS)
    handles.CONST.view.showFullCellCycleOnly = handles.complete_cell_cycles.Value;
    if handles.CONST.view.showFullCellCycleOnly
        figure(2);
        if isfield(handles,'clist') && ~isempty(handles.clist)
            % gate of stat0 2
            handles.clist = gateMake( handles.clist, 9, [1.9 inf] );
        end
        close(2);
        handles.message.String = 'Only showing complete Cell Cycles';
    else
        if isfield(handles,'clist') && ~isempty(handles.clist)
            handles.clist = gateStrip ( handles.clist, 9 );
        end
        
        handles.message.String = 'Showing incomplete Cell Cycles';
    end
    updateImage(hObject, handles)
end

function false_color_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    if ~isfield( handles.CONST,'view') || ~isfield( handles.CONST.view,'falseColorFlag') || isempty( handles.CONST.view.falseColorFlag )
        handles.CONST.view.falseColorFlag = true;
    else
        handles.CONST.view.falseColorFlag = handles.false_color.Value;
    end
    updateImage(hObject, handles)
end

function filtered_fluorescence_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.filt = handles.filtered_fluorescence.Value;
    updateImage(hObject, handles)
end

function fluor_foci_scores_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.s_flag = handles.fluor_foci_scores.Value;
    updateImage(hObject, handles)
end

function log_view_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    if ~isfield( handles.CONST, 'view' ) || ~isfield( handles.CONST.view, 'LogView' ) || isempty( handles.CONST.view.LogView )
        handles.CONST.view.LogView = true;
    else
        handles.CONST.view.LogView = handles.log_view.Value;
    end
    updateImage(hObject, handles)
end

function outline_cells_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.Outline_flag = handles.outline_cells.Value;
    if handles.FLAGS.Outline_flag
        handles.FLAGS.P_flag = 0;
        handles.region_outlines.Value = 0;
    end
    updateImage(hObject, handles)
end

function region_outlines_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.P_flag = handles.region_outlines.Value;
    if handles.FLAGS.P_flag
        handles.FLAGS.Outline_flag = 0;
        handles.outline_cells.Value = 0;
    end
    updateImage(hObject, handles)
end

function region_scores_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.regionScores = handles.region_scores.Value;
    if handles.FLAGS.regionScores
        handles.FLAGS.ID_flag = 0;
        handles.cell_numbers.Value = 0;
    end
    updateImage(hObject, handles)
end

function use_seg_files_Callback(hObject, eventdata, handles) % Not working
if ~isempty(handles.FLAGS)
    if handles.num_errs > 0
        handles.FLAGS.useSegs = handles.use_seg_files.Value;
        updateImage(hObject, handles)
    else
        handles.use_seg_files.Value = 1;
    end
end

% Gate options
function clear_gates_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.clist.gate = [];
    updateImage(hObject, handles);
end

function create_clist_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    if ~isfield( handles.clist, 'gate' )
        handles.clist.gate = [];
    end
    for ll_ = 1:handles.num_xy
        filename = [handles.dirname0,handles.contents_xy(ll_).name,filesep,'clist.mat'];
        clist_tmp = gate(load(filename ));
        if  ll_ == 1
            clist_comp = clist_tmp;
        else
            clist_comp.data = [clist_comp.data; clist_tmp.data];
        end
    end
    save( [handles.dirname0,'clist_comp.mat'], '-STRUCT', 'clist_comp' );
end

function histogram_clist_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    figure(2);
    clf;
    gateHist(handles.clist, handles.histogram_clist.Value);
end

function histogram_clist_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function make_gate_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    figure(2);
    handles.clist = gateMake(handles.clist, handles.make_gate.Value);
    updateImage(hObject, handles)
end

function make_gate_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function move_gates_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    trackOptiGateCellFiles(handles.dirname_cell, handles.clist);
end

function plot_two_clists_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    setappdata(0, 'clist', handles.clist);
    plot2ClistsGui();
end

% Link options

function show_daughters_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.showDaughters = handles.show_daughters.Value;
    updateImage(hObject, handles)
end

function show_mothers_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.showMothers = handles.show_mothers.Value;
    updateImage(hObject, handles)
end

function show_linking_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.showLinks = handles.show_linking.Value;
    updateImage(hObject, handles)
end

% Output options

function kymograph_cell_no_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS) && areCellsLoaded(handles)
    c = round(str2double(handles.kymograph_cell_no.String));
    if isnan(c) || c < 1 || c > max(handles.data_c.regs.ID);
        handles.kymograph_cell_no.String = '';
    else
        handles.kymograph_cell_no.String = num2str(c);
        data_cell = loadCellData(c, handles.dirname_cell, handles);
        if ~isempty( data_cell )
            figure(2);
            clf;
            makeKymographC(data_cell, 1, handles.CONST,[],handles.FLAGS.filt);
            ylabel('Long Axis (pixels)');
            xlabel('Time (frames)' );
        end
    end
end

function kymograph_cell_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function movie_cell_no_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS) && areCellsLoaded(handles)
    c = round(str2double(handles.movie_cell_no.String));
    if isnan(c) || c < 1 || c > max(handles.data_c.regs.ID)
        handles.movie_cell_no.String = '';
    else
        handles.movie_cell_no.String = num2str(c);
        [data_cell,cell_name] = loadCellData(c, handles.dirname_cell, handles);
        if ~isempty(data_cell)
            mov = makeCellMovie(data_cell);
            choice = questdlg('Save movie?', 'Save movie?', 'Yes', 'No', 'No');
            if strcmp(choice, 'Yes')
                saveFilename = [handles.dirSave,cell_name(1:end-4),'.avi'];
                v = VideoWriter(saveFilename);
                open(v)
                writeVideo(v,mov)
                close(v)
                handles.message.String = ['Saved movie at ', saveFilename];
            end
        end
    end
end

function movie_cell_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function no_columns_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    c = round(str2double(handles.no_columns.String));
    if isnan(c) || c < 1 || c > max(handles.data_c.regs.ID)
        handles.no_columns.String = '';
    else
        handles.no_columns.String = num2str(c);
    end
    if ~isempty(handles.tower_cell_no.String)
        tower_cell_no_Callback(hObject, eventdata, handles);
    end
end

function no_columns_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function tower_cell_no_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    c = round(str2double(handles.tower_cell_no.String));
    if isnan(c) || c < 1 || c > max(handles.data_c.regs.ID)
        handles.tower_cell_no.String = '';
    else
        handles.tower_cell_no.String = num2str(c);
        xdim__ = str2double(handles.no_columns.String);
        padStr = getPadSize( handles.dirname_cell, handles );
        if ~isempty( padStr )
            data_cell = [];
            filename_cell_C = [handles.dirname_cell,'Cell',num2str(c,padStr),'.mat'];
            filename_cell_c = [handles.dirname_cell,'cell',num2str(c,padStr),'.mat'];
            if exist(filename_cell_C, 'file' )
                filename_cell = filename_cell_C;
            elseif exist(filename_cell_c, 'file' )
                filename_cell = filename_cell_c;
            else
                filename_cell = [];
            end
            if isempty( filename_cell )
                handles.message.String = ['Files: ',filename_cell_C,' and ',filename_cell_c,' do not exist.'];
            else
                try
                    data_cell = load( filename_cell );
                catch ME
                    printError(ME);
                    handles.message.String = ['Error loading: ', filename_cell];
                end
                if ~isempty( data_cell )
                    figure(2);
                    clf;
                    makeFrameMosaic(data_cell, handles.CONST, xdim__);
                end
            end
        end
    end
end

function tower_cell_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function consensus_kymograph_Callback(hObject, eventdata, handles)
global dataImArray
if ~isempty(handles.FLAGS) && areCellsLoaded(handles)
    if ~exist('dataImArray','var') || isempty(dataImArray)
        fnum = handles.FLAGS.f_flag;
        if fnum == 0
            fnum = 1;
        end
        [dataImArray] = makeConsensusArray( handles.dirname_cell, handles.CONST...
            , 5,[], fnum, handles.clist);
        save ([handles.dirSave,'dataImArray'],'dataImArray');
    else
        handles.message.String = 'dataImArray already calculated';
    end
    
    [kymo,kymoMask ] = makeConsensusKymo(dataImArray.imCellNorm, dataImArray.maskCell , 1 );
end

function mosaic_kymograph_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS) && areCellsLoaded(handles)
    figure(2);
    im = makeKymoMosaic( handles.dirname_cell, handles.CONST );
end

function show_consensus_Callback(hObject, eventdata, handles)
global dataImArray
if ~isempty(handles.FLAGS) && areCellsLoaded(handles)
    if ~exist('dataImArray','var') || isempty(dataImArray)
        fnum = handles.FLAGS.f_flag;
        if fnum == 0
            fnum = 1;
        end
        [dataImArray] = makeConsensusArray( handles.dirname_cell, handles.CONST...
            , 5,[], fnum, handles.clist);
        save ([handles.dirSave,'dataImArray'],'dataImArray');
    else
        handles.message.String = 'dataImArray already calculated';
    end
    [imMosaic, imColor, imBW, imInv, imMosaic10 ] = makeConsensusImage(dataImArray,handles.CONST,5,4,0);
    figure(2);
    imshow(imColor);
end


function show_movie_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    clear mov;
    mov.cdata = [];
    mov.colormap = [];
    
    delete(get(handles.axes1, 'Children'))
    
    for ii = 1:handles.num_im
        [data_r, data_c, data_f] = intLoadDataViewer( handles.dirname_seg, ...
            handles.contents, ii, handles.num_im, handles.clist, handles.FLAGS);
        showSeggerImage( data_c, data_r, data_f, handles.FLAGS, handles.clist, handles.CONST, handles.axes1);
        drawnow;
        mov(ii) = getframe;
        handles.message.String = ['Frame number: ', num2str(ii)];
    end
    choice = questdlg('Save movie?', 'Save movie?', 'Yes', 'No', 'No');
    if strcmp(choice, 'Yes')
        filename = inputdlg('Filename', 'Filename:', 1);
        if ~isempty(filename)
            saveFilename = [handles.dirSave,filename{1},'.avi'];
            v = VideoWriter(saveFilename);
            v.FrameRate = 2;
            open(v)
            writeVideo(v,mov)
            close(v)
            handles.message.String = ['Saved movie at ', saveFilename];
        end
    end
end

function tower_cells_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS) && areCellsLoaded(handles)
    figure(2);
    imTot = makeFrameStripeMosaic([handles.dirname_cell], handles.CONST, [], true);
end

function stop_tool_ClickedCallback(hObject, eventdata, handles)
% use handles to look at the variables (for example handles.CONST)
% if you want to exit click the continue button on the toolbar.
keyboard;


function value = shouldUseErrorFiles(FLAGS, canUseErr)
value = canUseErr == 1 && FLAGS.useSegs == 0;

function makeActive(button)
button.ForegroundColor = [0, 0, 0];
button.Enable = 'on';

function makeActiveInput(input)
input.ForegroundColor = [0, 0, 0];
input.Enable = 'on';

function makeInactive(button)
button.ForegroundColor = [0, 0, 0];
button.Enable = 'off';

function makeInactiveInput(input)
input.ForegroundColor = [.5, .5, .5];
input.Enable = 'off';

function value = areCellsLoaded(handles)
value =  isfield(handles.data_c.regs, 'ID');


% --- Executes on selection change in time_clist.
function time_clist_Callback(hObject, eventdata, handles)
% hObject    handle to time_clist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(handles.FLAGS) && isfield(handles.clist,'data3D')
    figure(2);
    clf;
    plotClist3D(handles.clist, handles.time_clist.Value);
end


% --- Executes during object creation, after setting all properties.
function time_clist_CreateFcn(hObject, eventdata, handles)
% hObject    handle to time_clist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function clear_gate_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.clist = gateStrip(handles.clist, str2double(handles.clear_gate.String));
    handles.clear_gate.String = '';
    updateImage(hObject, handles)
end

function clear_gate_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
