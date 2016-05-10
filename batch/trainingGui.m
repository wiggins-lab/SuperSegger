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

% Last Modified by GUIDE v2.5 09-May-2016 23:08:14

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
settings.dataSegmented = 0;
settings.CONST = [];
settings.nameCONST = 'none';
settings.frameSkip = 5;
settings.imagesLoaded = 0;
settings.imageDirectory = 0;
settings.hasBadRegions = 0;
settings.currentIsBad = 0;

setWorkingDirectory(handles.directory.String, 1, 0);

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
global settings;

if handles.viewport.XLim(2) - handles.viewport.XLim(1) > 500 || handles.viewport.YLim(2) - handles.viewport.YLim(1) > 500
    answer = questdlg('Your training set is very large (Viewport size). This will take a long time. Do you wish to continue?', 'Continue?', 'Yes', 'No', 'No');
    
    if strcmp(answer, 'No')
        return;
    end
end



trainingFrames = dir([settings.imageDirectory, '*c1*.tif']);
numTrainingFrames = numel(trainingFrames);
% if numTrainingFrames < 5
%     answer = questdlg('Your training set is very small (Number of frames). This will be hard to train well. Do you wish to continue?', 'Continue?', 'Yes', 'No', 'No');
%
%     if strcmp(answer, 'No')
%         return;
%     end
% end

if numTrainingFrames > 50
    answer = questdlg('Your training set is very large (Number of frames). This will take a long time. Do you wish to continue?', 'Continue?', 'Yes', 'No', 'No');
    
    if strcmp(answer, 'No')
        return;
    end
end

%strip xy positions
for i = 1:numTrainingFrames
    originalName = [settings.imageDirectory, trainingFrames(i).name];
    saveName = [settings.imageDirectory, trainingFrames(i).name];
    saveName = strrep(saveName, 'xy', '');
    if ~strcmp(originalName,saveName)
        movefile(originalName, saveName);
    end
end

skip = 1;
clean_flag = 1;
only_seg = 1; % runs only segmentation, no linking
CONSTtemp = settings.CONST;
CONSTtemp.parallel.verbose = 0;
CONSTtemp.align.ALIGN_FLAG = 0
BatchSuperSeggerOpti(settings.imageDirectory, skip, clean_flag, CONSTtemp, 1, only_seg, 0);

settings.frameNumber = 1;
setWorkingDirectory(settings.loadDirectory(1:end-9));
updateUI(handles);

% --- Executes on button press in try_const.
function try_const_Callback(hObject, eventdata, handles)
% hObject    handle to try_const (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

dirname = fixDir(handles.directory.String);
images = dir([dirname,'*.tif']);

if isempty(images) && ~isempty(dir([dirname,'/raw_im/*.tif']))
    dirname = [dirname, '/raw_im/'];
end

tryDifferentConstantsGUI(dirname, [], ceil([handles.viewport.XLim, handles.viewport.YLim]), settings.frameNumber);




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




% --- Executes on button press in del_areas.
function del_areas_Callback(hObject, eventdata, handles)
% hObject    handle to del_areas (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

if exist([settings.loadDirectory, '../../CONST.mat'], 'file')
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
global settings;

h = msgbox('Training segments, this will take a bit.' );
handles.tooltip.String = 'Training segments... Please wait.';
drawnow;

saveData_Callback();

[Xsegs,Ysegs] = getInfoScores (settings.loadDirectory,'segs');
[settings.CONST.superSeggerOpti.A] = neuralNetTrain (Xsegs,Ysegs);

% update scores and save data files again
updateScores(settings.loadDirectory,'segs', settings.CONST.superSeggerOpti.A, settings.CONST.regionScoreFun.fun);

try
    close(h);
catch
end

updateUI(handles);



% --- Executes on button press in bad_regs.
function bad_regs_Callback(hObject, eventdata, handles)
% hObject    handle to bad_regs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

if exist([settings.loadDirectory, '../../CONST.mat'], 'file')
    if settings.hasBadRegions
        answer = questdlg('Are you sure you want to remove bad region frames?.', 'Clear bad regions?', 'Yes', 'No', 'No');
        
        if strcmp(answer, 'No')
            return;
        end
        
        delete([settings.loadDirectory, '*seg_*_mod.mat']);
    else
        handles.tooltip.String = 'Adding bad regions, please wait.';
        drawnow;
        
        makeBadRegions( settings.loadDirectory, settings.CONST)
        
        settings.numFrames = numel(dir([settings.loadDirectory,'*seg.mat']));
        
        settings.loadFiles = dir([settings.loadDirectory,'*seg*.mat']);
        loadData(settings.frameNumber);
    end
    
    setWorkingDirectory(handles.directory.String, 0, 0);
    
    updateUI(handles);
end


% --- Executes on button press in train_regs.
function train_regs_Callback(hObject, eventdata, handles)
% hObject    handle to train_regs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

h = msgbox('Training regions, this will take a bit.' );
handles.tooltip.String = 'Training regions... Please wait.';
drawnow;

saveData_Callback();

%settings.CONST.regionScoreFun.props = @cellprops3;
%settings.CONST.regionScoreFun.NUM_INFO = 21;

[Xregs,Yregs] = getInfoScores (settings.loadDirectory,'regs',settings.CONST);
[settings.CONST.regionScoreFun.E] = neuralNetTrain (Xregs,Yregs);

% 7) Calculates new scores for regions
disp ('Calculating regions'' scores with new coefficients...');
updateScores(settings.loadDirectory,'regs', settings.CONST.regionScoreFun.E, settings.CONST.regionScoreFun.fun);

try
    close(h);
catch
end

loadData(settings.frameNumber);

updateUI(handles);







function directory_Callback(hObject, eventdata, handles)
% hObject    handle to directory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of directory as text
%        str2double(get(hObject,'String')) returns contents of directory as a double

setWorkingDirectory(handles.directory.String);
updateUI(handles);


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
global settings;

CONST = settings.CONST;
[~, ~, constantsPath] = getConstantsList();
[FileName,PathName] = uiputfile('newCONST.mat', 'Save CONST file', [constantsPath, 'newConst']);
if ~isempty(strfind(FileName, '.'))
    FileName = FileName(1:(strfind(FileName, '.') - 1))
end

if FileName ~= 0
    save([PathName, FileName, '.mat'],'-STRUCT','CONST');
end


% --------------------------------------------------------------------
function image_folder_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to image_folder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.directory.String = uigetdir;
setWorkingDirectory(handles.directory.String);
updateUI(handles);


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

set(gca,'xcolor',get(gcf,'color'));
set(gca,'ycolor',get(gcf,'color'));
set(gca,'ytick',[]);
set(gca,'xtick',[]);

firstFrame = 0;
if numel(handles.viewport.Children) == 0
    firstFrame = 1;
end

while numel(handles.viewport.Children) > 0
    delete(handles.viewport.Children(1))
end

if settings.dataSegmented
    if settings.axisFlag == 1 || settings.axisFlag == 2
        % 1 for segments view, 2 for phase view.
        FLAGS.im_flag = settings.axisFlag;
        FLAGS.S_flag = 0;
        FLAGS.t_flag = 0;
        
        showSegRuleGUI(settings.currentData, FLAGS, handles.viewport);
        
        if numel(handles.viewport.Children) > 0
            set(handles.viewport.Children(1),'ButtonDownFcn',@imageButtonDownFcn);
        end
    elseif settings.axisFlag == 3
        % deleting regions
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
        % showing phase image
        axes(handles.viewport);
        imshow(settings.currentData.phase, []);
    end
elseif settings.imagesLoaded
    axes(handles.viewport);
    imshow(settings.currentData, []);
end

if firstFrame
    axis tight;
end
hold on;

if settings.imagesLoaded == 1 || settings.dataSegmented == 1
    handles.frameNumber.Visible = 'on';
    handles.frame_text.Visible = 'on';
    handles.frameNumber.String = num2str(settings.frameNumber);
else
    handles.frameNumber.Visible = 'off';
    handles.frame_text.Visible = 'off';
    if numel(handles.viewport.Children) > 0
        set(handles.viewport.Children(1),'Visible', 'off');
    end
end

if settings.currentIsBad
    badString = ' "Bad regions"';
else
    badString = '';
end

if settings.axisFlag == 4
    handles.tooltip.String = ['Phase image.', badString, ' Max frame: ', num2str(settings.numFrames), ', Test data: ', num2str(numel(settings.loadFiles))];
elseif settings.axisFlag == 3
    handles.tooltip.String = ['Click to the two corners to delete the regions inside a square', badString, ' Max frame: ', num2str(settings.numFrames), ', Test data: ', num2str(numel(settings.loadFiles))];
elseif settings.axisFlag == 1
    handles.tooltip.String = ['Click to toggle segments.', badString, ' Max frame: ', num2str(settings.numFrames), ', Test data: ', num2str(numel(settings.loadFiles))];
elseif settings.axisFlag == 2
    handles.tooltip.String = ['Click to toggle regions.', badString, ' Max frame: ', num2str(settings.numFrames), ', Test data: ', num2str(numel(settings.loadFiles))];
elseif settings.imagesLoaded == 1
    handles.tooltip.String = ['Phase image. Zoom in to the part of the image you want to train on.', badString, ' Max frame: ', num2str(settings.numFrames)];
elseif settings.axisFlag == 0
    handles.tooltip.String = 'Load a file with images or segmented files.';
end

handles.currentConstants.String = ['Current: ', settings.nameCONST];
handles.frameSkip.String = num2str(settings.frameSkip);
handles.directory.String = settings.loadDirectory(1:end-9);
numTrainingFrames = floor(numel(dir([settings.imageDirectory, '*c1*.tif'])) / settings.frameSkip);
handles.totalFrames.String = ['Total frames: ', num2str(numTrainingFrames), ' / ', num2str(numel(dir([settings.imageDirectory, '*c1*.tif'])))];

if settings.hasBadRegions
    handles.bad_regs.String = 'Clear bad regions';
else
    handles.bad_regs.String = 'Create bad regions';
end

if settings.imagesLoaded
    makeActive(handles.try_const);
    makeActive(handles.makeData);
else
    makeInactive(handles.try_const);
    makeInactive(handles.makeData);
end

% No CONST file selected
if isempty(settings.CONST)
    makeInactive(handles.cut_and_seg);
else
    makeActive(handles.cut_and_seg);
end

if settings.dataSegmented == 0
    handles.cut_and_seg.Visible = 'on';
    
    handles.diplay_panel.Visible = 'off';
    handles.save_panel.Visible = 'off';
    handles.makeGoodRegions.Visible = 'off';
    handles.phase.Visible = 'off';
    handles.toggle_segs.Visible = 'off';
    handles.toggle_regs.Visible = 'off';
    handles.del_areas.Visible = 'off';
    handles.bad_regs.Visible = 'off';
    handles.train_segs.Visible = 'off';
    handles.train_regs.Visible = 'off';
    handles.save.Visible = 'off';
    handles.saveData.Visible = 'off';
else
    handles.cut_and_seg.Visible = 'off';
    
    handles.diplay_panel.Visible = 'on';
    handles.save_panel.Visible = 'on';
    handles.makeGoodRegions.Visible = 'on';
    handles.phase.Visible = 'on';
    handles.toggle_segs.Visible = 'on';
    handles.toggle_regs.Visible = 'on';
    handles.del_areas.Visible = 'on';
    handles.bad_regs.Visible = 'on';
    handles.train_segs.Visible = 'on';
    handles.train_regs.Visible = 'on';
    handles.save.Visible = 'on';
    handles.saveData.Visible = 'on';
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


function setWorkingDirectory(directory, clearCONST, checkSave)
global settings;

if ~exist('checkSave') || isempty(checkSave)
    checkSave = 1;
end

if checkSave == 1 && checkIfSave()
    return;
end

if ~exist('clearCONST') || isempty(clearCONST)
    clearCONST = 1;
end

settings.frameNumber = 1;
settings.axisFlag = 0;
settings.dataSegmented = 0;

settings.loadDirectory = [directory,filesep,'xy1',filesep,'seg',filesep];

hasCONST = exist([settings.loadDirectory, '../../CONST.mat'], 'file');
if clearCONST == 1 || hasCONST == 1
    settings.CONST = [];
    settings.nameCONST = 'none';
    if hasCONST
        settings.CONST = loadConstantsNN([settings.loadDirectory, '../../CONST.mat'], 0, 0);
        settings.nameCONST = 'local';
    end
end

settings.imagesLoaded = 0;
settings.imageDirectory = [];
if numel(dir([settings.loadDirectory(1:end-8), '/*.tif'])) > 0
    settings.imagesLoaded = 1;
    settings.imageDirectory = settings.loadDirectory(1:end-8);
elseif numel(dir([settings.loadDirectory(1:end-8), '/raw_im/*.tif'])) > 0
    settings.imagesLoaded = 1;
    settings.imageDirectory = [settings.loadDirectory(1:end-8), '/raw_im/'];
end

if exist(settings.loadDirectory, 'dir')
    settings.dataSegmented = 1;
    settings.axisFlag = 4;
    settings.numFrames = numel(dir([settings.loadDirectory,'*seg.mat']));
    settings.loadFiles = dir([settings.loadDirectory,'*seg*.mat']);
    loadData(settings.frameNumber);
    
    settings.hasBadRegions = 0;
    if settings.numFrames < numel(settings.loadFiles)
        settings.hasBadRegions = 1;
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
elseif settings.imagesLoaded
    settings.numFrames = numel(dir([settings.imageDirectory,'*.tif']));
    settings.loadFiles = dir([settings.imageDirectory,'*.tif']);
    loadData(settings.frameNumber);
end

%Clear viewport
if isvalid(settings.handles.viewport)
    while numel(settings.handles.viewport.Children) > 0
        delete(settings.handles.viewport.Children(1))
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

if settings.dataSegmented
    if exist([settings.saveFolder,settings.loadFiles(frameNumber).name], 'file')
        settings.currentData = load([settings.saveFolder,settings.loadFiles(frameNumber).name]);
    else
        settings.currentData = load([settings.loadDirectory,settings.loadFiles(frameNumber).name]);
    end
else
    settings.currentData = imread([settings.imageDirectory,settings.loadFiles(frameNumber).name]);
end

settings.currentIsBad = strfind(settings.loadFiles(frameNumber).name, '_mod');


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


% function getValuesFromConst(handles)
% global settings;
% resValue = get(handles.constants_list,'Value');
% res = handles.constants_list.String{resValue};
% CONST = loadConstantsNN (res,0,0);
% settings.CONST = CONST;


% --- Executes on button press in modifyConstants.
function modifyConstants_Callback(hObject, eventdata, handles)
% hObject    handle to modifyConstants (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

modifyConstValuesGUI();


% --- Executes on button press in makeData.
function makeData_Callback(hObject, eventdata, handles)
% hObject    handle to makeData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

xSize = handles.viewport.XLim(2) - handles.viewport.XLim(1);
ySize = handles.viewport.YLim(2) - handles.viewport.YLim(1);
if xSize > 800 || ySize > 800
    answer = questdlg(['Your training set is very large (Viewport size: ', num2str(ySize), ', ', num2str(xSize), '). This will take a long time. Do you wish to continue?'], 'Continue?', 'Yes', 'No', 'No');
    if strcmp(answer, 'No')
        return;
    end
end

numTrainingFrames = floor((numel(dir([settings.imageDirectory, '*c1*.tif']))) / settings.frameSkip);
if numTrainingFrames < 5
    answer = questdlg('Your training set is very small (Number of frames). This will be hard to train well. Do you wish to continue?', 'Continue?', 'Yes', 'No', 'No');
    if strcmp(answer, 'No')
        return;
    end
end

if numTrainingFrames > 50
    answer = questdlg('Your training set is very large (Number of frames). This will take a long time. Do you wish to continue?', 'Continue?', 'Yes', 'No', 'No');
    if strcmp(answer, 'No')
        return;
    end
end

maxFrames = numel(dir([settings.imageDirectory, '*c1*.tif']));

newDir = uigetdir([settings.imageDirectory, '../'], 'Select empty folder for training data');

if newDir ~= 0
    if ~exist(newDir, 'dir')
        mkdir(newDir);
    else
        if numel(dir(newDir)) > 2
            dispError('You must select an empty directory.');
            return;
        end
    end
    
    cropX = ceil(handles.viewport.XLim(1):handles.viewport.XLim(2) - 1);
    cropY = ceil(handles.viewport.YLim(1):handles.viewport.YLim(2) - 1);
    
    for i = 1:settings.frameSkip:maxFrames
        tempImage = imread([settings.imageDirectory,settings.loadFiles(i).name]);
        saveName = [newDir, '/', settings.loadFiles(i).name];
        imwrite( tempImage(cropY, cropX), saveName, 'TIFF' );
    end
    
    setWorkingDirectory([newDir, '/'], 0);
    
    updateUI(handles);
end


function frameSkip_Callback(hObject, eventdata, handles)
% hObject    handle to frameSkip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of frameSkip as text
%        str2double(get(hObject,'String')) returns contents of frameSkip as a double
global settings;

settings.frameSkip = str2num(handles.frameSkip.String);

updateUI(handles);

% --- Executes during object creation, after setting all properties.
function frameSkip_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frameSkip (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in loadConstants.
function loadConstants_Callback(hObject, eventdata, handles)
% hObject    handle to loadConstants (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

[~, ~, constantsPath] = getConstantsList();
[FileName,PathName] = uigetfile('.mat', 'Load CONST file', constantsPath);
if FileName ~= 0
    settings.CONST = loadConstantsNN([PathName, FileName],0,0);
    settings.nameCONST = settings.CONST.ResFlag;
    settings.nameCONST = settings.nameCONST((max(strfind(settings.nameCONST, '/')) + 1):end);
    
    updateUI(handles);
end


function makeActive(button)
button.Enable = 'on';
button.ForegroundColor = [0, 0, 0];

function makeInactive(button)
button.Enable = 'inactive';
button.ForegroundColor = [.5, .5, .5];


% --- Executes on button press in makeGoodRegions.
function makeGoodRegions_Callback(hObject, eventdata, handles)
% hObject    handle to makeGoodRegions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;

settings.axisFlag = 2;

addUndo();
settings.currentData = intMakeRegs( settings.currentData, settings.CONST, [], 1 );
saveData();

updateUI(handles);


% --- Executes on button press in phase_radio.
function phase_radio_Callback(hObject, eventdata, handles)
% hObject    handle to phase_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of phase_radio
global settings
if get(hObject,'Value')
    handles.regions_radio.Value = 0;
    handles.segs_radio.Value = 0;
    settings.axisFlag = 4;
end
updateUI(handles);

% --- Executes on button press in regions_radio.
function regions_radio_Callback(hObject, eventdata, handles)
% hObject    handle to regions_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of regions_radio
global settings
if get(hObject,'Value')
    handles.phase_radio.Value = 0;
    handles.segs_radio.Value = 0;
    settings.axisFlag = 2;
    
    if settings.segmentsDirty == 1
        settings.currentData = intMakeRegs( settings.currentData, settings.CONST, [], [] );
        settings.segmentsDirty = 0;
    end
    
end
updateUI(handles);

% --- Executes on button press in segs_radio.
function segs_radio_Callback(hObject, eventdata, handles)
% hObject    handle to segs_radio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of segs_radio
global settings
if get(hObject,'Value')
    handles.regions_radio.Value = 0;
    handles.phase_radio.Value = 0;
    settings.axisFlag = 1;
end
updateUI(handles);


% --- Executes during object creation, after setting all properties.
function frame_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to frame_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
