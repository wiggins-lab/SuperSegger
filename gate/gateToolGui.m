function varargout = gateToolGui(varargin)
% GATETOOLGUI MATLAB code for gateToolGui.fig
%      GATETOOLGUI, by itself, creates a new GATETOOLGUI or raises the existing
%      singleton*.
%
%      H = GATETOOLGUI returns the handle to a new GATETOOLGUI or the handle to
%      the existing singleton*.
%
%      GATETOOLGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GATETOOLGUI.M with the given input arguments.
%
%      GATETOOLGUI('Property','Value',...) creates a new GATETOOLGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before gateToolGui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to gateToolGui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help gateToolGui

% Last Modified by GUIDE v2.5 17-Aug-2016 15:27:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @gateToolGui_OpeningFcn, ...
    'gui_OutputFcn',  @gateToolGui_OutputFcn, ...
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
% End initialization code - DO NOT EDIT


% --- Executes just before gateToolGui is made visible.
function gateToolGui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to gateToolGui (see VARARGIN)

% Choose default command line output for gateToolGui
handles.output = hObject;
handles.dirname.String = pwd;
handles.time_flag = 0;
handles.clist_found = 0;
handles.multi_clist = [];
handles.replace_flag = 0;
updateGui(hObject,handles)

set(handles.figure1, 'units', 'normalized', 'position', [0.2 0.1 0.35 0.75]);
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes gateToolGui wait for user response (see UIRESUME)
% uiwait(handles.figure1);





% --- Outputs from this function are returned to the command line.
function varargout = gateToolGui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.multi_clist;


function updateGui(hObject,handles)

if isfield(handles,'multi_clist') && ~isempty(handles.multi_clist)
    handles.clist_found = 1;
else
    handles.clist_found = 0;
    handles.msgbox.String = ['Clists : 0'];
end



if handles.clist_found
    % get def of clist
    
    which_clist = getClist(handles);
    
    if iscell(which_clist)
        which_clist = which_clist{1};
    end
    
    
    if handles.time_flag
        if isfield( which_clist(1), 'def3D' )
            handles.def1.String = ['None';which_clist(1).def3D'];
            handles.def2.String = ['None';which_clist(1).def3D'];
            
        elseif isfield( which_clist(1), 'def3d' )
            handles.def1.String = ['None';which_clist(1).def3d'];
            handles.def2.String = ['None';which_clist(1).def3d'];
            
        end
    else
        handles.def1.String = ['None';which_clist(1).def'];
        handles.def2.String = ['None';which_clist(1).def'];
    end
    
    num_clist = numel(handles.multi_clist);
    names = {};
    for i = 1 : num_clist
        if iscell (handles.multi_clist)
            if ~isfield(handles.multi_clist{i},'name')
                handles.multi_clist{i}.name = ['data',num2str(i)];
            end
            names {end+1} = handles.multi_clist{i}.name;
            
        elseif isstruct (handles.multi_clist)
            if ~isfield(handles.multi_clist(i),'name')
                handles.multi_clist(i).name = ['data',num2str(i)];
            end
            names {end+1} = handles.multi_clist(i).name;
        end
    end
    handles.clist_choice.String = ['All';names'];
    size1 = num2str(size(handles.multi_clist,1));
    size2 = num2str(size(handles.multi_clist,2));
    handles.msgbox.String = ['Clists : ', size1, ' x ', size2 ];
    set(findall(handles.action_panel, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.show_panel, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.save_panel, '-property', 'enable'), 'enable', 'on');
    set(findall(handles.def_panel, '-property', 'enable'), 'enable', 'on');
else
    set(findall(handles.action_panel, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.show_panel, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.save_panel, '-property', 'enable'), 'enable', 'off');
    set(findall(handles.def_panel, '-property', 'enable'), 'enable', 'off');
    
end


guidata(hObject,handles);

function which_clist = getClist(handles)
if handles.clist_choice.Value == 1
    which_clist = handles.multi_clist;
elseif isstruct(handles.multi_clist)
    which_clist = handles.multi_clist(handles.clist_choice.Value-1);
else
    which_clist = handles.multi_clist{handles.clist_choice.Value-1};
end


% --- Executes on button press in xls.
function xls_Callback(hObject, eventdata, handles)
% hObject    handle to xls (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathName] = uiputfile('data.csv', 'Save xls file',  handles.dirname.String);
which_clist = getClist(handles);
gateTool(which_clist,'xls',[pathName,filesep,filename]);


% --- Executes on button press in csv.
function csv_Callback(hObject, eventdata, handles)
% hObject    handle to csv (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathName] = uiputfile('data.csv', 'Save csv file',  handles.dirname.String);
which_clist = getClist(handles);
gateTool(which_clist,'csv',[pathName,filesep,filename]);

% --- Executes on button press in save_mat_file.
function save_mat_file_Callback(hObject, eventdata, handles)
% hObject    handle to save_mat_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathName] = uiputfile('clist.mat', 'Save clist file',  handles.dirname.String);
which_clist = getClist(handles);
gateTool(which_clist,'save',[pathName,filesep,filename]);

function [tmp_clist] = loadClistFromDir()
folderOrClist = uigetdir;
if folderOrClist~=0
    tmp_clist = gateTool(folderOrClist);
else 
    tmp_clist = [];
end

% --- Executes on button press in load_clist.
function load_clist_Callback(hObject, eventdata, handles)
% hObject    handle to load_clist (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[tmp_clist] = loadClistFromDir();
updateGui(hObject,handles)


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)




% --- Executes on button press in drill.
function drill_Callback(hObject, eventdata, handles)
% hObject    handle to drill (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.multi_clist = gateTool(handles.dirname,'drill' );
guidata(hObject,handles);

% --- Executes on button press in merge.
function merge_Callback(hObject, eventdata, handles)
% hObject    handle to merge (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of merge



% --- Executes on button press in dash.
function dash_Callback(hObject, eventdata, handles)
% hObject    handle to dash (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dash
handles.multi_clist = handles.multi_clist';
guidata(hObject,handles);

% --- Executes on button press in strip.
function strip_Callback(hObject, eventdata, handles)
% hObject    handle to strip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


if handles.clist_choice.Value == 1
    if handles.replace_flag
        handles.multi_clist = gateTool(handles.multi_clist,'strip');
    else
       tmp_clist = gateTool(handles.multi_clist,'strip','merge');
       tmp_clist.name = 'all_strip';
       handles.multi_clist{end+1} = tmp_clist;
    end
elseif isstruct(handles.multi_clist)
    if handles.replace_flag
        handles.multi_clist(handles.clist_choice.Value-1) =  gateTool(handles.multi_clist(handles.clist_choice.Value-1),'strip');
    else
        clist_bef = handles.multi_clist(handles.clist_choice.Value-1);
        name_bef = clist_bef.name;
        tmp_striped =  gateTool(clist_bef,'strip');
        tmp_striped.name = [name_bef,'stripped'];
        handles.multi_clist = {};
        handles.multi_clist{1} = clist_bef;
        handles.multi_clist{2} = tmp_striped;
    end
else
    if handles.replace_flag
        handles.multi_clist{handles.clist_choice.Value-1} =  gateTool(handles.multi_clist{handles.clist_choice.Value-1},'strip');
    else
        clist_bef = handles.multi_clist{handles.clist_choice.Value-1};
        name_bef = clist_bef.name;
        tmp_striped =  gateTool(clist_bef,'strip');
        tmp_striped.name = [name_bef,'stripped'];
        handles.multi_clist{end+1} = tmp_striped;
    end
end

updateGui(hObject,handles);
guidata(hObject,handles);


% --- Executes on button press in squeeze.
function squeeze_Callback(hObject, eventdata, handles)
% hObject    handle to squeeze (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.multi_clist = gateTool(handles.multi_clist,'squeeze');
guidata(hObject,handles);
updateGui(hObject,handles)

% --- Executes on button press in expand.
function expand_Callback(hObject, eventdata, handles)
% hObject    handle to expand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.multi_clist = gateTool(handles.multi_clist,'expand');
guidata(hObject,handles);
updateGui(hObject,handles)

% --- Executes on button press in kde.
function kde_Callback(hObject, eventdata, handles)
% hObject    handle to kde (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of kde

if get(hObject,'Value')
    if get(handles.dot,'Value')
        handles.dot.Value = 0;
    end
    if get(handles.hist,'Value')
        handles.hist.Value = 0;
    end
end


% --- Executes on button press in stats.
function stats_Callback(hObject, eventdata, handles)
% hObject    handle to stats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of stats


% --- Executes on button press in time.
function time_Callback(hObject, eventdata, handles)
% hObject    handle to time (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of time
if get(hObject,'Value')
    handles.time_flag = 1;
else
    handles.time_flag = 0;
end

updateGui(hObject,handles)
% --- Executes on selection change in def1.
function def1_Callback(hObject, eventdata, handles)
% hObject    handle to def1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns def1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from def1


% --- Executes during object creation, after setting all properties.
function def1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to def1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in def2.
function def2_Callback(hObject, eventdata, handles)
% hObject    handle to def2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns def2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from def2


% --- Executes during object creation, after setting all properties.
function def2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to def2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in hist_tool.
function hist_Callback(hObject, eventdata, handles)
% hObject    handle to hist_tool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of hist_tool

if get(hObject,'Value')
    if get(handles.dot,'Value')
        handles.dot.Value = 0;
    end
    if get(handles.kde,'Value')
        handles.kde.Value = 0;
    end
end

% --- Executes on button press in dot.
function dot_Callback(hObject, eventdata, handles)
% hObject    handle to dot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of dot
if get(hObject,'Value')
    if get(handles.hist,'Value')
        handles.hist.Value = 0;
    end
    if get(handles.kde,'Value')
        handles.kde.Value = 0;
    end
    
end

% --- Executes on button press in log.
function log_Callback(hObject, eventdata, handles)
% hObject    handle to log (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of log


% --- Executes on button press in cond.
function cond_Callback(hObject, eventdata, handles)
% hObject    handle to cond (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of cond
if get(hObject,'Value')
    handles.density.Value = 0;
end

% --- Executes on button press in show_gates.
function show_gates_Callback(hObject, eventdata, handles)
% hObject    handle to show_gates (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

index1 = handles.def1.Value - 1;
index2 = handles.def2.Value - 1;

varg = {'show'};


if ~index1 && ~index2
    %nothing
elseif index1~=0 && index2 == 0
    varg{end+1} = index1;
elseif index1==0 && index2 ~= 0
    varg{end+1} = index2;
elseif index1~=0 && index2 ~= 0
    varg{end+1} = [index1, index2];
end

if handles.time.Value
    varg{end+1} = 'time';
end


if handles.stats.Value
    varg{end+1} = 'stat';
end

if handles.kde.Value
    varg{end+1} = 'kde';
end

if handles.hist.Value
    varg{end+1} = 'hist';
end
if handles.dot.Value
    varg{end+1} = 'dot';
    if handles.line.Value
        varg{end+1} = 'line';
    end
end

if handles.log.Value
    varg{end+1} = 'log';
    log_axis = [];
    if handles.x_box.Value
        log_axis = [log_axis;1];
    end
    if handles.y_box.Value
        log_axis = [log_axis;2];
    end
    if handles.z_box.Value
        log_axis = [log_axis;3];
    end
    if  ~isempty(log_axis)
        varg{end+1} =  log_axis';
    end
    
end
if handles.cond.Value
    varg{end+1} = 'cond';
end

if handles.density.Value
    varg{end+1} = 'den';
end

if handles.err.Value
    varg{end+1} = 'err';
end

if handles.merge.Value
    varg{end+1} = 'merge';
end


which_clist = getClist(handles)
figure;
gateTool(which_clist,varg{:},'no clear');

% --- Executes on button press in err.
function err_Callback(hObject, eventdata, handles)
% hObject    handle to err (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of err


% --- Executes on button press in load.
function load_Callback(hObject, eventdata, handles)
% hObject    handle to load (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(handles.dirname.String)
    handles.multi_clist = gateTool(handles.dirname.String);
    updateGui(hObject,handles)
end

% --- Executes on button press in add.
function add_Callback(hObject, eventdata, handles)
% hObject    handle to add (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[loaded_clist] = loadClistFromDir();
if iscell(loaded_clist) && size(loaded_clist,2) ==1
    loaded_clist = loaded_clist{1};
end

if isstruct(handles.multi_clist)
    tmp_before = handles.multi_clist;
    handles.multi_clist = {};
    handles.multi_clist{1} = tmp_before;
end

handles.multi_clist{end+1} = loaded_clist;
updateGui(hObject,handles)

% --- Executes on button press in delete.
function delete_Callback(hObject, eventdata, handles)
% hObject    handle to delete (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.clist_choice.Value == 1
    handles.multi_clist = [];
elseif isstruct(handles.multi_clist)
    handles.multi_clist(handles.clist_choice.Value-1) =[];
else
    handles.multi_clist{handles.clist_choice.Value-1} =[];
    handles.multi_clist =  handles.multi_clist(~cellfun('isempty', handles.multi_clist))
end

handles.clist_choice.Value = 1;
updateGui(hObject,handles);

% --- Executes on selection change in def3d.
function def3d_Callback(hObject, eventdata, handles)
% hObject    handle to def3d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns def3d contents as cell array
%        contents{get(hObject,'Value')} returns selected item from def3d


% --- Executes during object creation, after setting all properties.
function def3d_CreateFcn(hObject, eventdata, handles)
% hObject    handle to def3d (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in make_gate.
function make_gate_Callback(hObject, eventdata, handles)
% hObject    handle to make_gate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

index1 = handles.def1.Value - 1;
index2 = handles.def2.Value - 1;


varg = {'make'};

if ~index1 && ~index2
    msgbox ('choose an index')
elseif index1~=0 && index2 == 0
    varg{end+1} = index1;
elseif index1==0 && index2 ~= 0
    varg{end+1} = index2;
elseif index1~=0 && index2 ~= 0
    varg{end+1} = [index1, index2];
end

% merges them permanently.. careful!
if handles.merge.Value
    varg{end+1} = 'merge';
end

if index1 || index2
    if handles.clist_choice.Value == 1
        if handles.replace_flag        
            handles.multi_clist = gateTool(handles.multi_clist,varg{:},'no clear','newfig');
        else
            tmp_clist = gateTool(handles.multi_clist,varg{:},'merge','no clear','newfig');
            tmp_clist.name = 'all_gated';
            handles.multi_clist{end+1} = tmp_clist;
        end
    elseif isstruct(handles.multi_clist)
        if handles.replace_flag
            handles.multi_clist(handles.clist_choice.Value-1) = gateTool(handles.multi_clist(handles.clist_choice.Value-1),varg{:},'no clear','newfig');
        else
            tmp = handles.multi_clist;
            handles.multi_clist = {};
            handles.multi_clist{1} = tmp;
            name_bef = tmp.name;
            handles.multi_clist{2} = gateTool(tmp,varg{:},'no clear','newfig');
            handles.clist_choice.Value = numel(handles.multi_clist)+1;
            handles  = naming_func (handles,[name_bef,'gated']);
        end
    else
        if handles.replace_flag
            handles.multi_clist{handles.clist_choice.Value-1} = gateTool(handles.multi_clist{handles.clist_choice.Value-1},varg{:},'no clear','newfig');
        else
            name_bef = handles.multi_clist{handles.clist_choice.Value-1}.name;
            handles.multi_clist{end+1} = gateTool(handles.multi_clist{handles.clist_choice.Value-1},varg{:},'no clear','newfig');
            handles.clist_choice.Value = numel(handles.multi_clist)+1;
            handles = naming_func (handles,[name_bef,'gated']);
        end
    end
end
updateGui(hObject,handles);
guidata(hObject,handles);



function dirname_Callback(hObject, eventdata, handles)
% hObject    handle to dirname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dirname as text
%        str2double(get(hObject,'String')) returns contents of dirname as a double


% --- Executes during object creation, after setting all properties.
function dirname_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dirname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --------------------------------------------------------------------
function uipushtool1_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to uipushtool1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.dirname.String = uigetdir;
guidata(hObject,handles);

% --------------------------------------------------------------------
function hist_tool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to hist_tool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.hist.Value = 1;
show_gates_Callback(hObject, eventdata, handles);
handles.hist.Value = 0;

% --------------------------------------------------------------------
function contour_tool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to contour_tool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.kde.Value = 1;
show_gates_Callback(hObject, eventdata, handles);
handles.kde.Value = 0;


% --------------------------------------------------------------------
function scatter_tool_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to scatter_tool (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.dot.Value = 1;
show_gates_Callback(hObject, eventdata, handles);
handles.dot.Value = 0;

% --------------------------------------------------------------------
function debug_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to debug (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
keyboard;


% --- Executes on button press in close_figs.
function close_figs_Callback(hObject, eventdata, handles)
% hObject    handle to close_figs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fh=findall(0,'Type','Figure');
for i = 1 : numel(fh)
    if ~strcmp(fh(i).Name,'gateToolGui')
        close(fh(i));
    end
end

% --- Executes on button press in clear_gate.
function clear_gate_Callback(hObject, eventdata, handles)
% hObject    handle to clear_gate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.clist_choice.Value == 1
   handles.multi_clist = gateTool(handles.multi_clist,'clear');
elseif isstruct(handles.multi_clist)
   handles.multi_clist(handles.clist_choice.Value-1) = gateTool(handles.multi_clist(handles.clist_choice.Value-1),'clear');
else
   handles.multi_clist{handles.clist_choice.Value-1} = gateTool(handles.multi_clist{handles.clist_choice.Value-1},'clear');
end

updateGui(hObject,handles);
guidata(hObject,handles);

function handles = naming_func (handles,name)
if handles.clist_choice.Value == 1
    handles.multi_clist = gateTool(handles.multi_clist,'name',name);
elseif isstruct(handles.multi_clist)
    handles.multi_clist(handles.clist_choice.Value-1) = gateTool(handles.multi_clist(handles.clist_choice.Value-1),'name',name);
else
    handles.multi_clist{handles.clist_choice.Value-1} = gateTool(handles.multi_clist{handles.clist_choice.Value-1},'name',name);
end


% --- Executes on button press in name.
function name_Callback(hObject, eventdata, handles)
% hObject    handle to name (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


name = getString ('Clist name', 'Type clist name');
handles = naming_func (handles,name);
updateGui(hObject,handles)

function num_return = getNumber (dlg_title, prompt)

num_lines = 1;
a = inputdlg(prompt,dlg_title,num_lines);

if ~isempty(a) % did not press cancel
    num_return = str2double(a(1));
else
    num_return = [];
end


function str_return = getString (dlg_title, prompt)

num_lines = 1;
a = inputdlg(prompt,dlg_title,num_lines);
if ~isempty(a) % did not press cancel
    str_return = a{1};
else
    str_return = [];
end


% --- Executes on selection change in clist_choice.
function clist_choice_Callback(hObject, eventdata, handles)
% hObject    handle to clist_choice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns clist_choice contents as cell array
%        contents{get(hObject,'Value')} returns selected item from clist_choice


% --- Executes during object creation, after setting all properties.
function clist_choice_CreateFcn(hObject, eventdata, handles)
% hObject    handle to clist_choice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in replace.
function replace_Callback(hObject, eventdata, handles)
% hObject    handle to replace (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of replace
if get(hObject,'Value')
    handles.replace_flag = 1;
else
    handles.replace_flag = 0;
end
guidata(hObject,handles);

% --- Executes on button press in x_box.
function x_box_Callback(hObject, eventdata, handles)
% hObject    handle to x_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of x_box


% --- Executes on button press in y_box.
function y_box_Callback(hObject, eventdata, handles)
% hObject    handle to y_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of y_box


% --- Executes on button press in z_box.
function z_box_Callback(hObject, eventdata, handles)
% hObject    handle to z_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of z_box


% --- Executes on button press in density.
function density_Callback(hObject, eventdata, handles)
% hObject    handle to density (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of density
if get(hObject,'Value')
    handles.cond.Value = 0
end


% --- Executes on button press in line.
function line_Callback(hObject, eventdata, handles)
% hObject    handle to line (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of line
