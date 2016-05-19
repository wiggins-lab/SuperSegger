function varargout = plot2ClistsGui(varargin)
% plot2ClistsGui : gui used to plot a dot plot of two values in the clist
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
                   'gui_OpeningFcn', @plot2ClistsGui_OpeningFcn, ...
                   'gui_OutputFcn',  @plot2ClistsGui_OutputFcn, ...
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

function plot2ClistsGui_OpeningFcn(hObject, eventdata, handles, varargin)
handles.clist = getappdata(0, 'clist');
handles.output = hObject;
handles.char1.String = handles.clist.def';
handles.char2.String = handles.clist.def';
handles.char2.Value = 2;
guidata(hObject, handles);

function varargout = plot2ClistsGui_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

function char1_Callback(hObject, eventdata, handles)

function char1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function char2_Callback(hObject, eventdata, handles)

function char2_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function plot_two_clists_Callback(hObject, eventdata, handles)
if handles.char1.Value && handles.char2.Value && handles.char1.Value ~= handles.char2.Value
    figure(2);
    clf;
    gateHistDot(handles.clist, [handles.char1.Value handles.char2.Value])
end
