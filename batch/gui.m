function varargout = gui(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
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

function gui_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);

function varargout = gui_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function imageFolder_ClickedCallback(hObject, eventdata, handles)
handles.directory.String = uigetdir;

function directory_Callback(hObject, eventdata, handles)

function directory_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function basename_Callback(hObject, eventdata, handles)

function basename_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function channels_Callback(hObject, eventdata, handles)

function channels_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function timeBefore_Callback(hObject, eventdata, handles)

function timeBefore_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function timeAfter_Callback(hObject, eventdata, handles)

function timeAfter_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function xyBefore_Callback(hObject, eventdata, handles)

function xyBefore_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function xyAfter_Callback(hObject, eventdata, handles)

function xyAfter_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function convert_images_Callback(hObject, eventdata, handles)
if isempty (handles.directory.String)
     errordlg ('Please select a directory');
     return
end
convertImageNames(handles.directory.String, handles.basename.String, ...
    handles.timeBefore.String, handles.timeAfter.String, handles.xyBefore.String, ...
    handles.xyAfter.String, strsplit(handles.channels.String, ','));

function consensus_Callback(hObject, eventdata, handles)

function clean_flag_Callback(hObject, eventdata, handles)

function fluor_flag_Callback(hObject, eventdata, handles)

function neighbor_flag_Callback(hObject, eventdata, handles)

function parallel_flag_Callback(hObject, eventdata, handles)

function skip_Callback(hObject, eventdata, handles)

function skip_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function spots_Callback(hObject, eventdata, handles)

function spots_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function segment_images_Callback(hObject, eventdata, handles)
if isempty (handles.directory.String)
     errordlg ('Please select a directory');
     return
end
if (handles.ec60.Value + handles.ec100.Value + handles.pa100.Value + ...
        handles.a60.Value + handles.pa60.Value + handles.a60.Value + ...
        handles.pam60.Value) > 1
    errordlg ('Too many constants selected')
    return
end
if handles.ec60.Value;
    text = '60XEc';
elseif handles.ec100.Value;
    text = '100XEc';
elseif handles.pa100.Value;
    text = '100XPa';
elseif handles.pa60.Value;
    text = '60XPa';
elseif handles.a60.Value;
    text = '60XA';
elseif handles.eclb60.Value;
    text = '60XEcLB';
elseif handles.pam60.Value;
    text = '60XPaM';
elseif handles.bthai60.Value;
    text = '60XBthai';
else
    errordlg ('No constants selected');
    return
end
CONST = loadConstants(text, handles.parallel_flag.Value);
CONST.consensus = handles.consensus.Value;
CONST.trackLoci.fluorFlag = handles.fluor_flag.Value;
CONST.trackOpti.NEIGHBOR_FLAG = handles.neighbor_flag.Value;
CONST.trackLoci.numSpots = str2double(strsplit(handles.spots.String, ','));
BatchSuperSeggerOpti(handles.directory.String, str2double(handles.skip.String), handles.clean_flag.Value, CONST);

function ec60_Callback(hObject, eventdata, handles)

function ec100_Callback(hObject, eventdata, handles)

function pa100_Callback(hObject, eventdata, handles)

function pa60_Callback(hObject, eventdata, handles)

function a60_Callback(hObject, eventdata, handles)

function eclb60_Callback(hObject, eventdata, handles)

function pam60_Callback(hObject, eventdata, handles)

function bthai60_Callback(hObject, eventdata, handles)

function try_constants_Callback(hObject, eventdata, handles)
resFlags = {};
if handles.ec60.Value;
    resFlags{end+1} = '60XEc';
end
if handles.ec100.Value;
    resFlags{end+1} = '100XEc';
end
if handles.pa100.Value;
    resFlags{end+1} = '100XPa';
end
if handles.pa60.Value;
    resFlags{end+1} = '60XPa';
end
if handles.a60.Value;
    resFlags{end+1} = '60XA';
end
if handles.eclb60.Value;
    resFlags{end+1} = '60XEcLB';
end
if handles.pam60.Value;
    resFlags{end+1} = '60XPaM';
end
if handles.bthai60.Value;
    resFlags{end+1} = '60XBthai';
end
if isempty (handles.directory.String)
     errordlg ('Please select a directory');
     return
end
tryDifferentConstants(handles.directory.String, resFlags);

function view_cells_Callback(hObject, eventdata, handles)
if isempty (handles.directory.String)
     errordlg ('Please select a directory');
     return
end
setappdata(0, 'dirname', handles.directory.String);
viewer();