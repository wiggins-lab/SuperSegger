function varargout = superSeggerGui(varargin)
% superSeggerGui : gui for segmenting images with superSegger. 
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Silas Boye Nissen & Stella Stylianidou.
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
    'gui_OpeningFcn', @superSeggerGui_OpeningFcn, ...
    'gui_OutputFcn',  @superSeggerGui_OutputFcn, ...
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

function superSeggerGui_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
handles.directory.String = pwd;
load_listbox(handles)
set(handles.figure1, 'units', 'normalized', 'position', [0.25 0.2 0.38 0.8])
guidata(hObject, handles);


function load_listbox(handles)
[~,reslist] = getConstantsList();
[sorted_names,sorted_index] = sortrows(reslist');
handles.file_names = sorted_names;
handles.sorted_index = sorted_index;
set(handles.constants_list,'String',handles.file_names,...
	'Value',1)

function varargout = superSeggerGui_OutputFcn(hObject, eventdata, handles)
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

% converts image names
function convert_images_Callback(hObject, eventdata, handles)
convertImageNames(handles.directory.String, handles.basename.String, ...
    handles.timeBefore.String, handles.timeAfter.String, handles.xyBefore.String, ...
    handles.xyAfter.String, strsplit(handles.channels.String, ','));


function crop_images_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function crop_images_Callback(hObject, eventdata, handles)
tmp_name = trackOptiCropMulti(handles.directory.String);
if ~isempty(tmp_name)
    handles.directory.String = tmp_name;
end



function segment_images_Callback(hObject, eventdata, handles)

dirname = handles.directory.String;
if isempty (dirname)
    errordlg ('Please select a directory');
    return
end

% load constants
parallel = handles.parallel_flag.Value;
resValue = get(handles.constants_list,'Value');
res = handles.constants_list.String{resValue};
CONST = loadConstants (res,parallel);


% set constants
CONST.trackOpti.NEIGHBOR_FLAG = handles.neighbor_flag.Value;
CONST.trackLoci.fluorFlag = handles.fluor_flag.Value;
CONST.parallel.verbose = handles.verbose.Value;
CONST.imAlign.AlignChannel = str2double(handles.alignChan.String);
CONST.trackLoci.numSpots = str2num(handles.fociNum.String);
CONST.getLocusTracks.TimeStep = str2num(handles.timestep.String);
CONST.trackOpti.MIN_CELL_AGE = str2num(handles.cell_age.String);
CONST.trackOpti.REMOVE_STRAY = handles.remove_stray.Value;
clean_flag = handles.clean_flag.Value;
skip = str2double(handles.skip.String);

BatchSuperSeggerOpti(dirname, skip, clean_flag, CONST);


% tries different constants
function try_constants_Callback(hObject, eventdata, handles)
tryDifferentConstants(handles.directory.String);

% opens superSeggerViewer
function view_button_Callback(hObject, eventdata, handles)
setappdata(0, 'dirname', handles.directory.String);
superSeggerViewerGui();

% functions to get the state of the constants handles 
function pole_snapshot_Callback(hObject, eventdata, handles)
function timestep_Callback(hObject, eventdata, handles)
function timestep_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function fociNum_Callback(hObject, eventdata, handles)
function fociNum_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function alignChan_Callback(hObject, eventdata, handles)
function alignChan_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function remove_stray_Callback(hObject, eventdata, handles)
function verbose_Callback(hObject, eventdata, handles)
function clean_flag_Callback(hObject, eventdata, handles)
function fluor_flag_Callback(hObject, eventdata, handles)
function neighbor_flag_Callback(hObject, eventdata, handles)
function parallel_flag_Callback(hObject, eventdata, handles)
function skip_Callback(hObject, eventdata, handles)
function skip_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cell_age_Callback(hObject, eventdata, handles)
function cell_age_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function constants_list_Callback(hObject, eventdata, handles)
function constants_list_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end