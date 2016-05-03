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
set(handles.figure1, 'units', 'normalized', 'position', [0.25 0.2 0.35 0.7])
guidata(hObject, handles);


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

function segment_images_Callback(hObject, eventdata, handles)

dirname = handles.directory.String;
if isempty (dirname)
    errordlg ('Please select a directory');
    return
end

if (handles.ec60.Value + handles.ec100.Value + handles.pa100.Value + ...
        handles.pa60.Value + ...
        handles.bay60.Value+handles.eclb60.Value) > 1
    errordlg ('Please select only one constant.')
    return
end

text = '';

if handles.ec60.Value;
    text = '60XEc';
elseif handles.ec100.Value;
    text = '100XEc';
elseif handles.pa100.Value;
    text = '100XPa';
elseif handles.pa60.Value;
    text = '60XPa';
elseif handles.eclb60.Value;
    text = '60XEcLB';
elseif handles.bay60.Value;
    text = '60XBay';
end


% get values for constants
parallel = handles.parallel_flag.Value;
if ~strcmp(text,'');
    CONST = loadConstantsNN(text, parallel);
elseif isfield(handles,'CONST') && ~isempty(handles.CONST)
    CONST = handles.CONST;
else
    errordlg ('No constants selected');
    return
end

% set constants
CONST.trackOpti.NEIGHBOR_FLAG = handles.neighbor_flag.Value;
CONST.trackLoci.fluorFlag = handles.fluor_flag.Value;
CONST.parallel.verbose = handles.verbose.Value;
CONST.trackOpti.pole_flag = handles.pole_snapshot.Value;
CONST.imAlign.AlignChannel = str2double(handles.alignChan.String);
CONST.trackLoci.numSpots = str2num(handles.fociNum.String);
CONST.getLocusTracks.TimeStep = str2num(handles.timestep.String);
CONST.trackOpti.MIN_CELL_AGE = str2num(handles.cell_age.String);
CONST.trackOpti.REMOVE_STRAY = handles.remove_stray.Value;


linkVal = get(handles.link_list,'Value'); 
if linkVal == 1
    CONST.trackOpti.linkFun =  @multiAssignmentFastOnlyOverlap;
else
    CONST.trackOpti.linkFun =  @multiAssignmentPairs;
end


clean_flag = handles.clean_flag.Value;
skip = str2double(handles.skip.String);

BatchSuperSeggerOpti(dirname, skip, clean_flag, CONST);

function ec60_Callback(hObject, eventdata, handles)
function ec100_Callback(hObject, eventdata, handles)
function pa100_Callback(hObject, eventdata, handles)
function pa60_Callback(hObject, eventdata, handles)
function a60_Callback(hObject, eventdata, handles)
function eclb60_Callback(hObject, eventdata, handles)
function pam60_Callback(hObject, eventdata, handles)
function bthai60_Callback(hObject, eventdata, handles)

% tries different constants
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
if handles.bay60.Value;
    resFlags{end+1} = '60XBay';
end
if handles.eclb60.Value;
    resFlags{end+1} = '60XEcLB';
end

tryDifferentConstants(handles.directory.String, resFlags);

% loads constants that user selects 
function loadConstMine_Callback(hObject, eventdata, handles)
if get(hObject,'Value')
[filename,path] = uigetfile('*.mat', 'Pick a superSegger constants file');
handles.CONST = load([path,'/',filename]);
else
    handles.CONST  = [];
end
guidata(hObject, handles)


% opens superSeggerViewer
function view_button_Callback(hObject, eventdata, handles)
superSeggerViewer(handles.directory.String);


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




% --- Executes on selection change in constants_list.
function link_list_Callback(hObject, eventdata, handles)
% hObject    handle to constants_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns constants_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from constants_list



% --- Executes during object creation, after setting all properties.
function link_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to constants_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end