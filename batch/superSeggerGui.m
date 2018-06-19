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


function help_ClickedCallback(hObject, eventdata, handles)
msgbox('Examples for image conversion : ')

function convert_names_help_Callback(hObject, eventdata, handles)
Opt.Interpreter = 'tex';
Opt.WindowStyle = 'normal';
h = msgbox({'Your images files have to have the format \bf[basename]t[number]xy[number]c[number].tif\rm, where the first number (after \bft\rm) indicates the time frame number, the second number (after \bfxy\rm) is for the different timelapse positions, and finally the third number (after \bfc\rm) are for the different channels (\bfc1\rm are the phase images while \bfc2\rm and onwards are for fluorescence channels), e.g. \bfMG1655{\_}t001xy1c1.tif\rm (where the basename is \bfMG1655{\_}\rm).',
'',
'If your image files do not have this name format you can use the GUI to convert the names. The way the name conversion works is that the user indicates the characters before and after the time frame numbers, before and after the xy numbers, and the characters that indicate the channel. The program can then find the numbers and rename the images to the required naming convention.',
'',
'The different fields are: \bfImage directory\rm: directory where the .tif images are stored. \bfBasename\rm: how you want your images to be named e.g. strain. \bfChannels\rm: an array of strings seperated by comma that indicate the different channels in your filenames e.g. BF,GFP. The one that will be converted to c1 (phase image) should be listed first. \bfTime prefix\rm: characters in you current filename before the number that indicates the time frame. \bfTime suffix\rm: characters in you current filename after the number that indicates the time frame. \bfXY prefix\rm: characters in you current filename before the number that indicates the xy position. \bfXY suffix\rm: characters in you current filename after the number that indicates the xy position.',
'',
'The program can segment images for snapshots (i.e. if \bft\rm is missing from the filename, \bf[basename]xy[number]c[number].tif\rm) or for one xy position (i.e. if \bfxy\rm is missing from the filename, \bf[basename]t[number]c[number].tif\rm).',
'',
'The program can still rename the images if you leave blank either the prefix or the suffix. If both the prefix and suffix are left blank the number 1 is set as default.',
'',
'For more details and examples: https://github.com/wiggins-lab/SuperSegger/wiki/Segmenting-with-SuperSegger'
}, 'Naming Conversion', 'none', Opt);

function convert_names_help_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

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
tbef = handles.timeBefore.String;
taft = handles.timeAfter.String;
xybef =  handles.xyBefore.String;
xyaft = handles.xyAfter.String;

% check if they are numbers

[temp,status] = str2num(tbef)
if status
    tbef = temp;
end

[temp,status] = str2num(taft)
if status
    taft = temp;
end

[temp,status] = str2num(xybef)
if status
    xybef = temp;
end

[temp,status] = str2num(xyaft)
if status
    xyaft = temp;
end


convertImageNames(handles.directory.String, handles.basename.String, ...
    tbef,taft, xybef, xyaft, strsplit(handles.channels.String, ','));


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
CONST.superSeggerOpti.REMOVE_STRAY = handles.remove_stray.Value;
CONST.superSeggerOpti.segmenting_fluorescence = handles.segmenting_fluor.Value;

clean_flag = handles.clean_flag.Value;
skip = str2double(handles.skip.String);
start_step = str2double(handles.start_step.String);
end_step = str2double(handles.end_step.String);
startEnd = [start_step end_step];
debug_flag = 0;
if debug_flag
    BatchSuperSeggerDebug(dirname, skip, clean_flag, CONST, startEnd);
else
    BatchSuperSeggerOpti(dirname, skip, clean_flag, CONST, startEnd);
end

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


% --- Executes on button press in segmenting_fluor.
function segmenting_fluor_Callback(hObject, eventdata, handles)
% hObject    handle to segmenting_fluor (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of segmenting_fluor



function start_step_Callback(hObject, eventdata, handles)
% hObject    handle to start_step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of start_step as text
%        str2double(get(hObject,'String')) returns contents of start_step as a double


% --- Executes during object creation, after setting all properties.
function start_step_CreateFcn(hObject, eventdata, handles)
% hObject    handle to start_step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function end_step_Callback(hObject, eventdata, handles)
% hObject    handle to end_step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of end_step as text
%        str2double(get(hObject,'String')) returns contents of end_step as a double


% --- Executes during object creation, after setting all properties.
function end_step_CreateFcn(hObject, eventdata, handles)
% hObject    handle to end_step (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
