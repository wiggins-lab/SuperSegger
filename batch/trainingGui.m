function varargout = trainingGui(varargin)
% TRAININGGUI MATLAB code for trainingGui.fig
%      TRAININGGUI, by itself, creates a new TRAININGGUI or raises the existing
%      singleton*.
%
%      H = TRAININGGUI returns the handle to a new TRAININGGUI or the handle to
%      the existing singleton*.
%
%      TRAININGGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRAININGGUI.M with the given input arguments.
%
%      TRAININGGUI('Property','Value',...) creates a new TRAININGGUI or raises
%      the existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before trainingGui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to trainingGui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help trainingGui

% Last Modified by GUIDE v2.5 04-May-2016 15:27:59

% Begin initialization code - DO NOT EDIT

global settings;


gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @trainingGui_OpeningFcn, ...
                   'gui_OutputFcn',  @trainingGui_OutputFcn, ...
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

% --- Executes just before trainingGui is made visible.
function trainingGui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to trainingGui (see VARARGIN)
global settings;

handles.output = hObject;
set(handles.figure1, 'units', 'normalized', 'position', [0.1 0.1 0.8 0.8])
guidata(hObject, handles);

handles.directory.String = pwd;

settings.axisFlag = 4;
settings.frameNumber = 1;
settings.loadFiles = [];
settings.loadDirectory = [];
settings.currentData = [];
settings.handles = handles;
settings.oldData = [];
settings.oldFrame = [];
settings.maxData = 10;
settings.firstPosition = [];
settings.errorHandle = [];
settings.segmentsDirty = 0;
settings.numFrames = 0;
settings.saveFolder = '';

setWorkingDirectory(handles.directory.String);

updateUI(handles);

% UIWAIT makes trainingGui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = trainingGui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;




% --- Executes on button press in cut_and_seg.
function cut_and_seg_Callback(hObject, eventdata, handles)
% hObject    handle to cut_and_seg (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% set constants
dirname = handles.directory.String;

disp ('Croppping images - choose a small region with a couple of colonies');
% only xy1
trackOptiCropMulti(dirname,1)
segTrainingDir = [dirname,filesep,'crop',filesep];
resValue = get(handles.constants_list,'Value'); 
res = handles.constants_list.String{resValue};
CONST = loadConstantsNN (res,0);

skip = 1;
clean_flag = 1;
handles.directory.String = segTrainingDir;
only_seg = 1; % runs only segmentation, no linking
BatchSuperSeggerOpti(segTrainingDir,skip,0,CONST,0,1,only_seg);

setWorkingDirectory(settings.loadDirectory);

% --- Executes on button press in try_const.
function try_const_Callback(hObject, eventdata, handles)
% hObject    handle to try_const (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dirname = fixDir(handles.directory.String);
images = dir([dirname,'*c1*.tif']);

if isempty(images) && ~isempty(dir([dirname,'/raw_im/*c1*.tif']))
    dirname = [dirname, '/raw_im/'];
end

tryDifferentConstants(dirname, []);





% --- Executes on button press in next.
function previous_Callback(hObject, eventdata, handles)
% hObject    handle to next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

settings.frameNumber = settings.frameNumber - 1;
settings.frameNumber = max(settings.frameNumber, 1);

loadData(settings.frameNumber)

updateUI(handles);


% --- Executes on button press in previous.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to previous (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in undo.
function undo_Callback(hObject, eventdata, handles)
% hObject    handle to undo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

if numel(settings.oldData) > 0
    settings.currentData = settings.oldData(1);
    settings.frameNumber = settings.oldFrame(1);
    
    if numel(settings.oldData) > 1
        settings.oldData = settings.oldData(2:end);
        settings.oldFrame = settings.oldFrame(2:end);
    else
        settings.oldData = [];
        settings.oldFrame = [];
    end
    
    updateUI(handles);

    saveData();
else
    dispError('Reached undo limit');
end



function dispError(message)
global settings;

if ~isempty(settings.errorHandle) 
    delete(settings.errorHandle)
end

settings.errorHandle = errordlg(message);



% --- Executes on button press in toggle_segs.
function toggle_segs_Callback(hObject, eventdata, handles)
% hObject    handle to toggle_segs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

settings.axisFlag = 1;

updateUI(handles);


% --- Executes on button press in del_areas.
function del_areas_Callback(hObject, eventdata, handles)
% hObject    handle to del_areas (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

if exist([settings.loadDirectory, '../../CONST.mat'], 'file')
    settings.CONST = load([settings.loadDirectory, '../../CONST.mat']);

    settings.axisFlag = 3;
    
    settings.firstPosition = [];
    
    updateUI(handles);
else
    warning(['Plese segment files first']);
end

% --- Executes on button press in train_segs.
function train_segs_Callback(hObject, eventdata, handles)
% hObject    handle to train_segs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in toggle_regs.
function toggle_regs_Callback(hObject, eventdata, handles)
% hObject    handle to toggle_regs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

settings.axisFlag = 2;

if exist([settings.loadDirectory, '../../CONST.mat'], 'file') && settings.segmentsDirty == 1
    settings.CONST = load([settings.loadDirectory, '../../CONST.mat']);
    settings.currentData = intMakeRegs( settings.currentData, settings.CONST, [], [] );
    
    settings.segmentsDirty = 0;
end

updateUI(handles);

% --- Executes on button press in bad_regs.
function bad_regs_Callback(hObject, eventdata, handles)
% hObject    handle to bad_regs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

if exist([settings.loadDirectory, '../../CONST.mat'], 'file')
    makeBadRegions( settings.loadDirectory, settings.CONST)
    
    settings.numFrames = numel(dir([settings.loadDirectory,'*seg.mat']));
    
    settings.loadFiles = dir([settings.loadDirectory,'*seg*.mat']);
    settings.currentData = load([settings.loadDirectory,settings.loadFiles(settings.frameNumber).name]);
    
    updateUI(handles);
end


% --- Executes on button press in train_regs.
function train_regs_Callback(hObject, eventdata, handles)
% hObject    handle to train_regs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in constants_list.
function constants_list_Callback(hObject, eventdata, handles)
% hObject    handle to constants_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns constants_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from constants_list



% --- Executes during object creation, after setting all properties.
function constants_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to constants_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function directory_Callback(hObject, eventdata, handles)
% hObject    handle to directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of directory as text
%        str2double(get(hObject,'String')) returns contents of directory as a double

setWorkingDirectory(handles.directory.String);


% --- Executes during object creation, after setting all properties.
function directory_CreateFcn(hObject, eventdata, handles)
% hObject    handle to directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in save.
function save_Callback(hObject, eventdata, handles)
% hObject    handle to save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over constants_list.
function constants_list_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to constants_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function image_folder_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to image_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.directory.String = uigetdir;

setWorkingDirectory(handles.directory.String);


% --- Executes on button press in next.
function next_Callback(hObject, eventdata, handles)
% hObject    handle to next (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

settings.frameNumber = settings.frameNumber + 1;
settings.frameNumber = min(settings.frameNumber, numel(settings.loadFiles));

loadData(settings.frameNumber)

updateUI(handles);


function updateUI(handles)
global settings;

firstFrame = 0;
if numel(handles.viewport.Children) == 0
    firstFrame = 1;
end

while numel(handles.viewport.Children) > 0
    delete(handles.viewport.Children(1))
end

if settings.axisFlag == 1 || settings.axisFlag == 2
    FLAGS.im_flag = settings.axisFlag;
    FLAGS.S_flag = 0;
    FLAGS.t_flag = 0;

    showSegRuleGUI(settings.currentData, FLAGS, handles.viewport);

    if numel(handles.viewport.Children) > 0
        set(handles.viewport.Children(1),'ButtonDownFcn',@imageButtonDownFcn);
    end
elseif settings.axisFlag == 3
    FLAGS.im_flag = 2;
    
    showSegRuleGUI(settings.currentData, FLAGS, handles.viewport);
    
    if numel(handles.viewport.Children) > 0
        set(handles.viewport.Children(1),'ButtonDownFcn',@imageButtonDownFcn);
    end
    
    if numel(settings.firstPosition) > 0
        hold on;
        plot( settings.firstPosition(1), settings.firstPosition(2), 'w+','MarkerSize', 30)
    end
elseif settings.axisFlag == 4    
    axes(handles.viewport);
    
    imshow(settings.currentData.phase);
end

if firstFrame
    axis tight;
end
hold on;

if settings.axisFlag > 0
    handles.frameNumber.Visible = 'on';
    handles.frameNumber.String = num2str(settings.frameNumber);
else
    handles.frameNumber.Visible = 'off';
    
    if numel(handles.viewport.Children) > 0
        set(handles.viewport.Children(1),'Visible', 'off');
    end
end

if settings.axisFlag == 4
    handles.tooltip.String = ['Phase image. Max frame: ', num2str(settings.numFrames), ', Test data: ', num2str(numel(settings.loadFiles))];
elseif settings.axisFlag == 3
    handles.tooltip.String = ['Deleting regions (Click twice). Max frame: ', num2str(settings.numFrames), ', Test data: ', num2str(numel(settings.loadFiles))];
elseif settings.axisFlag == 1
    handles.tooltip.String = ['Editing segments. Max frame: ', num2str(settings.numFrames), ', Test data: ', num2str(numel(settings.loadFiles))];
elseif settings.axisFlag == 2
    handles.tooltip.String = ['Editing regions. Max frame: ', num2str(settings.numFrames), ', Test data: ', num2str(numel(settings.loadFiles))];
elseif settings.axisFlag == 0
    handles.tooltip.String = '';
end


% numChildren = numel(viewport.Children);
% for i = 1:numChildren
%     viewport.Children(i).HitTest = 'off';
% end


function saveData()
global settings

try
    data = settings.currentData;
    
    save([settings.saveFolder, settings.loadFiles(settings.frameNumber).name],'-STRUCT','data');
catch ME
    warning(['Could not save changes: ', ME.message]);
end


function addUndo()
global settings

settings.oldData = [settings.currentData, settings.oldData];
if numel(settings.oldData) > settings.maxData
    settings.oldData = settings.oldData(1:settings.maxData);
end

settings.oldFrame = [settings.frameNumber, settings.oldFrame];
if numel(settings.oldFrame) > settings.maxData
    settings.oldFrame = settings.oldFrame(1:settings.maxData);
end


function setWorkingDirectory(directory)
global settings;

if checkIfSave()
    return;
end

settings.frameNumer = 1;
settings.axisFlag = 0;

settings.loadDirectory = [directory,filesep,'xy1',filesep,'seg',filesep];
if exist(settings.loadDirectory, 'dir')
    settings.axisFlag = 4;
    
    settings.numFrames = numel(dir([settings.loadDirectory,'*seg.mat']));
    
    settings.loadFiles = dir([settings.loadDirectory,'*seg*.mat']);
    settings.currentData = load([settings.loadDirectory,settings.loadFiles(settings.frameNumber).name]);

    if exist([settings.loadDirectory, '../../CONST.mat'], 'file')
        settings.CONST = load([settings.loadDirectory, '../../CONST.mat']);
    end
    
    %Make save folder
    try
        settings.saveFolder = [settings.loadDirectory(1:end-1), '_tmp/'];
        if ~exist(settings.saveFolder, 'dir')
            mkdir(settings.saveFolder);
        else
            delete([settings.saveFolder, '*']);
        end
    catch ME
        warning(['Could not back up files: ', ME.message]);
    end
end

%Make backup folder
% try
%     backupFolder = [settings.loadDirectory(1:end-1), '_old/'];
%     if ~exist(backupFolder, 'dir')
%         mkdir(backupFolder);
%     end
% 
%     copyfile(settings.loadDirectory, backupFolder)
% catch ME
%     warning(['Could not back up files: ', ME.message]);
% end



% --- Executes on mouse press over axes background.
function imageButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to viewport (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

if settings.axisFlag == 1 || settings.axisFlag == 2
    FLAGS.im_flag = settings.axisFlag;
    FLAGS.S_flag = 0;
    FLAGS.t_flag = 0;
    
    addUndo();
    [settings.currentData, list] = updateTrainingImage(settings.currentData, FLAGS, eventdata.IntersectionPoint(1:2));
    saveData();
    
    if settings.axisFlag == 1
        if numel(list) > 0
            settings.segmentsDirty = 1;
        end
    else
        settings.segmentsDirty = 0;
    end
elseif settings.axisFlag == 3
    if numel(settings.firstPosition) == 0
        settings.firstPosition = eventdata.IntersectionPoint;
    else
        plot(eventdata.IntersectionPoint(1), eventdata.IntersectionPoint(2), 'w+','MarkerSize', 30)
        
        drawnow;
        
        addUndo();
        settings.currentData = killRegionsGUI(settings.currentData, settings.CONST, settings.firstPosition, eventdata.IntersectionPoint(1:2));
        saveData();
        
        settings.firstPosition = [];
    end
end

updateUI(settings.handles);



function loadData(frameNumber)
global settings;

if exist([settings.saveFolder,settings.loadFiles(settings.frameNumber).name], 'file')
    settings.currentData = load([settings.saveFolder,settings.loadFiles(settings.frameNumber).name]);
else
    settings.currentData = load([settings.loadDirectory,settings.loadFiles(settings.frameNumber).name]);
end


function shouldCancel = checkIfSave()
global settings;

shouldCancel = 0;

if exist(settings.saveFolder, 'dir')
    if numel(dir(settings.saveFolder)) > 2
        answer = questdlg('You have unsaved changes.', 'Save changes?', 'Save', 'Ignore', 'Cancel', 'Save');
        
        if strcmp(answer, 'Save')
            saveData_Callback();
        elseif strcmp(answer, 'Cancel')
            shouldCancel = 1;
            
            return;
        end
    end
    
    delete([settings.saveFolder, '*']);
    rmdir(settings.saveFolder);
end





function frameNumber_Callback(hObject, eventdata, handles)
% hObject    handle to frameNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frameNumber as text
%        str2double(get(hObject,'String')) returns contents of frameNumber as a double
global settings;

settings.frameNumber = str2num(handles.frameNumber.String);
settings.frameNumber = max(1, min(settings.frameNumber, numel(settings.loadFiles)));

loadData(settings.frameNumber);

updateUI(handles);


% --- Executes during object creation, after setting all properties.
function frameNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frameNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in phase.
function phase_Callback(hObject, eventdata, handles)
% hObject    handle to phase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

settings.axisFlag = 4;

updateUI(handles);


% --- Executes on button press in saveData.
function saveData_Callback(hObject, eventdata, handles)
% hObject    handle to saveData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

try
    if numel(dir(settings.saveFolder)) > 2
        movefile([settings.saveFolder, '*'], settings.loadDirectory)
    end
catch ME
    warning(['Could not back up files: ', ME.message]);
end


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
checkIfSave();
