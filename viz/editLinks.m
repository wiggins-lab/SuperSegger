function varargout = editLinks(varargin)
% editLinks : gui used to edit the links between cells.
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou.
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
    'gui_OpeningFcn', @editLinks_OpeningFcn, ...
    'gui_OutputFcn',  @editLinks_OutputFcn, ...
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


function varargout = editLinks_OutputFcn(hObject, eventdata, handles)


function plotCells (data, viewport, cell_ids)
axes(viewport);
for jj = cell_ids
    rr = data.regs.props(jj).Centroid;
    x_cell = rr(1)-0.5;
    y_cell = rr(2)-0.5;
    plot(x_cell, y_cell, 'o', 'MarkerFaceColor', 'r');
end


function displayDotsToCurrentAndPrevious(hObject, eventdata, handles)
[ii,x_point,y_point] = getClosestCellToPoint(handles.data_c, handles.point);
axes(handles.viewport1);
hold on;
plot(x_point, y_point, 'o', 'MarkerFaceColor', 'g');
handles.cur_id.String = num2str(ii);
if (ii ~=0)
    f_cells = handles.data_c.regs.map.f{ii};
    message = ['Cell ID:', num2str(handles.data_c.regs.ID(ii)), ...
        ' with region ID:', num2str(ii)];
    if (numel(f_cells) ==0)
        message = [message, ' has no link'];
        handles.next_id.String = "";
    else
        message = [message, ' linked to cell forward with region ID:', num2str(f_cells)];
        allOneString = sprintf('%.0f ' , f_cells);
        handles.next_id.String = allOneString(1:end-1);
    end
    handles.message.String = message;
    plotCells (handles.data_f, handles.viewport2, f_cells);
else
    handles.message.String = 'Cell not found';
end


function clickOnImage(hObject, eventdata, handles)
updateImage(hObject, handles);
handles.point = round(eventdata.IntersectionPoint(1:2));
displayDotsToCurrentAndPrevious(hObject, eventdata, handles)


function editLinks_OpeningFcn(hObject, ~, handles, varargin)
handles.dirname_seg = fixDir(getappdata(0, 'dirname_seg'));
handles.dirname_xy = fixDir(getappdata(0, 'dirname_xy'));
handles.dirname_cell = fixDir(getappdata(0, 'dirname_cell'));
handles.frame_no.String = num2str(getappdata(0, 'nn'));
handles.CONST = getappdata(0, 'CONST');
handles.contents = dir([handles.dirname_seg '*_err.mat']);
handles.num_im = length(handles.contents);
handles.flags = fixFlags([]);
handles.flags.edit_links = 1;
handles.flags.Outline_flag = 1;
handles.flags.P_flag = 0;
handles.flags.ID_flag  = 0;
handles.flags.cell_flag = 0;
handles.flags.colored_regions = 1;
handles.colored.Value=1;
handles.cell_id.Value=0;
handles.regs_id.Value=0;
updateImage(hObject, handles);
resetAxis(handles);


function resetAxis(handles)
axes(handles.viewport1);
axis tight;
axes(handles.viewport2);
axis tight;


function updateImage(hObject, handles)
[handles.data_r, handles.data_c, handles.data_f] = intLoadDataViewer( ...
    handles.dirname_seg,...
    handles.contents, str2double(handles.frame_no.String), ...
    handles.num_im, [], handles.flags);

%Copy size of image 1 to image 2.
handles.viewport2.YLim = handles.viewport1.YLim;
handles.viewport2.XLim = handles.viewport1.XLim;
guidata(hObject, handles);

delete(get(handles.viewport1, 'Children'));
delete(get(handles.viewport2, 'Children'));
showSeggerImage(handles.data_c, handles.data_r, handles.data_f, ...
    handles.flags, [], handles.CONST, handles.viewport1);
showSeggerImage(handles.data_f, [], [], ...
    handles.flags, [], handles.CONST, handles.viewport2);
set(handles.viewport1.Children, 'ButtonDownFcn', {@clickOnImage,handles});
set(handles.viewport2.Children, 'ButtonDownFcn', {@clickOnImage,handles});


function figure1_CloseRequestFcn(hObject, eventdata, handles)
delete(hObject);

% Frame no.
function frame_no_Callback(hObject, eventdata, handles)
c = round(str2double(handles.frame_no.String));
if c > handles.num_im
    handles.frame_no.String = num2str(handles.num_im);
elseif isnan(c) || c < 1
    handles.frame_no.String = '1';
else
    handles.frame_no.String = num2str(c);
end
updateImage(hObject, handles)

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


function relink_keep_Callback(hObject, eventdata, handles)
choice = questdlg('Are you sure you want to relink and remake the cell files using the changes you have made?', 'Re-link the cells?', 'Yes', 'No', 'No');
if strcmp(choice, 'Yes')
    skip = 1;
    
    % delete old files that keep track of where you were left off.
    startEnd = [5 20]; % from cell marker to the end
    cleanSuperSegger (handles.dirname_xy, startEnd, skip);
    
    % link without deleting old err files
    delete_old_err_files = 0;
    startFrom = -1;
    header = 'Relink: ';
    trackOptiLinkCellMulti(handles.dirname_seg, delete_old_err_files, ...
        handles.CONST, header, 0, startFrom);
    
    trackOpti(handles.dirname_xy,skip, handles.CONST, header, startEnd);
end

% --- Executes on button press in relink_no_manual.
function relink_no_manual_Callback(hObject, eventdata, handles)
choice = questdlg('Are you sure you want to relink and remake the cell files without keeping the changes you have made?', 'Re-link the cells?', 'Yes', 'No', 'No');
if strcmp(choice, 'Yes')
    skip = 1;
    % Delete SuperSegger tracking files from linking onwards.
    startEnd =[4 20];
    cleanSuperSegger (handles.dirname_xy, startEnd, skip);
    header = 'Relink: ';
    trackOpti(handles.dirname_xy,skip, handles.CONST, header, startEnd);
end

function reg_ids_Callback(hObject, eventdata, handles)
if ~isempty(handles.flags)
    handles.flags.ID_flag = handles.reg_ids.Value;
    if handles.reg_ids.Value
        handles.flags.cell_flag = 0;
        handles.cell_id.Value = 0;
    end
    updateImage(hObject, handles);
end


function colored_Callback(hObject, eventdata, handles)
if ~isempty(handles.flags)
    handles.flags.colored_regions = get(hObject,'Value') ;
    updateImage(hObject, handles);
end

function next_id_Callback(hObject, eventdata, handles)

function next_id_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function cur_id_Callback(hObject, eventdata, handles)

function cur_id_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function add_manual_link_if_missing (handles)
if ~isfield (handles.data_c.regs, 'manual_link')
    handles.data_c.regs.manual_link.f = zeros(1,numel(handles.data_c.regs.ID));
    handles.data_c.regs.manual_link.r = zeros(1,numel(handles.data_c.regs.ID));
end

if ~isfield (handles.data_f.regs, 'manual_link')
    handles.data_f.regs.manual_link.f = zeros(1,numel(handles.data_f.regs.ID));
    handles.data_f.regs.manual_link.r = zeros(1,numel(handles.data_f.regs.ID));
end

% --- Executes on button press in save_link.
function save_link_Callback(hObject, eventdata, handles)
if (handles.cell_id.Value)
    choice = questdlg('You are viewing cell IDs, are you sure you have the region IDs in the boxes?', 'Save the link?', 'Yes', 'No', 'No');
    if ~strcmp(choice, 'Yes')
        return
    end
end
add_manual_link_if_missing (handles)
cur_id = str2double(handles.cur_id.String);
next_id = str2double(strsplit(handles.next_id.String));

% Get old assignments
c = cellfun(@(x)(ismember(next_id,x)),handles.data_c.regs.map.f,'UniformOutput',false);
[old_assignment,~] = find(reshape([c{:}],numel(next_id),[])');

if isnan(cur_id)
    errordlg('Current region ID is empty.');
    return;
end

if numel(cur_id) > 1
    errordlg('Current region ID has more elements than one.');
    return;
end

if max(cur_id) > handles.data_c.regs.num_regs
    errordlg('Current id is larger than the maximum allowed id.');
    return;
end
if isnan(next_id)
    errordlg('Next region ID is empty.');
    return;
end
if max(next_id) > handles.data_f.regs.num_regs
    errordlg('Next id is larger than the maximum allowed id.');
    return;
end

% Make current id to map to next id forward in data_c.
handles.data_c.regs.map.f {cur_id} = next_id;
handles.data_c.regs.manual_link.f(cur_id) = 1;
% Make next id to map to current id backwards in data_f.
for jj = next_id
    handles.data_f.regs.map.r {jj} = cur_id;
    handles.data_f.regs.manual_link.r(jj) = 1;
end

%Remove old link to data_f.
for i = 1: numel(old_assignment)
    old_current_cell = old_assignment(i);
    if (old_current_cell~=cur_id)
        handles.data_c.regs.map.f {old_current_cell} = [];
        handles.data_c.regs.manual_link.f (old_current_cell) = 0;
    end
end
saveData(handles)
updateImage(hObject, handles);
plotCells (handles.data_c, handles.viewport1, cur_id)
plotCells (handles.data_f, handles.viewport2, next_id)

function saveData(handles)
data_c = handles.data_c;
data_f = handles.data_f;
if ~isempty(data_c)
    save([handles.dirname_seg, handles.contents(str2double(handles.frame_no.String)).name], '-STRUCT', 'data_c');
end
if ~isempty(data_f)
    save([handles.dirname_seg, handles.contents(str2double(handles.frame_no.String)+1).name], '-STRUCT', 'data_f');
end

% --- Executes on button press in discard_link.
function discard_link_Callback(hObject, eventdata, handles)
add_manual_link_if_missing (handles)
cur_id = str2double(handles.cur_id.String);
next_id = str2double(strsplit(handles.next_id.String));
if isnan(cur_id)
    errordlg('Current region ID is empty.');
    return;
end
if isnan(next_id)
    errordlg('Current region ID is empty.');
    return;
end
handles.data_c.regs.map.f {cur_id} = [];
handles.data_c.regs.manual_link.f(cur_id) = 0;
for jj = next_id
    handles.data_f.regs.map.r {jj} = [];
    handles.data_f.regs.manual_link.r(jj) = 0;
end
saveData(handles)
updateImage(hObject, handles);


% --- Executes on button press in cell_id.
function cell_id_Callback(hObject, eventdata, handles)
if ~isempty(handles.flags)
    handles.flags.ID_flag = handles.cell_id.Value;
    if handles.cell_id.Value
        handles.flags.cell_flag = 1;
        handles.reg_ids.Value = 0;
    end
    updateImage(hObject, handles);
end
