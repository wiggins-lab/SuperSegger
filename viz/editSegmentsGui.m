function varargout = editSegmentsGui(varargin)
% editSegmentsGui : gui used to turn on/off segments
%
% Copyright (C) 2016 Wiggins Lab
% Written by Silas Boye Nissen.
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
                   'gui_OpeningFcn', @editSegmentsGui_OpeningFcn, ...
                   'gui_OutputFcn',  @editSegmentsGui_OutputFcn, ...
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

function varargout = editSegmentsGui_OutputFcn(hObject, eventdata, handles) 

% Global functions

function clickOnImage(hObject, eventdata, handles)
global settings
FLAGS.im_flag = settings.handles.im_flag;
currentData = load([settings.handles.dirname, settings.handles.contents(str2double(settings.handles.frame_no.String)).name]);
[data, list] = updateTrainingImage(currentData, FLAGS, eventdata.IntersectionPoint(1:2));
save([settings.handles.dirname, settings.handles.contents(str2double(settings.handles.frame_no.String)).name], '-STRUCT', 'data');
updateUI(settings.hObject, settings.handles);

function data = loaderInternal(filename)
data = load(filename);
data.segs.segs_good = double(data.segs.segs_label>0).*double(~data.mask_cell);
data.segs.segs_bad = double(data.segs.segs_label>0).*data.mask_cell;

function editSegmentsGui_OpeningFcn(hObject, eventdata, handles, varargin)
handles.dirname = fixDir(getappdata(0, 'dirname_seg'));
handles.dirname_xy = fixDir(getappdata(0, 'dirname_xy'));
handles.dirname_cell = fixDir(getappdata(0, 'dirname_cell'));
handles.frame_no.String = num2str(getappdata(0, 'nn'));
handles.CONST = getappdata(0, 'CONST');
handles.contents = dir([handles.dirname '*_seg.mat']);
handles.num_im = length(handles.contents);
handles.im_flag = 1;
axis tight;
updateUI(hObject, handles);

function updateUI(hObject, handles)
global settings
delete(get(handles.axes1, 'Children'));
data = loaderInternal([handles.dirname, handles.contents(str2double(handles.frame_no.String)).name]);
data.mask_cell = double((data.mask_bg - data.segs.segs_good - data.segs.segs_3n) > 0);
showSegData(data, handles.im_flag, handles.axes1);
settings.handles = handles;
settings.hObject = hObject;
set(handles.axes1.Children, 'ButtonDownFcn', @clickOnImage);
guidata(hObject, handles);

function figure1_CloseRequestFcn(hObject, eventdata, handles)
setappdata(0, 'dirname', handles.dirname(1:end-8));
delete(hObject);
superSeggerViewerGui();

% Frame no.

function frame_no_Callback(hObject, eventdata, handles)
c = round(str2double(handles.frame_no.String));
if c > handles.num_im
    handles.frame_no.String = num2str(handles.num_im);
elseif isnan(c) || c < 1;
    handles.frame_no.String = '1';
else
    handles.frame_no.String = num2str(c);
end
updateUI(hObject, handles)

function frame_no_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function previous_Callback(hObject, eventdata, handles)
handles.frame_no.String = num2str(str2double(handles.frame_no.String)-1);
frame_no_Callback(hObject, eventdata, handles);

function next_Callback(hObject, eventdata, handles)
handles.frame_no.String = num2str(str2double(handles.frame_no.String)+1);
frame_no_Callback(hObject, eventdata, handles);

function figure1_KeyPressFcn(hObject, eventdata, handles)
if strcmpi(eventdata.Key,'leftarrow')
    previous_Callback(hObject, eventdata, handles);
end
if strcmpi(eventdata.Key,'rightarrow')
    next_Callback(hObject, eventdata, handles);
end

% Radio buttons

function mask_Callback(hObject, eventdata, handles)
handles.im_flag = 2;
handles.phase.Value = 0;
handles.segment.Value = 0;
updateUI(hObject, handles)

function phase_Callback(hObject, eventdata, handles)
handles.im_flag = 3;
handles.mask.Value = 0;
handles.segment.Value = 0;
updateUI(hObject, handles)

function segment_Callback(hObject, eventdata, handles)
handles.im_flag = 1;
handles.mask.Value = 0;
handles.phase.Value = 0;
updateUI(hObject, handles)

function relink_Callback(hObject, eventdata, handles)
choice = questdlg('Are you sure you want to relink and remake the cell files?', 'Re-link the cells?', 'Yes', 'No', 'No');
if strcmp(choice, 'Yes')
    skip = 1;
    
    % deleting old linking files
    startEnd = [4 20]; % from linking to the end
    cleanSuperSegger (handles.dirname_xy, startEnd, skip);

    header = 'Relink: ';
    trackOpti(handles.dirname_xy,skip, handles.CONST, header, startEnd);
end