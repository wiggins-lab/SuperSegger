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


intCheckForInstallLib

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

function disable_all_panels (~,handles)
set(findall(handles.gate_options_text, '-property', 'enable'), 'enable', 'off')
set(findall(handles.output_options_text, '-property', 'enable'), 'enable', 'off')
set(findall(handles.display_options_text, '-property', 'enable'), 'enable', 'off')
set(findall(handles.link_options_text, '-property', 'enable'), 'enable', 'off')

handles.go_to_frame_no.Enable = 'off';
handles.previous.Enable = 'off';
handles.next.Enable = 'off';
handles.switch_xy_directory.Enable = 'off';
handles.max_cell_no.Enable = 'off';
handles.edit_segments.Enable = 'off';

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
handles.edit_segments.Enable = 'on';


function update_clist_panel(hObject, handles)
if isempty(handles.clist)
    set(findall(handles.gate_options_text, '-property', 'enable'), 'enable', 'off')
    handles.clist_text.String = 'No clist loaded, these commands will not work';
    
else
    handles.clist_text.String = ['Clist: ' handles.contents_xy(handles.dirnum).name,filesep,'clist.mat'];
    set(findall(handles.gate_options_text, '-property', 'enable'), 'enable', 'on')
    handles.make_gate.String = handles.clist.def';
    handles.histogram_clist.String = handles.clist.def';
    if isfield(handles.clist,'def3d')
        handles.time_clist.String = handles.clist.def3d';
    end
     if isfield(handles.clist,'def3D')
        handles.time_clist.String = handles.clist.def3D';
    end
    if isfield(handles.clist,'idExclude')
        handles.exclude_ids.String = num2str(handles.clist.idExclude);
    else
        handles.exclude_ids.String = '';
    end
    if isfield(handles.clist,'idInclude')
        handles.include_ids.String = num2str(handles.clist.idInclude);
    else
        handles.include_ids.String = '';
    end
end
guidata(hObject, handles);

function handles = updateOutputPanel (handles)

output_options = list_output_strings ();
names = output_options(:,1);
needCellFiles = find([output_options{:,2}]);
needClist = find([output_options{:,3}]);
cellFilesFound = areCellsLoaded(handles);
stringList = [];
counter = 0;
for i = 1 : numel(names)
    if any(needClist == i) && isempty(handles.clist)
        % skip
    elseif any(needCellFiles == i) && ~cellFilesFound
        % skip
    else
        counter = counter + 1;
        stringList {counter} = names{i};
    end
end
handles.output_list.String = stringList;
handles.output_list.Value = 1;


function initImage(hObject, handles) % Not updated
global dataImArray;
% initialize
guidata(hObject, handles);
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

axes(handles.axes1);
axis tight
cla;

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

if dirnum > handles.num_xy
    dirnum = 1;
end

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
        if numel(dir([dirname, '*.tif'])) > 0
            handles.message.String = ['Directory does not contain segmented data. Please use superSeggerGui to segment your data.'];
        else
            handles.message.String = ['There are no xy dirs. Choose a different directory.'];
        end
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
    try
        mkdir(dirSave);
    catch
    end
else
    if exist([dirSave, 'dataImArray.mat'], 'file')
        load([dirSave, 'dataImArray'],'dataImArray');
        
    end
end


% flags and checkboxes are initialized here
FLAGS.cell_flag = 1; %This is handled by useSegs now
handles.channel.String = num2str(FLAGS.f_flag);
handles.cell_numbers.Value = FLAGS.ID_flag;
handles.cell_poles.Value = FLAGS.p_flag;
handles.legend_box.Value = FLAGS.legend;
handles.outline_cells.Value = FLAGS.Outline_flag;
if FLAGS.f_flag
    handles.foci_box.Value = FLAGS.s_flag(FLAGS.f_flag);
    handles.scores_foci.Value = FLAGS.scores_flag;
    handles.filt.Value = FLAGS.filt(FLAGS.f_flag);
    handles.phase_flag.Value = FLAGS.phase_flag(FLAGS.f_flag);
else
    handles.filt.Value = 0;
end

handles.region_outlines.Value = FLAGS.P_flag;
handles.region_scores.Value = FLAGS.regionScores;
handles.use_seg_files.Value = FLAGS.useSegs;
handles.show_daughters.Value = FLAGS.showDaughters;
handles.show_mothers.Value = FLAGS.showMothers;
handles.show_linking.Value = FLAGS.showLinks;
handles.phase_level_txt.String = num2str(FLAGS.phase_level);
handles.composite.Value = FLAGS.composite;
if exist('nn','var');
    handles.go_to_frame_no.String = num2str(nn);
else
    handles.go_to_frame_no.String = '1';
end
handles.autoscale.Value = FLAGS.autoscale;
handles.kymograph_cell_no.String = '';
handles.movie_cell_no.String = '';
handles.cell_no.String = '';
handles.max_cell_no.String = '';
handles.find_cell_no.String = '';

handles.channel_color.String = {'r','m','y','g','c','b','w'};


handles.contents = dir([handles.dirname_seg, file_filter]);
handles.contents_seg = dir([handles.dirname_seg, '*seg.mat']);
handles.num_seg = length(handles.contents_seg);
handles.num_err = length(handles.contents);
if handles.num_seg >= handles.num_err
    handles.num_im  = handles.num_seg;
else
    handles.num_im  = handles.num_err;
end


handles.use_seg_files.Value = FLAGS.useSegs;

if exist([dirname0, 'CONST.mat'], 'file')
    %CONST = load([dirname0, 'CONST.mat']);
    CONST = loadConstantsFile( [dirname0,'CONST.mat'] );
    if isfield(CONST, 'CONST')
        CONST = CONST.CONST;
    end
end

f = 0;
while isfield(handles,'data_c') && isfield(handles.data_c, ['fluor' num2str(f+1)] )
    f = f+1;
end

handles.num_fluor = f;
handles.CONST = CONST;
handles.FLAGS = FLAGS;
handles.dirnum = dirnum;
handles.dirSave = dirSave;
handles.dirname0 = dirname0;
handles.contents_xy = contents_xy;
handles.filename_flags = filename_flags;
handles.FLAGS.f_flag = 0;
handles.channel.String = 0;
handles.go_to_frame_no_text.String = ['Time (frames) max: ', num2str(handles.num_im)];
update_clist_panel(hObject, handles)
handles = updateOutputPanel (handles);
handles = updateImage(hObject, handles);
guidata(hObject, handles);

c = FLAGS.f_flag;
if c == 0
    handles.color.String = '';
    handles.min_score.String = '';
else
    handles.color.String = CONST.view.fluorColor{c};
    
    scoreName = [ 'FLUOR',num2str(c),'_MIN_SCORE'];
    
    if isfield( CONST.getLocusTracks, scoreName )
        handles.min_score.String = num2str(CONST.getLocusTracks.(scoreName) );
    else
        handles.min_score.String = '';
    end
end


function handles = updateImage(hObject, handles)
delete(get(handles.axes1, 'Children'))
handles.previous.Enable = 'off';
handles.next.Enable = 'off';
if handles.num_im == 0
    cla(handles.axes1)
    handles.message.String = ['No images/seg/err files found in xy1.'];
    disable_all_panels(hObject,handles);
    handles.switch_xy_directory.Enable = 'on';
else
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
            num_cell_gates = numel(handles.clist.gate);
            for i=1:num_cell_gates
                handles.gate_text.String = strcat(handles.gate_text.String, '[',[num2str(handles.clist.gate(i).ind) ']']);
            end
        else
            handles.gate_text.String = '';
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
        [~,im_ptr] = showSeggerImage(handles.data_c, handles.data_r, handles.data_f, forcedFlags, handles.clist, handles.CONST, handles.axes1);
        set(im_ptr,'ButtonDownFcn',{@clickOnImageInfo,handles} );

        
        intShowLUT( handles );
        
        
        try
            save(handles.filename_flags, 'FLAGS', 'nn', 'dirnum' );
        catch
        end
        
    end
    
    if handles.num_errs == 0
        handles.use_seg_files.Value = 1;
        makeInactive(handles.use_seg_files);
    else
        makeActive(handles.use_seg_files);
    end
    
    makeActive(handles.autoscale)
    
    if handles.num_seg  == 0
        handles.use_seg_files.Enable = 'off';
    end
    
    %handles.switch_xy_directory_text.String = ['Switch xy (', num2str(handles.num_xy), ')'];
    for kk = 1:handles.num_xy
        handles.xy_popup.String{kk} = num2str(kk);
    end
    
    nc = intGetChannelNum(handles.data_c);
    for kk = 0:nc
        handles.channel_popup.String{kk+1} = num2str(kk);
    end
    
    f = 0;
    while true
        if isfield(handles,'data_c') && isfield(handles.data_c, ['fluor' num2str(f+1)] )
            f = f+1;
        else
            break
        end
    end
    handles.channel_text.String = ['Channel (', num2str(f), ')'];
    if handles.FLAGS.f_flag >= 1 %&& ~handles.FLAGS.composite% Fluorescence
        makeActive(handles.log_view);
        makeActive(handles.false_color);
        if shouldUseErrorFiles(handles.FLAGS, handles.canUseErr)
            makeActive(handles.foci_box);
        else
            makeInactive(handles.foci_box);
        end
    else
        makeInactive(handles.log_view);
        makeInactive(handles.foci_box);
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
    if handles.FLAGS.ID_flag
        handles.region_ids.Enable = 'on';
    else
        handles.region_ids.Enable = 'off';
    end
end
guidata(hObject, handles);

function save_figure_ClickedCallback(hObject, eventdata, handles)
[filename, pathName] = uiputfile('image.fig', 'Save current image', handles.dirSave);
if contains(filename, '.')
    filename = filename(1:(max(strfind(filename, '.')) - 1));
end
if filename ~= 0
    fh = figure('visible', 'off');
    copyobj(handles.axes1, fh);
    savename = sprintf('%s/%s',pathName,filename);
    print(fh,'-depsc',[(savename),'.eps'])
    saveas(fh,[(savename),'.png'],'png');
    handles.message.String = ['Figure is saved in eps and png format at ',savename];
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
if getappdata(0, 'dirname')
    handles.image_directory.String = getappdata(0, 'dirname');
    rmappdata(0,'dirname')
else
    handles.image_directory.String = pwd;
end
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
    updateImage(hObject, handles);
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
if strcmpi(eventdata.Key,'e')
    intDispError(handles.data_c, handles.FLAGS, handles.canUseErr);
end

function previous_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.go_to_frame_no.String = num2str(str2double(handles.go_to_frame_no.String)-1);
    go_to_frame_no_Callback(hObject, eventdata, handles);
end


function save_CONST_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
     CONST = handles.CONST;
     
    save( [handles.dirname0,'CONST.mat'], '-STRUCT',  'CONST' );
end


function max_cell_no_Callback(hObject, eventdata, handles)
handles.CONST.view.maxNumCell = round(str2double(handles.max_cell_no.String));
handles.max_cell_no.String = num2str(round(str2double(handles.max_cell_no.String)));
updateImage(hObject, handles);

function max_cell_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function switch_xy_directory_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    ll_ = round(str2double(handles.switch_xy_directory.String));
    dirname0 = handles.dirname0;
    if isnumeric(ll_)
        handles.switch_xy_directory.String = num2str(ll_);
        if ~isempty(ll_) && (ll_ >= 1) && (ll_ <= handles.num_xy)
            try
                clist = handles.clist;
                if ~isempty(clist)
                    save( [dirname0,handles.contents_xy(handles.dirnum).name,filesep,'clist.mat'],'-STRUCT','clist');
                end
            catch ME
                printError(ME);
                handles.message.String = 'Error writing clist file';
            end
            handles.dirnum = ll_;
            handles.dirname_seg = [dirname0,handles.contents_xy(ll_).name,filesep,'seg',filesep];
            handles.dirname_cell = [dirname0,handles.contents_xy(ll_).name,filesep,'cell',filesep];
            handles.dirname_xy = [dirname0,handles.contents_xy(ll_).name,filesep];
            ixy = sscanf( handles.contents_xy(handles.dirnum).name, 'xy%d' );
            handles.header = ['xy',num2str(ixy),': '];
            handles.contents = dir([handles.dirname_seg, '*seg.mat']);
            handles.num_im = numel(handles.contents);
            enable_all_panels(hObject,handles)
            if exist([dirname0,handles.contents_xy(ll_).name,filesep,'clist.mat'])
                handles.clist = load([dirname0,handles.contents_xy(ll_).name,filesep,'clist.mat']);
                update_clist_panel(hObject, handles)
            else
                handles.clist = []
                update_clist_panel(hObject, handles)
            end
            updateImage(hObject, handles);
        else
            handles.message.String = 'Incorrect number for xy position';
        end
    else
        handles.message.String = 'Number of xy position missing';
    end
end
guidata(hObject, handles);

function switch_xy_directory_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% Display options


function channel_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function find_cell_no_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    updateImage(hObject, handles);
    find_cell_no(handles);
end

function find_cell_no(handles)
if ~isempty(handles.FLAGS)
    
    axes( handles.axes1 );
    
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
    updateImage(hObject, handles);
end

function cell_poles_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.p_flag = handles.cell_poles.Value;
    updateImage(hObject, handles);
end

function complete_cell_cycles_Callback(hObject, eventdata, handles)
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
    updateImage(hObject, handles);
end

function false_color_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    if ~isfield( handles.CONST,'view') || ~isfield( handles.CONST.view,'falseColorFlag') || isempty( handles.CONST.view.falseColorFlag )
        handles.CONST.view.falseColorFlag = true;
    else
        handles.CONST.view.falseColorFlag = handles.false_color.Value;
    end
    updateImage(hObject, handles);
end

function gbl_auto_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
        
    chan = handles.FLAGS.f_flag;
    
    handles.FLAGS.gbl_auto(chan+1) = handles.gbl_auto.Value;
    updateImage(hObject, handles);
end

function filt_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    
    channel = handles.FLAGS.f_flag;
    handles.FLAGS.filt(channel) = handles.filt.Value;
    handles.CONST.view.filtered = handles.filt.Value;
    updateImage(hObject, handles);
end

function foci_box_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    
    chan = handles.FLAGS.f_flag;
    handles.FLAGS.s_flag(chan) = handles.foci_box.Value;
    updateImage(hObject, handles);
end

function fluor_scores_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    
    chan = handles.FLAGS.f_flag;

    handles.FLAGS.scores_flag(chan) = handles.scores_foci.Value;
    updateImage(hObject, handles);
end


function log_view_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
   
    chan = handles.FLAGS.f_flag;
    
    handles.FLAGS.log_view(chan) = handles.log_view.Value;
    updateImage(hObject, handles);
end

function outline_cells_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.Outline_flag = handles.outline_cells.Value;
    if handles.FLAGS.Outline_flag
        handles.FLAGS.P_flag = 0;
        handles.region_outlines.Value = 0;
    end
    updateImage(hObject, handles);
end

function region_outlines_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.P_flag = handles.region_outlines.Value;
    if handles.FLAGS.P_flag
        handles.FLAGS.Outline_flag = 0;
        handles.outline_cells.Value = 0;
    end
    updateImage(hObject, handles);
end

function region_scores_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.regionScores = handles.region_scores.Value;
    if handles.FLAGS.regionScores
        handles.FLAGS.ID_flag = 0;
        handles.cell_numbers.Value = 0;
    end
    updateImage(hObject, handles);
end

function use_seg_files_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    if handles.num_errs > 0
        handles.FLAGS.useSegs = handles.use_seg_files.Value;
        updateImage(hObject, handles);
    else
        handles.use_seg_files.Value = 1;
    end
end

function manual_lut_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
        chan = handles.FLAGS.f_flag;
        handles.FLAGS.manual_lut(chan+1) = handles.manual_lut.Value;
        updateImage(hObject, handles);
end

function level_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
        chan = handles.FLAGS.f_flag;
        handles.FLAGS.level(chan+1) = str2double(handles.level.String);
        updateImage(hObject, handles);
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
            if isfield(clist_tmp,'data3D')
                clist_comp.data3D = [clist_comp.data3D; clist_tmp.data3D];
            end
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


function channel_color_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    chan = handles.FLAGS.f_flag;
    if chan
            handles.CONST.view.fluorColor{chan} = ...
                handles.channel_color.String{handles.channel_color.Value};
            updateImage(hObject, handles);
        
    end
    
end
        
function channel_popup_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
                
     nc = intGetChannelNum( handles.data_c );
                
     c = handles.channel_popup.Value-1;
                
     if c == 0
                    handles.color_popup.Value = 1;
                    handles.min_score.String = '';
                    
     else
                    handles.channel_color.Value = ...
                        intGetColorValue(handles.CONST.view.fluorColor{c}, ...
                        handles.channel_color.String );
                    
                    scoreName = [ 'FLUOR',num2str(c),'_MIN_SCORE'];
                    
          if isfield( handles.CONST.getLocusTracks, scoreName )
                        handles.min_score.String = num2str(handles.CONST.getLocusTracks.(scoreName) );
          else
                        handles.min_score.String = '';
          end
      end
            
      handles.FLAGS.f_flag = c;
      updateImage(hObject, handles);
end

function xy_popup_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    ll_ = handles.xy_popup.Value;
    dirname0 = handles.dirname0;
    if isnumeric(ll_)

        if ~isempty(ll_) && (ll_ >= 1) && (ll_ <= handles.num_xy)
            try
                clist = handles.clist;
                if ~isempty(clist)
                    save( [dirname0,handles.contents_xy(handles.dirnum).name,filesep,'clist.mat'],'-STRUCT','clist');
                end
            catch ME
                printError(ME);
                handles.message.String = 'Error writing clist file';
            end
            handles.dirnum = ll_;
            handles.dirname_seg = [dirname0,handles.contents_xy(ll_).name,filesep,'seg',filesep];
            handles.dirname_cell = [dirname0,handles.contents_xy(ll_).name,filesep,'cell',filesep];
            handles.dirname_xy = [dirname0,handles.contents_xy(ll_).name,filesep];
            ixy = sscanf( handles.contents_xy(handles.dirnum).name, 'xy%d' );
            handles.header = ['xy',num2str(ixy),': '];
            handles.contents = dir([handles.dirname_seg, '*seg.mat']);
            handles.num_im = numel(handles.contents);
            enable_all_panels(hObject,handles)
            if exist([dirname0,handles.contents_xy(ll_).name,filesep,'clist.mat'])
                handles.clist = load([dirname0,handles.contents_xy(ll_).name,filesep,'clist.mat']);
                update_clist_panel(hObject, handles)
            else
                handles.clist = []
                update_clist_panel(hObject, handles)
            end
            updateImage(hObject, handles);
        else
            handles.message.String = 'Incorrect number for xy position';
        end
    else
        handles.message.String = 'Number of xy position missing';
    end
end
guidata(hObject, handles);

function histogram_clist_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function channel_color_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function channel_popup_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function xy_popup_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function make_gate_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    figure(2);
    handles.clist = gateMake(handles.clist, handles.make_gate.Value);
    updateImage(hObject, handles);
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
    [handles.clist] = plot2ClistsGui();
    updateImage(hObject, handles);
end

% Link options

function show_daughters_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.showDaughters = handles.show_daughters.Value;
    updateImage(hObject, handles);
end

function show_mothers_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.showMothers = handles.show_mothers.Value;
    updateImage(hObject, handles);
end

function show_linking_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.FLAGS.showLinks = handles.show_linking.Value;
    updateImage(hObject, handles);
end


function stop_tool_ClickedCallback(hObject, eventdata, handles)
% button on toolstrip to debug
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
%value =  isfield(handles.data_c.regs, 'ID');
value = numel(dir([handles.dirname_cell,'*ell*']))>0;

function time_clist_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS) && isfield(handles.clist,'data3D')
    figure(2);
    clf;
    plotClist3D(handles.clist, handles.time_clist.Value);
end

function time_clist_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function clear_gate_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.clist = gateStrip(handles.clist, str2double(handles.clear_gate.String));
    handles.clear_gate.String = '';
    updateImage(hObject, handles);
end

function clear_gate_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function exclude_ids_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.clist.idExclude = str2double(strsplit(handles.exclude_ids.String));
    if isnan(handles.clist.idExclude)
        handles.exclude_ids.String = '';
    end
    if isempty(handles.exclude_ids.String)
        handles.clist = rmfield(handles.clist, 'idExclude');
    end
    updateImage(hObject, handles);
end

function exclude_ids_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function include_ids_Callback(hObject, eventdata, handles)
if ~isempty(handles.FLAGS)
    handles.clist.idInclude = str2double(strsplit(handles.include_ids.String));
    if isnan(handles.clist.idInclude)
        handles.include_ids.String = '';
    end
    if isempty(handles.include_ids.String)
        handles.clist = rmfield(handles.clist, 'idInclude');
    end
    updateImage(hObject, handles);
end

function include_ids_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit_segments_Callback(hObject, eventdata, handles)
choice = questdlg('Are you sure you want to edit the segments?', 'Edit segments?', 'Yes', 'No', 'No');
if strcmp(choice, 'Yes')
    setappdata(0, 'CONST', handles.CONST);
    setappdata(0, 'dirname_xy', [handles.dirname0,handles.contents_xy(handles.dirnum).name,filesep]);
    setappdata(0, 'dirname_seg', handles.dirname_seg);
    setappdata(0, 'dirname_cell', handles.dirname_cell);
    setappdata(0, 'nn', str2double(handles.go_to_frame_no.String));
    editSegmentsGui();
end

function intDispError( data_c, FLAGS, canUseErr)
% intDispError
disp(  ' ' );
disp(  '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%' );
disp(  '%     Errors for this frame     %' );
disp(  '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%' );
for kk = 1:data_c.regs.num_regs
    if isfield(data_c,'regs') &&...
            isfield(data_c.regs, 'error') && ...
            isfield(data_c.regs.error,'label') && ...
            ~isempty( data_c.regs.error.label{kk} )
        if FLAGS.cell_flag && shouldUseErrorFiles(FLAGS, canUseErr) && isfield( data_c.regs, 'ID' )
            disp(  ['Cell: ', num2str(data_c.regs.ID(kk)), ', ', ...
                data_c.regs.error.label{kk}] );
        else
            disp(  [ data_c.regs.error.label{kk}] );
        end
    end
end

function clickOnImage(hObject, eventdata, handles)
global settings;
point = round(eventdata.IntersectionPoint(1:2));
if settings.handles.use_seg_files.Value == 1
    errordlg('Untick use regions');
elseif ~isfield(settings.handles,'data_c')
    errordlg('Reload frame first');
else
    data = settings.handles.data_c;
    if ~isfield(data,'regs')
        data = intMakeRegs(data, settings.handles.CONST, [], []);
    end
    [ii,x_point,y_point] = getClosestCellToPoint(data,point);
    hold on;
    plot(x_point, y_point, 'o', 'MarkerFaceColor', 'g' );
    if ii ~= 0
        if strcmp(settings.function, 'exclude')
            settings.id_list(end+1) = data.regs.ID(ii);
            settings.handles.exclude_ids.String = num2str(settings.id_list);
        elseif strcmp(settings.function, 'include')
            settings.id_list(end+1) = data.regs.ID(ii);
            settings.handles.include_ids.String = num2str(settings.id_list);
        else
            disp(['ID : ', num2str(data.regs.ID(ii))]);
            disp(['Area : ', num2str(data.regs.props(ii).Area)]);
                     
            if isfield(data,'CellA')
                disp(['Pole orientation : ', num2str(data.CellA{ii}.pole.op_ori)]);
                disp(['BoundingBox : ', num2str(data.CellA{ii}.BB)]);
                disp(['Axis Lengths : ', num2str(data.CellA{ii}.length)]);
                disp(['Cell Length : ', num2str(data.CellA{ii}.cellLength(1))]);
                disp(['Mean Width : ', num2str(data.CellA{ii}.cellLength(2))]);
                disp(['Cell distance : ', num2str(data.CellA{ii}.cell_dist)]);
                disp(['Cell Old Pole Age : ', num2str( data.CellA{ii}.pole.op_age)]);
                disp(['Cell New Pole Age : ', num2str(data.CellA{ii}.pole.np_age)]);              
                for u = 1 : settings.handles.num_fluor
                    if isfield(data.CellA{ii},['fl',num2str(u)])
                        fluor_name = ['fl',num2str(u)];
                        fluor_field = data.CellA{ii}.(fluor_name);
                        disp(['fluorescence ', num2str(u), ' statistics: '])
                        disp(fluor_field);
                    end
                end
            end         
            updateImage(settings.hObject, settings.handles);
            plot(x_point, y_point, 'o', 'MarkerFaceColor', 'g' );
            cell_info_Callback(settings.hObject, settings.eventdata, settings.handles);
        end
    end
end


function from_img_exclude_Callback(hObject, eventdata, handles)
global settings;
state = get(hObject,'Value');
if state == get(hObject,'Max')
    settings.handles = handles;
    settings.function = 'exclude';
    if isnan(str2double(strsplit(handles.exclude_ids.String)))
        settings.id_list = [];
    else
        settings.id_list = str2double(strsplit(handles.exclude_ids.String));
    end
    set(handles.axes1.Children, 'ButtonDownFcn', @clickOnImage);
elseif state == get(hObject,'Min')
    handles.exclude_ids.String = settings.handles.exclude_ids.String;
    exclude_ids_Callback(hObject, eventdata, handles);
end

function from_img_include_Callback(hObject, eventdata, handles)
global settings;
state = get(hObject,'Value');
if state == get(hObject,'Max')
    settings.handles = handles;
    settings.function = 'include';
    if isnan(str2double(strsplit(handles.include_ids.String)))
        settings.id_list = [];
    else
        settings.id_list = str2double(strsplit(handles.include_ids.String));
    end
    set(handles.axes1.Children, 'ButtonDownFcn', @clickOnImage);
elseif state == get(hObject,'Min')
    handles.include_ids.String = settings.handles.include_ids.String;
    include_ids_Callback(hObject, eventdata, handles);
end

function save_output_Callback(hObject, eventdata, handles)



% --- Executes on button press in legend_box.
function legend_box_Callback(hObject, eventdata, handles)
% hObject    handle to legend_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of legend_box
if ~isempty(handles.FLAGS)
    handles.FLAGS.legend = handles.legend_box.Value;
    updateImage(hObject, handles);
end



% --- Executes on button press in phase_flag.
function phase_flag_Callback(hObject, eventdata, handles)
% hObject    handle to phase_flag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of phase_flag
if ~isempty(handles.FLAGS)
    chan = handles.FLAGS.f_flag;
    handles.FLAGS.phase_flag(chan+1) = get(hObject,'Value');
    updateImage(hObject, handles);
end

function phase_level_txt_Callback(hObject, eventdata, handles)
% hObject    handle to phase_level_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phase_level_txt as text
%        str2double(get(hObject,'String')) returns contents of phase_level_txt as a double
if ~isempty(handles.FLAGS)
    handles.FLAGS.level(handles.FLAGS.f_flag+1) = str2double(get(hObject,'String'));
    updateImage(hObject, handles);
end


function lut_min_Callback(hObject, eventdata, handles)
% hObject    handle to phase_level_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phase_level_txt as text
%        str2double(get(hObject,'String')) returns contents of phase_level_txt as a double
if ~isempty(handles.FLAGS)
    handles.FLAGS.lut_min(handles.FLAGS.f_flag+1) = str2double(get(hObject,'String'));
    updateImage(hObject, handles);
end

function lut_max_Callback(hObject, eventdata, handles)
% hObject    handle to phase_level_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phase_level_txt as text
%        str2double(get(hObject,'String')) returns contents of phase_level_txt as a double
if ~isempty(handles.FLAGS)
   handles.FLAGS.lut_max(handles.FLAGS.f_flag+1) = str2double(get(hObject,'String'));
    updateImage(hObject, handles);
end


function min_score_Callback(hObject, eventdata, handles)
% hObject    handle to phase_level_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phase_level_txt as text
%        str2double(get(hObject,'String')) returns contents of phase_level_txt as a double
if ~isempty(handles.FLAGS)
    
    chan = handles.FLAGS.f_flag;
    if chan
        scoreName = [ 'FLUOR',num2str(chan),'_MIN_SCORE'];

        tmp = str2double(get(hObject,'String'));
        handles.CONST.getLocusTracks.(scoreName) = tmp;
        updateImage(hObject, handles);
    end
    
end

function color_Callback(hObject, ~, handles)
% hObject    handle to phase_level_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of phase_level_txt as text
%        str2double(get(hObject,'String')) returns contents of phase_level_txt as a double
if ~isempty(handles.FLAGS)
    
    chan = handles.FLAGS.f_flag;
    if chan
       
        tmp = get(hObject,'String');
        
        if iscell( tmp )
            tmp = tmp{1};
        end
        
        if ~isempty( tmp ) && ischar( tmp(1) )
            handles.CONST.view.fluorColor{chan} = tmp(1);
            updateImage(hObject, handles);
        end
    end
    
end

% --- Executes during object creation, after setting all properties.
function phase_level_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to phase_level_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in composite.
function composite_Callback(hObject, eventdata, handles)
% hObject    handle to composite (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of composite
if ~isempty(handles.FLAGS)
    handles.FLAGS.composite = get(hObject,'Value') ;
    updateImage(hObject, handles);
end


% --- Executes on button press in composite.
function include_Callback(hObject, eventdata, handles)
% hObject    handle to composite (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of composite
if ~isempty(handles.FLAGS)
    handles.FLAGS.include(handles.FLAGS.f_flag+1) = get(hObject,'Value') ;
    updateImage(hObject, handles);
end



% --- Executes on button press in region_ids.
function region_ids_Callback(hObject, eventdata, handles)
% hObject    handle to region_ids (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of region_ids
if ~isempty(handles.FLAGS)
    handles.FLAGS.cell_flag = ~get(hObject,'Value') ;
    updateImage(hObject, handles);
end



% Output options
function names = list_output_strings ()
% strings that will be included in the output
% format is :  name, needsCellFiles, needsClist
names = [{'Cell Kymo'},1,0;
    {'Cell Movie'},1,0;
    {'Cell Tower'},1,0;
    {'Kymograph Mosaic'},1,0;
    {'Cell Tower Mosaic'},1,0;
    {'Lineage'},0,1;
    {'Field Movie'},0,0;
    {'Field Mosaic'},0,0;
    {'Consensus'},1,0;
    {'Outline figure'},1,0;
    {'Consensus Kymo'},1,0;
    {'Cell Info'},1,0];



% --- Executes on selection change in output_list.
function output_list_Callback(hObject, eventdata, handles)
% Executes on double click of output options :
% make sure names here match with names above.

contents = cellstr(get(hObject,'String'));
value = contents{get(hObject,'Value')};
handles.message.String = '';

if ~isempty(get(hObject, 'UserData')) && get(hObject, 'UserData') == get(hObject, 'Value')
    if strcmp('Cell Kymo',value)
        makeCellKymo(handles);
    elseif strcmp('Cell Movie',value)
        intMakeCellMovie(handles);
    elseif strcmp('Kymograph Mosaic',value)
        if ~areCellsLoaded(handles)
            errordlg('No cell files found');
        else
            figure(2);
            im = makeKymoMosaic( handles.dirname_cell, handles.CONST, handles.FLAGS );
            if handles.save_output.Value
                savename = [handles.dirSave, 'mosaic_kymograph'];
                save (savename, 'im');
                handles.message.String = ['Saved mosaic kymograph at ', savename];
            end
        end
    elseif strcmp('Cell Tower',value)
        makeCellTower(handles);
    elseif strcmp('Outline figure',value)
        makeOutlineFigure(handles);    
    elseif strcmp('Cell Tower Mosaic',value)
        cell_tower_mosaic(handles);
    elseif strcmp('Lineage',value)
        if isempty(handles.clist)
            errordlg('No clist found');
        else
            min_width = 3;
            ids = str2double(handles.cell_no.String);
            if isnan(ids)
                ids = [];
            end
            makeLineage( handles.clist, ids, min_width );
        end
    elseif strcmp('Field Movie',value)
        makeFieldMovie(hObject,handles);
    elseif strcmp('Field Mosaic',value)
        handles = field_mosaic( handles)
    elseif strcmp('Consensus',value);
        handles = consensus_image(handles)
    elseif strcmp('Consensus Kymo',value)
        handles = consensus_kymo(handles);
    elseif strcmp('Cell Info',value)
        handles = cell_info(hObject, eventdata, handles);
    end
end

set(hObject, 'UserData', get(hObject, 'Value')); % for double click selection

function handles = cell_info(hObject, eventdata, handles)
% global settings;
% state = get(hObject,'Value');
% if state == get(hObject,'Max')
%     settings.hObject = hObject;
%     settings.handles = handles;
%     settings.function = 'cell_info';
%     settings.eventdata = eventdata;
%     set(handles.axes1.Children, 'ButtonDownFcn', @clickOnImage);
% elseif state == get(hObject,'Min')
%     updateImage(hObject, handles);
%     
 ii = [];
 
if ~isempty( handles.cell_no.String )
    cell_num = str2num(handles.cell_no.String);
    if (cell_num)
        if isfield( handles, 'data_c' )
           if isfield( handles.data_c, 'regs' )
              if isfield( handles.data_c.regs, 'ID' )
                 reg_num = find(  handles.data_c.regs.ID == cell_num );
                 
                 if ~isempty( reg_num )
                     ii = reg_num(1);
                 else
                    errordlg( 'reg number is empty' ); 
                 end
              else
                  errordlg( 'no ID field' );
              end
           else
               errordlg( 'no regs field' );
           end
            
        else
            errordlg( 'no data_c field.' );
        end
    else
        errordlg( 'cell number isnt valid.' );
    end
else
    errordlg('Please enter a cell number.' );
end
        
if ~isempty( ii )
    if isfield(handles.data_c,'CellA')
        disp(['Pole orientation : ',  num2str(handles.data_c.CellA{ii}.pole.op_ori)]);
        disp(['BoundingBox : ',       num2str(handles.data_c.CellA{ii}.BB)]);
        disp(['Axis Lengths : ',      num2str(handles.data_c.CellA{ii}.length)]);
        disp(['Cell Length : ',       num2str(handles.data_c.CellA{ii}.cellLength(1))]);
        disp(['Mean Width : ',        num2str(handles.data_c.CellA{ii}.cellLength(2))]);
        disp(['Cell distance : ',     num2str(handles.data_c.CellA{ii}.cell_dist)]);
        disp(['Cell Old Pole Age : ', num2str( handles.data_c.CellA{ii}.pole.op_age)]);
        disp(['Cell New Pole Age : ', num2str(handles.data_c.CellA{ii}.pole.np_age)]);
    end
    
end

function handles = consensus_kymo(handles)
global dataImArray
if ~areCellsLoaded(handles)
    errordlg('No cell files found');
else
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
    if handles.save_output.Value
        save ([handles.dirSave, 'consensus_kymograph'], 'kymo', 'kymoMask');
    end
end



function handles = consensus_image(handles)
global dataImArray
if ~areCellsLoaded(handles)
    errordlg('No cell files found');
else
    if true % ~exist('dataImArray','var') || isempty(dataImArray)
        
        nc = intGetChannelNum(handles.data_c);
        
        if handles.FLAGS.composite
            ranger = find(  handles.FLAGS.include(2:nc+1) );
        else
            ranger = handles.FLAGS.f_flag;
        end
        
        imm = {};
        
        for ff = ranger
            tmpskip = 1;
            
            tmp = makeConsensusArray( handles.dirname_cell, handles.CONST...
                , tmpskip,[], ff, handles.clist);
            
            
            
            [imMosaic, imColor, imBW, imInv, imMosaic10, towerMask ] ...
                = makeConsensusImage(tmp,handles.CONST,tmpskip,4,0);
            
            if handles.FLAGS.composite || ~handles.CONST.view.falseColorFlag
                comm = { imBW, handles.CONST.view.fluorColor{ff}, handles.FLAGS.level(ff+1) };
            else
                comm = { imBW, jet(256) };
            end
            
            imm = comp( {imm}, comm );
        end
        
        if ~isempty( imm )
            imm = comp( {imm, 'mask', towerMask} );
        end
        
    else
        handles.message.String = 'dataImArray already calculated';
    end
    
    %     if handles.save_output.Value
    %         save ([handles.dirSave, 'show_consensus'], 'imMosaic', 'imColor', 'imBW', 'imInv', 'imMosaic10');
    %     end
    
    if ~isempty( imm )
        figure(2);
        clf;
        imshow(imm);
    end
    
end


    function makeCellKymo(handles)
        if ~areCellsLoaded(handles)
            errordlg('No cell files found');
        else
            c = str2double(handles.cell_no.String);
            if numel(c) > 1
                c = c(1);
    end
    if isempty(c) || isnan(c) || c < 1 || c > max(handles.data_c.regs.ID)
        handles.message.String = ['Invalid cell number'];
    else
        handles.kymograph_cell_no.String = num2str(c);
        [data_cell,cell_name] = loadCellData(c, handles.dirname_cell, handles);
        handles.message.String = ['Kymograph for cell ', cell_name];
        if ~isempty( data_cell )
            figure(2);
            clf;
            makeKymographC(data_cell, 1, handles.CONST,handles.FLAGS);
            title(cell_name);
            ylabel('Long Axis (pixels)');
            xlabel('Time (frames)' );
        end
    end
end

function intMakeCellMovie(handles)
if ~areCellsLoaded(handles)
    errordlg('No cell files found');
else
    c = str2double(handles.cell_no.String);
    if numel(c) > 1
        c = c(1);
    end
    if isempty(c) || isnan(c) || c < 1 || c > max(handles.data_c.regs.ID)
        handles.message.String = ['Invalid cell number'];
    else
        
        handles.movie_cell_no.String = num2str(c);
        [data_cell,cell_name] = loadCellData(c, handles.dirname_cell, handles);
        
        if ~isempty(data_cell)
            handles.message.String = ['Movie for cell ', cell_name];
            mov = makeCellMovie(data_cell, handles.CONST, handles.FLAGS, handles.clist);
            choice = questdlg('Save movie?', 'Save movie?', 'Yes', 'No', 'No');
            if strcmp(choice, 'Yes')
                saveFilename = [handles.dirSave,cell_name(1:end-4),'.avi'];
                v = VideoWriter(saveFilename);
                v.FrameRate = 10;
                open(v)
                writeVideo(v,mov)
                close(v)
                handles.message.String = ['Saved movie at ', saveFilename];
            end
        end
    end
end




    function hanldes = makeCellTower( handles)
        if ~areCellsLoaded(handles)
            errordlg('No cell files found');
        else
            %     if ~isempty(handles.FLAGS)
            c = str2num(handles.cell_no.String);
            if numel(c) > 1
                c = c(1);
            end
            if isempty(c) || isnan(c) || c < 1 || c > max(handles.data_c.regs.ID)
                handles.message.String = ['Invalid cell number'];
            else
                
                handles.cell_no.String = num2str(c);
                xdim = 4; %str2double(handles.no_columns.String);
                [data_cell,cell_name] = loadCellData(c, handles.dirname_cell, handles);
                if ~isempty( data_cell )
                    handles.message.String = ['Cell Tower for cell ', cell_name];
                    figure(2);
                    clf;
                    %makeFrameMosaic(data_cell, handles.CONST, xdim);
                    makeFrameMosaic(data_cell, handles.CONST, xdim,[],[],handles.FLAGS);
                    title(cell_name);
                end
            end
        end
    
  function hanldes = makeOutlineFigure( handles)
        if ~areCellsLoaded(handles)
            errordlg('No cell files found');
        else
            %     if ~isempty(handles.FLAGS)
 
            if isfield(handles, 'data_c'  )
                
                tmp_axis = axis;
                
                figure(2);
                clf;
                axis(tmp_axis);
                
               showSeggerImage( handles.data_c, [], [], handles.FLAGS, handles.clist, handles.CONST, [] );

               clist_tmp = gate( handles.clist );
               ID_LIST = clist_tmp.data(:,1);
               
               doDrawCellOutlinePAW(  handles.data_c, ID_LIST );
            else
                errordlg('No data_c field found');
            end
        end
            

function [startFr,endFr,skip] = dialogBoxStartEndSkip (handles)
prompt = {'Start frame:', 'End frame:','Choose Total # frames :','or Skip Frames :'};
dlg_title = 'Make Field Movie';
num_lines = 1;
a = inputdlg(prompt,dlg_title,num_lines);

if ~isempty(a) % did not press cancel
    startFr = str2double(a(1));
    endFr =  str2double(a(2));
    numFrm =  str2double(a(3));
    skip =  str2double(a(4));
    if isnan(endFr) || endFr < startFr || endFr > handles.num_im
        endFr = handles.num_im;
    end
    
    if  isnan(startFr) ||startFr < 1 || startFr > handles.num_im
        startFr = 1;
    end
    
    if isnan(skip) && ~isnan(numFrm)
        skip = (endFr-startFr)/(numFrm-1);
    end
    
    if isnan(numFrm) && ~isnan(skip)
        skip = skip;
    end
    
    if isnan(skip) && isnan(numFrm)
        skip = 1; % default value
    end
    
else
    startFr = [];
    endFr = [];
    skip =  [];
    
end



function handles = field_mosaic( handles)

if ~isempty(handles.FLAGS)
    clear mov;
    mov.cdata = [];
    mov.colormap = [];
    [startFr,endFr,skip] = dialogBoxStartEndSkip (handles);
    if ~isempty(startFr)
        counter = 0;
        time = round(startFr:skip:endFr);
        for ii = time
            delete(get(handles.axes1, 'Children'));
            counter = counter  + 1;
            [data_r, data_c, data_f] = intLoadDataViewer( handles.dirname_seg, ...
                handles.contents, ii, handles.num_im, handles.clist, handles.FLAGS);
            showSeggerImage( data_c, data_r, data_f, handles.FLAGS, handles.clist, handles.CONST, handles.axes1);
            drawnow;
            mov(counter) = getframe;
            handles.message.String = ['Frame number: ', num2str(ii)];
        end
        handles.message.String = ('Field mosaic loaded');
        
        figure(2);
        clf;
        
        num_time = numel(time);
        x = min(6,num_time);
        y = ceil(num_time/x);
        if y == 0
            y = 1;
        end
        ha = tight_subplot(y,x,[0.01 0],[0 0],[0 0]);
        counter = 0;
        for ii = time
            counter = counter  + 1;
            axes(ha(counter));
            imshow(mov(counter).cdata);
            hold on;
            text( 30,30,[num2str(ii)],'color','b');
        end
    end
end



function makeFieldMovie(hObject,handles)
% makes field movie
if ~isempty(handles.FLAGS)
    tmp = handles.go_to_frame_no.String;

    clear mov;
    [startFr,endFr,skip] = dialogBoxStartEndSkip (handles);
    if ~isempty(startFr)
        mov.cdata = [];
        mov.colormap = [];
        counter = 1;
        
        for ii = round(startFr:skip: endFr)
            delete(get(handles.axes1, 'Children'))
            [data_r, data_c, data_f] = intLoadDataViewer( handles.dirname_seg, ...
                handles.contents, ii, handles.num_im, handles.clist, handles.FLAGS);
            showSeggerImage( data_c, data_r, data_f, handles.FLAGS, handles.clist, handles.CONST, handles.axes1);
            drawnow;           
            mov(counter) = getframe;
            counter = counter + 1;
            handles.message.String = ['Frame number: ', num2str(ii)];
        end
        choice = questdlg('Save movie?', 'Save movie?', 'Yes', 'No', 'No');
        if strcmp(choice, 'Yes')
            filename = inputdlg('Filename', 'Filename:', 1);
            if ~isempty(filename)
                saveFilename = [handles.dirSave,filename{1},'.avi'];
                v = VideoWriter(saveFilename);
                v.FrameRate = 10;
                open(v);
                writeVideo(v,mov);
                close(v);
                handles.message.String = ['Saved movie at ', saveFilename];
            end
        end
    end
    
    handles.go_to_frame_no.String = tmp;
    updateImage(hObject, handles);
end


function cell_tower_mosaic(handles)
if ~isempty(handles.FLAGS) && areCellsLoaded(handles)
    figure(2);
    clf;
    imTot = makeFrameStripeMosaic([handles.dirname_cell], ...
        handles.CONST, [], true, handles.clist, handles.FLAGS );
    if handles.save_output.Value
        save ([handles.dirSave,'tower_cells'],'imTot');
    end
end

% --- Executes during object creation, after setting all properties.
function output_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to output_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function cell_no_Callback(hObject, eventdata, handles)
% hObject    handle to cell_no (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cell_no as text
%        str2double(get(hObject,'String')) returns contents of cell_no as a double


% --- Executes during object creation, after setting all properties.
function cell_no_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cell_no (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in save_clist.
function save_clist_Callback(hObject, eventdata, handles)
% hObject    handle to save_clist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    clist = handles.clist;
    if ~isempty(clist)
        save( [handles.dirname0,handles.contents_xy(handles.dirnum).name,filesep,'clist.mat'],'-STRUCT','clist');
    end
catch
    disp('Error saving.' );
end

% --- Executes on button press in edit_links.
function edit_links_Callback(hObject, eventdata, handles)
choice = questdlg('Are you sure you want to edit the links?', 'Edit links?', 'Yes', 'No', 'No');
if strcmp(choice, 'Yes')
    setappdata(0, 'CONST', handles.CONST);
    setappdata(0, 'dirname_xy', [handles.dirname0,handles.contents_xy(handles.dirnum).name,filesep]);
    setappdata(0, 'dirname_seg', handles.dirname_seg);
    setappdata(0, 'dirname_cell', handles.dirname_cell);
    setappdata(0, 'nn', str2double(handles.go_to_frame_no.String));
    editLinks();
end

function ind = intGetColorValue( str, lib );
       ind =  find(strcmp(lib , str));        

       
function intShowLUT( handles )
  
    handles.FLAGS.phase_flag = double(logical(handles.FLAGS.phase_flag));
    
    % do the show lut stuff
    chan = handles.FLAGS.f_flag;
    if chan == 0
        im = handles.data_c.phase;
        cc = 'w';
    else
        im = handles.data_c.(['fluor',num2str(chan)]);
        cc = handles.CONST.view.fluorColor{chan};
    end
   
    axes(handles.lut_show )
    [y,x] = hist( double(im(:)), 100 );
    plot( x,y, '.', 'Color', cc );    
    set(gca, 'Yscale', 'log', 'Color', [0,0,0] );
    
    % now set everything in the channel pannel
    handles.include.Value    = handles.FLAGS.include(chan+1);
    handles.level.String     = num2str(handles.FLAGS.level(chan+1));
    handles.lut_min.String   = num2str(handles.FLAGS.lut_min(chan+1));
    handles.lut_max.String   = num2str(handles.FLAGS.lut_max(chan+1));
    handles.manual_lut.Value = handles.FLAGS.manual_lut(chan+1);
    handles.phase_flag.Value = handles.FLAGS.phase_flag(chan+1);
    handles.gbl_auto.Value   = handles.FLAGS.gbl_auto(chan+1);


    if chan == 0       
       makeInactive(handles.channel_color);
       makeInactive(handles.phase_flag);
       makeInactive(handles.log_view);
       makeInactive(handles.false_color);
       makeInactive(handles.foci_box);
       makeInactive(handles.scores_foci);
       makeInactive(handles.min_score);
       makeInactive(handles.filt);

       handles.foci_box.Value = 0;
       handles.scores_foci.Value      = 0;
       handles.min_score.String        = '';
       handles.log_view.Value = 0;
       
    else
       makeActive(handles.channel_color);
       makeActive(handles.phase_flag);
       makeActive(handles.log_view);
       
       handles.log_view.Value = handles.FLAGS.log_view(chan);
       
       filtname = ['fluor',num2str(chan),'_filtered'];
       if isfield( handles.data_c, filtname );
            makeActive(handles.filt);
            handles.filt.Value = handles.FLAGS.filt(chan);
       else
           makeInactive(handles.filt);
           handles.filt.Value = 0;
           handles.FLAGS.filt(chan) = 0;
       end

       
       makeActive(handles.false_color);

       filtname = ['locus',num2str(chan)];
       if isfield( handles.data_c.CellA{1}, filtname );
           makeActive(handles.foci_box);
           makeActive(handles.scores_foci);
           makeActive(handles.min_score);
           
           handles.channel_color.Value = ...
               intGetColorValue(handles.CONST.view.fluorColor{chan}, ...
               handles.channel_color.String );
           
           handles.foci_box.Value = handles.FLAGS.s_flag(chan);
           handles.scores_foci.Value       = handles.FLAGS.scores_flag(chan);
           
           scoreName = [ 'FLUOR',num2str(chan),'_MIN_SCORE'];
           
           
           if ~isfield( handles.CONST.getLocusTracks, scoreName )
               handles.CONST.getLocusTracks.(scoreName) = 0;
           end
           
           handles.min_score.String        = num2str(handles.CONST.getLocusTracks.(scoreName));
       else
           makeInactive(handles.foci_box);
           handles.foci_box.Value = 0;
           handles.FLAGS.s_flag(chan) = 0;
           
           makeInactive(handles.scores_foci);
           handles.scores_foci.Value       = 0;
           handles.FLAGS.scores_flag(chan) = 0;
           
           makeInactive(handles.min_score);
           handles.min_score.String = '';
       end
      
    end
    
    
    
function ImageClickCallback ( objectHandle , eventData )
    axesHandle  = get(objectHandle,'Parent');
    coordinates = get(axesHandle,'CurrentPoint'); 
    coordinates = coordinates(1,1:2);
    message     = sprintf('x: %.1f , y: %.1f',coordinates (1) ,coordinates (2));
    helpdlg(message);
    
    
function clickOnImageInfo(hObject, eventdata, handles)
    point = round(eventdata.IntersectionPoint(1:2));
    
    reg_num = handles.data_c.regs.regs_label( point(2), point(1) );
    
    if reg_num
        cell_num = handles.data_c.regs.ID( reg_num );
    else
        cell_num = 0;
    end
    
    handles.message.String = ['Cell number: ',num2str(cell_num),...
        '    Region number: ',num2str(reg_num)];
    
    if cell_num
        handles.cell_no.String = num2str( cell_num );
    end




