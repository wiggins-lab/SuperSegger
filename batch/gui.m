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

function parallel_flag_Callback(hObject, eventdata, handles)

function basename_Callback(hObject, eventdata, handles)

function basename_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function timeFilterBefore_Callback(hObject, eventdata, handles)

function timeFilterBefore_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function xyFilterBefore_Callback(hObject, eventdata, handles)

function xyFilterBefore_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function channelNames_Callback(hObject, eventdata, handles)

function channelNames_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function timeFilterAfter_Callback(hObject, eventdata, handles)

function timeFilterAfter_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function xyFilterAfter_Callback(hObject, eventdata, handles)

function xyFilterAfter_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cleanflag_Callback(hObject, eventdata, handles)

function res_Callback(hObject, eventdata, handles)

function res_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function skip_Callback(hObject, eventdata, handles)

function skip_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function dirname_Callback(hObject, eventdata, handles)

function dirname_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function loadConstants_Callback(hObject, eventdata, handles)
res = handles.res.String;
if ~isnan(str2double(res))
    res = str2double(res);
end
CONST = loadConstants(res, handles.parallel_flag.Value);

function tryDifferentConstants_Callback(hObject, eventdata, handles)
tryDifferentConstants(handles.dirname.String);

function convertImageNames_Callback(hObject, eventdata, handles)
chanNames = strsplit(handles.channelNames.String, ',');
convertImageNames(handles.dirname.String, handles.basename.String, handles.timeFilterBefore.String, ...
handles.timeFilterAfter.String, handles.xyFilterBefore.String, handles.xyFilterAfter.String, chanNames);

function BatchSuperSeggerOpti_Callback(hObject, eventdata, handles)
res = handles.res.String;
if ~isnan(str2double(res))
    res = str2double(res);
end
CONST = loadConstants(res, handles.parallel_flag.Value);

BatchSuperSeggerOpti(handles.dirname.String, str2double(handles.skip.String), handles.cleanflag.Value, CONST);
