function varargout = trainingGui(varargin)
% modifyConstValuesGUI : gui to train for region and segment scores.
%
% Copyright (C) 2016 Wiggins Lab
% Written by Connor Brennan and Stella Styliandou.
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
% Last Modified by GUIDE v2.5 06-Jul-2016 12:38:17

% Begin initialization code - DO NOT EDIT

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
global settings_train;

handles.output = hObject;
set(handles.figure1, 'units', 'normalized', 'position', [0.1 0.1 0.8 0.8])
handles.directory.String = pwd;

settings_train.trainFun = @neuralNetTrain; % options : @ trainLasso, @trainTree, @neuralNetTrain
settings_train.axisFlag = 4;
settings_train.frameNumber = 1;
settings_train.loadFiles = [];
settings_train.loadDirectory = [];
settings_train.currentDirectory = [];
settings_train.currentData = [];
settings_train.handles = handles;
settings_train.oldData = [];
settings_train.oldFrame = [];
settings_train.maxData = 10;
settings_train.firstPosition = [];
settings_train.errorHandle = [];
settings_train.numFrames = 0;
settings_train.saveFolder = '';
settings_train.dataSegmented = 0;
settings_train.CONST = [];
settings_train.nameCONST = 'none';
settings_train.frameSkip = 1;
settings_train.imagesLoaded = 0;
settings_train.imageDirectory = 0;
settings_train.hasBadRegions = 0;
settings_train.currentIsBad = 0;
settings_train.constantModified = 0;
settings_train.recalculateSegs = 1;
settings_train.segsInfo = @segInfoCurv;
settings_train.numSegsInfo = 25;
settings_train.recalculateRegs = 0;
settings_train.regsInfo = @cellprops3;
settings_train.numRegsInfo = 21;
settings_train.cropTime = 0;
setWorkingDirectory(handles.directory.String, 1, 0);

updateUI(handles);
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = trainingGui_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;

% --- Executes on button press in cut_and_seg.
function cut_and_seg_Callback(hObject, eventdata, handles)
% set constants
global settings_train;

if handles.viewport_train.XLim(2) - handles.viewport_train.XLim(1) > 500 || handles.viewport_train.YLim(2) - handles.viewport_train.YLim(1) > 500
    answer = questdlg('Your training set is very large (Viewport size). This will take a long time. Do you wish to continue?', 'Continue?', 'Yes', 'No', 'No');
    if strcmp(answer, 'No')
        return;
    end
end

trainingFrames = dir([settings_train.imageDirectory, '*c1*.tif']);
numTrainingFrames = numel(trainingFrames);

if numTrainingFrames > 50
    answer = questdlg('Your training set is very large (Number of frames). This will take a long time. Do you wish to continue?', 'Continue?', 'Yes', 'No', 'No');
    if strcmp(answer, 'No')
        return;
    end
end

contents = dir([settings_train.imageDirectory, '*c*.tif']);
originalDir = [settings_train.imageDirectory,filesep,'image_backup',filesep];
mkdir(originalDir);

% move original images to originalDir
for i = 1:numel(contents)
    prevName = [settings_train.imageDirectory, contents(i).name];
    newName = [originalDir, contents(i).name];
    movefile(prevName, newName);
end

% Strip xy positions from bright field images, and move them back to
% imageDirectory
for i = 1:numTrainingFrames
    originalName = [originalDir, trainingFrames(i).name];
    saveName = [settings_train.imageDirectory, strrep(trainingFrames(i).name, 'xy', '')];
    if ~strcmp(originalName,saveName)
        copyfile(originalName, saveName);
    end
end

skip = 1;
clean_flag = 1;
start_end_steps =  [2 3]; % runs only segmentation, no linking
CONSTtemp = settings_train.CONST;
CONSTtemp.parallel.verbose = 1;
CONSTtemp.align.ALIGN_FLAG = 0;
CONSTtemp.seg.OPTI_FLAG = 1;

BatchSuperSeggerOpti(settings_train.imageDirectory, skip, clean_flag, CONSTtemp, start_end_steps, 1);

% make a backup of the seg files
mkdir([settings_train.loadDirectory(1:end-1),'_backup'])
copyfile ([settings_train.loadDirectory,'*seg.mat'],[settings_train.loadDirectory(1:end-1),'_backup'],'f')

settings_train.frameNumber = 1;
setWorkingDirectory(settings_train.loadDirectory(1:end-9));


updateUI(handles);

% --- Executes on button press in try_const.
function try_const_Callback(hObject, eventdata, handles)
global settings_train;

dirname = fixDir(handles.directory.String);
images = dir([dirname,'*.tif']);
if isempty(images) && ~isempty(dir([dirname, filesep, 'raw_im', filesep, '*.tif']))
    dirname = [dirname, filesep, 'raw_im', filesep];
end

tryDifferentConstants(dirname)



function previous_Callback(hObject, eventdata, handles)
global settings_train;
settings_train.frameNumber = settings_train.frameNumber - 1;
settings_train.frameNumber = max(settings_train.frameNumber, 1);
loadData(settings_train.frameNumber)
updateUI(handles);


function undo_Callback(hObject, eventdata, handles)
global settings_train;
if numel(settings_train.oldData) > 0
    settings_train.currentData = settings_train.oldData(1);
    settings_train.frameNumber = settings_train.oldFrame(1);
    
    if numel(settings_train.oldData) > 1
        settings_train.oldData = settings_train.oldData(2:end);
        settings_train.oldFrame = settings_train.oldFrame(2:end);
    else
        settings_train.oldData = [];
        settings_train.oldFrame = [];
    end
    updateUI(handles);
    saveData();
else
    dispError('Reached undo limit');
end

function dispError(message)
global settings_train;
if ~isempty(settings_train.errorHandle)
    delete(settings_train.errorHandle)
end
settings_train.errorHandle = errordlg(message);

function del_areas_Callback(hObject, eventdata, handles)
global settings_train;
if  hObject.Value
    if settings_train.dataSegmented
        settings_train.cropTime = 1;
        settings_train.firstPosition = [];
        updateUI(handles);
        hObject.Value
    else
        warning(['Plese segment files first']);
    end
else
    settings_train.cropTime = 0;
end

function del_reg_Callback(hObject, eventdata, handles)
global settings_train
if settings_train.dataSegmented
    settings_train.axisFlag = 6;
    settings_train.firstPosition = [];
    updateUI(handles);
else
    warning(['Plese segment files first']);
end

function train_segs_Callback(hObject, eventdata, handles)
global settings_train;
if isempty(settings_train.CONST)
    dispError('You must load a CONST file to create bad regions')
    return;
end
set(handles.figure1,'Pointer','watch');
h = msgbox('Training segments, this will take a bit.' );
handles.tooltip.String = 'Training segments... Please wait.';
drawnow;
saveData_Callback();

% hack to put a new segm info calculation - change your pointer
settings_train.CONST.seg.segScoreInfo = settings_train.segsInfo;
settings_train.CONST.superSeggerOpti.NUM_INFO = settings_train.numSegsInfo;

disp('loading the segments'' data');
[Xsegs,Ysegs] = getInfoScores (settings_train.loadDirectory,'segs',...
    settings_train.recalculateSegs,settings_train.CONST);
save([settings_train.currentDirectory,filesep,'segs_training_data'],'Xsegs','Ysegs');
disp('training the segments ..');
[settings_train.CONST.superSeggerOpti.A,...
    settings_train.CONST.seg.segmentScoreFun] = settings_train.trainFun (Xsegs, Ysegs);
settings_train.constantModified = 1;

% update scores and save data files again
disp('updating the segments'' raw scores with the new coefficients..');
updateScores(settings_train.loadDirectory,'segs', ...
    settings_train.CONST.superSeggerOpti.A, settings_train.CONST.seg.segmentScoreFun);
set(handles.figure1,'Pointer','arrow');
try
    close(h);
catch
end

updateUI(handles);


function bad_regs_Callback(hObject, eventdata, handles)
global settings_train;
if settings_train.dataSegmented
    if settings_train.hasBadRegions
        answer = questdlg('Are you sure you want to remove bad region frames?.', 'Clear bad regions?', 'Yes', 'No', 'No');
        if strcmp(answer, 'No')
            return;
        end
        delete([settings_train.loadDirectory, '*seg_*_mod.mat']);
    else
        handles.tooltip.String = 'Adding bad regions, please wait.';
        drawnow;
        makeBadRegions( settings_train.loadDirectory, settings_train.CONST)
        settings_train.numFrames = numel(dir([settings_train.loadDirectory,'*seg.mat']));
        settings_train.loadFiles = dir([settings_train.loadDirectory,'*seg*.mat']);
        loadData(settings_train.frameNumber);
    end
    
    setWorkingDirectory(handles.directory.String, 0, 0);
    updateUI(handles);
else
    dispError('You must load a CONST file to create bad regions')
end



function train_regs_Callback(hObject, eventdata, handles)
global settings_train;
if isempty(settings_train.CONST)
    dispError('You must load a CONST file to create bad regions')
    return;
end

if ~settings_train.hasBadRegions
    answer = questdlg(...
        ['You have not added bad regions. Do you wish to continue?'], ...
        'Continue?', 'Yes', 'No', 'No');
    if strcmp(answer, 'No')
        return;
    end
end
set(handles.figure1,'Pointer','watch');
h = msgbox('Training regions, this will take a bit.' );
handles.tooltip.String = 'Training regions... Please wait.';

drawnow;
saveData_Callback();
settings_train.CONST.regionScoreFun.props = settings_train.regsInfo;
settings_train.CONST.regionScoreFun.NUM_INFO = settings_train.numRegsInfo;
[Xregs,Yregs] = getInfoScores (settings_train.loadDirectory,'regs',...
    settings_train.recalculateRegs, settings_train.CONST);
save([settings_train.currentDirectory,filesep,'regs_training_data'],'Xregs','Yregs');
[settings_train.CONST.regionScoreFun.E,...
    settings_train.CONST.regionScoreFun.fun] = settings_train.trainFun (Xregs, Yregs);

settings_train.constantModified = 1;

% 7) Calculates new scores for regions
disp ('Calculating regions'' scores with new coefficients...');
updateScores(settings_train.loadDirectory,'regs', ...
    settings_train.CONST.regionScoreFun.E, settings_train.CONST.regionScoreFun.fun);

try
    close(h);
catch
end

set(handles.figure1,'Pointer','arrow');
loadData(settings_train.frameNumber);
updateUI(handles);

function directory_Callback(hObject, eventdata, handles)
setWorkingDirectory(handles.directory.String);
updateUI(handles);

% --- Executes during object creation, after setting all properties.
function directory_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in save.
function save_Callback(hObject, eventdata, handles)
global settings_train;
CONST = settings_train.CONST;
[~, ~, constantsPath] = getConstantsList();
[FileName,PathName] = uiputfile('newCONST.mat', 'Save CONST file', [constantsPath, 'newConst']);
if ~isempty(strfind(FileName, '.'))
    FileName = FileName(1:(max(strfind(FileName, '.')) - 1));
end

if FileName ~= 0
    save([PathName, FileName, '.mat'],'-STRUCT','CONST');
    
    settings_train.constantModified = 0;
    
    if exist('hObject', 'var') && ~isempty(hObject)
        updateUI(handles);
    end
end

function image_folder_ClickedCallback(hObject, eventdata, handles)
newDir = uigetdir;
if newDir ~= 0
    handles.directory.String = newDir;
    setWorkingDirectory(handles.directory.String);
    updateUI(handles);
end

% --- Executes on button press in next.
function next_Callback(hObject, eventdata, handles)
global settings_train;
settings_train.frameNumber = settings_train.frameNumber + 1;
settings_train.frameNumber = min(settings_train.frameNumber, numel(settings_train.loadFiles));
loadData(settings_train.frameNumber)
updateUI(handles);


function updateUI(handles)
global settings_train;
set(gca,'xcolor',get(gcf,'color'));
set(gca,'ycolor',get(gcf,'color'));
set(gca,'ytick',[]);
set(gca,'xtick',[]);
handles.currentConstants.String = ['Current: ', settings_train.nameCONST];

firstFrame = 0;
if numel(handles.viewport_train.Children) == 0
    firstFrame = 1;
end

while numel(handles.viewport_train.Children) > 0
    delete(handles.viewport_train.Children(1))
end

if settings_train.dataSegmented
    if settings_train.axisFlag == 1 || settings_train.axisFlag == 2
        % 1 for segments view, 2 for phase view.
        FLAGS.im_flag = settings_train.axisFlag;
        FLAGS.S_flag = settings_train.handles.show_score.Value;
        FLAGS.index_score = str2num(settings_train.handles.score_txt.String);
        FLAGS.t_flag = 0;
        showSegRuleGUI(settings_train.currentData, FLAGS, handles.viewport_train);
        if numel(handles.viewport_train.Children) > 0
            set(handles.viewport_train.Children(1),'ButtonDownFcn',{@imageButtonDownFcn,handles});
        end
        
    elseif settings_train.axisFlag == 4
        % showing phase image
        axes(handles.viewport_train);
        imshow(settings_train.currentData.phase, []);
    elseif settings_train.axisFlag == 5
        % mask image
        maskFigure()
    elseif settings_train.axisFlag == 6
        % deleting regions
        maskFigure()
        if numel(handles.viewport_train.Children) > 0
            set(handles.viewport_train.Children(1),'ButtonDownFcn',{@imageButtonDownFcn,handles});
        end
        
        if numel(settings_train.firstPosition) > 0
            hold on;
            plot( settings_train.firstPosition(1), settings_train.firstPosition(2), 'w+','MarkerSize', 30)
        end
    end
elseif settings_train.imagesLoaded
    axes(handles.viewport_train);
    imshow(settings_train.currentData, []);
end

if settings_train.cropTime
    % deleting areas in square
    if numel(handles.viewport_train.Children) > 0
        set(handles.viewport_train.Children(1),'ButtonDownFcn',{@imageButtonDownFcn,handles});
    end
    
    if numel(settings_train.firstPosition) > 0
        hold on;
        plot( settings_train.firstPosition(1), settings_train.firstPosition(2), 'w+','MarkerSize', 30)
    end
end

handles.regions_radio.Value = 0;
handles.phase_radio.Value = 0;
handles.segs_radio.Value = 0;
handles.mask_radio.Value = 0;
if settings_train.axisFlag == 5 ||  settings_train.axisFlag == 6
    handles.mask_radio.Value = 1;
elseif settings_train.axisFlag == 4
    handles.phase_radio.Value = 1;
elseif settings_train.axisFlag == 2
    handles.regions_radio.Value = 1;
elseif settings_train.axisFlag == 1
    handles.segs_radio.Value = 1;
end

if firstFrame
    axis tight;
end
hold on;

if settings_train.imagesLoaded == 1 || settings_train.dataSegmented == 1
    handles.frameNumber.Visible = 'on';
    handles.frame_text.Visible = 'on';
    handles.frameNumber.String = num2str(settings_train.frameNumber);
else
    handles.frameNumber.Visible = 'off';
    handles.frame_text.Visible = 'off';
    if numel(handles.viewport_train.Children) > 0
        set(handles.viewport_train.Children(1),'Visible', 'off');
    end
end

if settings_train.currentIsBad
    badString = ' "Bad regions"';
else
    badString = '';
end

if settings_train.axisFlag == 5
    handles.tooltip.String = ['Mask.', badString, ' Num frames: ', num2str(settings_train.numFrames), ', Test data: ', num2str(numel(settings_train.loadFiles))];
elseif settings_train.axisFlag == 4
    handles.tooltip.String = ['Phase image.', badString, ' Num frames: ', num2str(settings_train.numFrames), ', Test data: ', num2str(numel(settings_train.loadFiles))];
elseif settings_train.axisFlag == 3
    handles.tooltip.String = ['Click to the two corners to delete the regions inside a square', badString, ' Num frames: ', num2str(settings_train.numFrames), ', Test data: ', num2str(numel(settings_train.loadFiles))];
elseif settings_train.axisFlag == 1
    handles.tooltip.String = ['Click to toggle segments.', badString, ' Num frames: ', num2str(settings_train.numFrames), ', Test data: ', num2str(numel(settings_train.loadFiles))];
elseif settings_train.axisFlag == 2
    handles.tooltip.String = ['Click to toggle regions.', badString, ' Num frames: ', num2str(settings_train.numFrames), ', Test data: ', num2str(numel(settings_train.loadFiles))];
elseif settings_train.imagesLoaded == 1
    handles.tooltip.String = ['Phase image. Zoom in to the part of the image you want to train on.', badString, ' Num frames: ', num2str(settings_train.numFrames)];
elseif settings_train.axisFlag == 0
    handles.tooltip.String = 'Load a file with images or segmented files.';
end

handles.currentConstants.String = ['Current: ', settings_train.nameCONST];
handles.frameSkip.String = num2str(settings_train.frameSkip);
handles.directory.String = settings_train.currentDirectory;
numTrainingFrames = floor(numel(dir([settings_train.imageDirectory, '*c1*.tif'])) / settings_train.frameSkip);
handles.totalFrames.String = ['Total frames: ', num2str(numTrainingFrames), ' / ', num2str(numel(dir([settings_train.imageDirectory, '*c1*.tif'])))];

if numel(settings_train.oldData) > 0
    makeActive(handles.undo);
else
    makeInactive(handles.undo);
end

if settings_train.hasBadRegions
    handles.bad_regs.String = 'Clear bad regions';
else
    handles.bad_regs.String = 'Create bad regions';
end

if settings_train.constantModified
    makeActive(handles.save);
else
    makeInactive(handles.save);
end

if exist(settings_train.saveFolder, 'dir') && numel(dir(settings_train.saveFolder)) > 2
    makeActive(handles.saveData);
else
    makeInactive(handles.saveData);
end

if settings_train.imagesLoaded
    makeActive(handles.try_const);
    makeActive(handles.makeData);
else
    makeInactive(handles.try_const);
    makeInactive(handles.makeData);
end

if settings_train.imagesLoaded || settings_train.dataSegmented == 1
    makeActive(handles.previous);
    makeActive(handles.next);
else
    makeInactive(handles.previous);
    makeInactive(handles.next);
end

% No CONST file selected
if isempty(settings_train.CONST)
    makeInactive(handles.cut_and_seg);
else
    makeActive(handles.cut_and_seg);
end

if settings_train.dataSegmented == 0
    handles.train_actions.Visible = 'off';
    handles.seg_actions.Visible = 'on';
    handles.cut_and_seg.Visible = 'on';
else
    handles.train_actions.Visible = 'on';
    handles.seg_actions.Visible = 'off';
    handles.cut_and_seg.Visible = 'off';
end


function maskFigure()
global settings_train;
cell_mask = settings_train.currentData.mask_cell;
cc = bwconncomp(cell_mask, 4);
labeled = labelmatrix(cc);
RGB_label = label2rgb(labeled,'lines',[0 0 0]);%,'shuffle');
imshow(RGB_label);


function saveData()
global settings_train
try
    data = settings_train.currentData;
    save([settings_train.saveFolder, settings_train.loadFiles(settings_train.frameNumber).name],'-STRUCT','data');
catch ME
    warning(['Could not save changes: ', ME.message]);
end


function addUndo()
global settings_train
try
    settings_train.oldData = [settings_train.currentData(1), settings_train.oldData(1)];
catch
    settings_train.oldData = [settings_train.currentData(1)];
end
if numel(settings_train.oldData) > settings_train.maxData
    settings_train.oldData = settings_train.oldData(1:settings_train.maxData);
end

settings_train.oldFrame = [settings_train.frameNumber, settings_train.oldFrame];
if numel(settings_train.oldFrame) > settings_train.maxData
    settings_train.oldFrame = settings_train.oldFrame(1:settings_train.maxData);
end


function setWorkingDirectory(directory, clearCONST, checkSave)
global settings_train;
if ~exist('checkSave') || isempty(checkSave)
    checkSave = 1;
end

if checkSave == 1 && checkIfSave()
    return;
end

if ~exist('clearCONST') || isempty(clearCONST)
    clearCONST = 1;
end

settings_train.frameNumber = 1;
settings_train.axisFlag = 0;
settings_train.dataSegmented = 0;
settings_train.loadDirectory = [];

%Is in seg folder
settings_train.currentDirectory = [directory,filesep];
settings_train.currentDirectory = settings_train.currentDirectory(1:(max(regexp(settings_train.currentDirectory, [filesep, '*$']))));
isSegFolder = numel(dir([directory,filesep,'*seg.mat'])) > 0;


if isSegFolder
    settings_train.loadDirectory = [directory,filesep];
else
    xyPositions = dir([directory,filesep,'xy*']);
    if numel(xyPositions) > 0
        settings_train.loadDirectory = [directory,filesep,xyPositions(1).name,filesep,'seg',filesep];
        settings_train.currentDirectory = settings_train.loadDirectory(1:end-9);
    else
        settings_train.loadDirectory = [directory,filesep,'xy1/seg/'];
    end
end

hasCONST = ~isSegFolder && exist([settings_train.loadDirectory, '..', filesep, '..', filesep, 'CONST.mat'], 'file');
if clearCONST == 1 || hasCONST == 1
    settings_train.CONST = [];
    settings_train.nameCONST = 'none';
    settings_train.constantModified = 0;
    if hasCONST
        settings_train.CONST = loadConstants([settings_train.loadDirectory, '..', filesep, '..', filesep, 'CONST.mat'], 0, 0);
        settings_train.nameCONST = 'local';
    end
end

settings_train.imagesLoaded = 0;
settings_train.imageDirectory = [];
if numel(dir([settings_train.loadDirectory(1:end-8), filesep, '*.tif'])) > 0
    settings_train.imagesLoaded = 1;
    settings_train.imageDirectory = settings_train.loadDirectory(1:end-8);
elseif numel(dir([settings_train.loadDirectory(1:end-8), filesep, 'raw_im', filesep, '*.tif'])) > 0
    settings_train.imagesLoaded = 1;
    settings_train.imageDirectory = [settings_train.loadDirectory(1:end-8), filesep, 'raw_im', filesep];
end

if exist(settings_train.loadDirectory, 'dir')
    settings_train.numFrames = numel(dir([settings_train.loadDirectory,'*seg.mat']));
    
    % get files with right names
    loadFiles = dir([settings_train.loadDirectory,'*seg*.mat']);
    filenames = {loadFiles.name}';
    pass_names= regexp(filenames,'seg.mat|seg_\d+_mod.mat');
    pass_flag = ~cellfun('isempty',pass_names);
    loadFiles(~pass_flag) = [];
    settings_train.loadFiles = loadFiles;
    
    if settings_train.numFrames > 0
        settings_train.dataSegmented = 1;
        settings_train.axisFlag = 4;
        loadData(settings_train.frameNumber);        
        settings_train.hasBadRegions = 0;
        if settings_train.numFrames < numel(settings_train.loadFiles)
            settings_train.hasBadRegions = 1;
        end
        
        if isempty(settings_train.CONST)
            loadConstants_Callback([], [], settings_train.handles)
        end
        
        %Make save folder
        try
            settings_train.saveFolder = [settings_train.loadDirectory(1:end-1), '_tmp', filesep];
            if ~exist(settings_train.saveFolder, 'dir')
                mkdir(settings_train.saveFolder);
            else
                delete([settings_train.saveFolder, '*']);
            end
        catch ME
            warning(['Could not back up files: ', ME.message]);
        end
    end
elseif settings_train.imagesLoaded
    settings_train.numFrames = numel(dir([settings_train.imageDirectory,'*.tif']));
    settings_train.loadFiles = dir([settings_train.imageDirectory,'*.tif']);
    loadData(settings_train.frameNumber);
else
    settings_train.numFrames = 0;
    settings_train.loadFiles = [];
end

%Clear viewport_train
if isfield(settings_train.handles,'viewport_train') && isvalid(settings_train.handles.viewport_train)
    while numel(settings_train.handles.viewport_train.Children) > 0
        delete(settings_train.handles.viewport_train.Children(1))
    end
end

% --- Executes on mouse press over axes background.
function imageButtonDownFcn(hObject, eventdata, handles)
global settings_train;
if settings_train.cropTime
    if numel(settings_train.firstPosition) == 0
        settings_train.firstPosition = eventdata.IntersectionPoint;
    else
        plot(eventdata.IntersectionPoint(1), eventdata.IntersectionPoint(2), 'w+','MarkerSize', 30)
        drawnow;
        addUndo();
        settings_train.currentData = killRegionsGUI(settings_train.currentData, settings_train.CONST, settings_train.firstPosition, eventdata.IntersectionPoint(1:2));
        saveData();
        settings_train.firstPosition = [];
    end
elseif settings_train.axisFlag == 1 || settings_train.axisFlag == 2
    FLAGS.im_flag = settings_train.axisFlag;
    FLAGS.S_flag = 0;
    FLAGS.t_flag = 0;
       
    
    addUndo();
    [settings_train.currentData, list] = updateTrainingImageTrain(settings_train.currentData, FLAGS, eventdata.IntersectionPoint(1:2));
    if settings_train.axisFlag == 1 && numel(list) > 0
        settings_train.currentData = intMakeRegs( settings_train.currentData, settings_train.CONST, [], [] );
    end
    saveData();
elseif settings_train.axisFlag == 6
    plot(eventdata.IntersectionPoint(1), eventdata.IntersectionPoint(2), 'w+','MarkerSize', 30)
    drawnow;
    addUndo();
    settings_train.currentData = killRegionsGUI(settings_train.currentData, settings_train.CONST, [eventdata.IntersectionPoint(1),eventdata.IntersectionPoint(2)],[]);
    saveData();
end

updateUI(settings_train.handles);

function loadData(frameNumber)
global settings_train;

if settings_train.dataSegmented
    if exist([settings_train.saveFolder,settings_train.loadFiles(frameNumber).name], 'file')
        settings_train.currentData = load([settings_train.saveFolder,settings_train.loadFiles(frameNumber).name]);
    else
        settings_train.currentData = load([settings_train.loadDirectory,settings_train.loadFiles(frameNumber).name]);
    end
else
    settings_train.currentData = intImRead([settings_train.imageDirectory,settings_train.loadFiles(frameNumber).name]);
end
settings_train.currentIsBad = strfind(settings_train.loadFiles(frameNumber).name, '_mod.mat');

function shouldCancel = checkIfSave()
global settings_train;
shouldCancel = 0;
if exist(settings_train.saveFolder, 'dir')
    if numel(dir(settings_train.saveFolder)) > 2
        answer = questdlg('You have unsaved changes to the data.', 'Save data changes?', 'Save', 'Ignore', 'Cancel', 'Save');
        if strcmp(answer, 'Save')
            saveData_Callback();
        elseif strcmp(answer, 'Cancel')
            shouldCancel = 1;
            
            return;
        end
    end
    delete([settings_train.saveFolder, '*']);
    rmdir(settings_train.saveFolder);
end

if settings_train.constantModified == 1
    answer = questdlg('You have unsaved changes to the constants.', 'Save constants changes?', 'Save', 'Ignore', 'Cancel', 'Save');
    if strcmp(answer, 'Save')
        save_Callback();
    elseif strcmp(answer, 'Cancel')
        shouldCancel = 1;
        
        return;
    end
end

function frameNumber_Callback(hObject, eventdata, handles)
global settings_train;
settings_train.frameNumber = str2num(handles.frameNumber.String);
settings_train.frameNumber = max(1, min(settings_train.frameNumber, numel(settings_train.loadFiles)));
loadData(settings_train.frameNumber);
updateUI(handles);

% --- Executes during object creation, after setting all properties.
function frameNumber_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function saveData_Callback(hObject, eventdata, handles)
global settings_train;
try
    if numel(dir(settings_train.saveFolder)) > 2
        movefile([settings_train.saveFolder, '*'], settings_train.loadDirectory)
    end
catch ME
    warning(['Could not back up files: ', ME.message]);
end

if exist('hObject', 'var') && ~isempty(hObject)
    updateUI(handles);
end


function figure1_DeleteFcn(hObject, eventdata, handles)
checkIfSave();

function modifyConstants_Callback(hObject, eventdata, handles)
modifyConstValuesGUI();

function makeData_Callback(hObject, eventdata, handles)
global settings_train;

xSize = handles.viewport_train.XLim(2) - handles.viewport_train.XLim(1);
ySize = handles.viewport_train.YLim(2) - handles.viewport_train.YLim(1);
if xSize > 800 || ySize > 800
    answer = questdlg(['Your training set is very large (Viewport size: ', num2str(ySize), ', ', num2str(xSize), '). This will take a long time. Do you wish to continue?'], 'Continue?', 'Yes', 'No', 'No');
    if strcmp(answer, 'No')
        return;
    end
end

numTrainingFrames = floor((numel(dir([settings_train.imageDirectory, '*c1*.tif']))) / settings_train.frameSkip);
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

maxFrames = numel(dir([settings_train.imageDirectory, '*c1*.tif']));
newDir = uigetdir([settings_train.imageDirectory, '..', filesep], ...
    'Select empty folder for training data');

if newDir ~= 0
    if ~exist(newDir, 'dir')
        mkdir(newDir);
    else
        if numel(dir(newDir)) > 2
            dispError('You must select an empty directory.');
            return;
        end
    end
    
    cropX = ceil(handles.viewport_train.XLim(1):handles.viewport_train.XLim(2) - 1);
    cropY = ceil(handles.viewport_train.YLim(1):handles.viewport_train.YLim(2) - 1);
    
    for i = 1:settings_train.frameSkip:maxFrames
        tempImage = intImRead([settings_train.imageDirectory,settings_train.loadFiles(i).name]);
        saveName = [newDir, filesep, settings_train.loadFiles(i).name];
        imwrite( tempImage(cropY, cropX), saveName, 'TIFF' );
    end
    
    setWorkingDirectory([newDir, filesep], 0);
    updateUI(handles);
end


function frameSkip_Callback(hObject, eventdata, handles)
global settings_train;
settings_train.frameSkip = str2num(handles.frameSkip.String);
updateUI(handles);

function frameSkip_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function loadConstants_Callback(hObject, eventdata, handles)
global settings_train;
[~, ~, constantsPath] = getConstantsList();
[FileName,PathName] = uigetfile('.mat', 'Load CONST file', constantsPath);
if FileName ~= 0
    settings_train.CONST = loadConstants([PathName, FileName],0,0);
    settings_train.nameCONST = settings_train.CONST.ResFlag;
    settings_train.nameCONST = settings_train.nameCONST((max(strfind(settings_train.nameCONST, filesep)) + 1):end);
    updateUI(handles);
end


function makeActive(button)
button.Enable = 'on';
button.ForegroundColor = [0, 0, 0];

function makeInactive(button)
button.Enable = 'inactive';
button.ForegroundColor = [.5, .5, .5];

function makeGoodRegions_Callback(hObject, eventdata, handles)
global settings_train;
settings_train.axisFlag = 2;
addUndo();
settings_train.currentData.regs.score = ones( settings_train.currentData.regs.num_regs, 1 );
saveData();
updateUI(handles);

function phase_radio_Callback(hObject, eventdata, handles)

global settings_train
if get(hObject,'Value')
    settings_train.axisFlag = 4;
    handles.regions_radio.Value = 0;
    handles.segs_radio.Value = 0;
    handles.mask_radio.Value = 0;
end
updateUI(handles);

function regions_radio_Callback(hObject, eventdata, handles)
global settings_train
if get(hObject,'Value')
    settings_train.axisFlag = 2;
    handles.phase_radio.Value = 0;
    handles.segs_radio.Value = 0;
    handles.mask_radio.Value = 0;
    if isempty(settings_train.CONST)
        loadConstants_Callback([], [], settings_train.handles)
    end
    if isempty(settings_train.CONST)
        questdlg('You must load a CONST file to update the regions', 'Error', 'Okay', 'Okay');
    end
end
updateUI(handles);

% --- Executes on button press in segs_radio.
function segs_radio_Callback(hObject, eventdata, handles)
global settings_train
if get(hObject,'Value')
    settings_train.axisFlag = 1;
    handles.mask_radio.Value = 0;
    handles.regions_radio.Value = 0;
    handles.phase_radio.Value = 0;
end
updateUI(handles);

function frame_text_CreateFcn(hObject, eventdata, handles)

function mask_radio_Callback(hObject, eventdata, handles)
global settings_train
if get(hObject,'Value')
    settings_train.axisFlag = 5;
    handles.regions_radio.Value = 0;
    handles.segs_radio.Value = 0;
    handles.phase_radio.Value = 0;
end
updateUI(handles);

function crop_Callback(hObject, eventdata, handles)


function save_cut_Callback(hObject, eventdata, handles)
global settings_train;

xSize = handles.viewport_train.XLim(2) - handles.viewport_train.XLim(1);
ySize = handles.viewport_train.YLim(2) - handles.viewport_train.YLim(1);
cropX = ceil(handles.viewport_train.XLim(1):handles.viewport_train.XLim(2) - 1);
cropY = ceil(handles.viewport_train.YLim(1):handles.viewport_train.YLim(2) - 1);
i = settings_train.frameNumber;
filename =[ settings_train.imageDirectory,filesep,settings_train.loadFiles(i).name];

tempImage = intImRead([filename]);
saveName = [filename];
imwrite( tempImage(cropY, cropX), saveName, 'TIFF' );

function figure1_KeyPressFcn(hObject, eventdata, handles)
if strcmpi(eventdata.Key,'leftarrow')
    previous_Callback(hObject, eventdata, handles);
end
if strcmpi(eventdata.Key,'rightarrow')
    next_Callback(hObject, eventdata, handles);
end

% --------------------------------------------------------------------
function debug_ClickedCallback(hObject, eventdata, handles)
global settings_train;
keyboard;

% --- Executes on button press in show_score.
function show_score_Callback(hObject, eventdata, handles)
updateUI(handles);

function score_txt_Callback(hObject, eventdata, handles)
% Shows value for one of the 19 region parameters that enter the
% model.
updateUI(handles);

% --- Executes during object creation, after setting all properties.
function score_txt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
