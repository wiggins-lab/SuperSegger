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
global settings;

handles.output = hObject;
set(handles.figure1, 'units', 'normalized', 'position', [0.1 0.1 0.8 0.8])

handles.directory.String = pwd;

settings.trainFun = @neuralNetTrain; % options : @ trainLasso, @trainTree, @neuralNetTrain

settings.axisFlag = 4;
settings.frameNumber = 1;
settings.loadFiles = [];
settings.loadDirectory = [];
settings.currentDirectory = [];
settings.currentData = [];
settings.handles = handles;
settings.oldData = [];
settings.oldFrame = [];
settings.maxData = 10;
settings.firstPosition = [];
settings.errorHandle = [];
settings.numFrames = 0;
settings.saveFolder = '';
settings.dataSegmented = 0;
settings.CONST = [];
settings.nameCONST = 'none';
settings.frameSkip = 1;
settings.imagesLoaded = 0;
settings.imageDirectory = 0;
settings.hasBadRegions = 0;
settings.currentIsBad = 0;
settings.constantModified = 0;
settings.recalculateSegs = 1;
settings.segsInfo = @segInfoCurv;
settings.numSegsInfo = 25;
settings.recalculateRegs = 0;
settings.regsInfo = @cellprops3;
settings.numRegsInfo = 21;

setWorkingDirectory(handles.directory.String, 1, 0);

updateUI(handles);
guidata(hObject, handles);



% --- Outputs from this function are returned to the command line.
function varargout = trainingGui_OutputFcn(hObject, eventdata, handles)
varargout{1} = handles.output;



% --- Executes on button press in cut_and_seg.
function cut_and_seg_Callback(hObject, eventdata, handles)
% set constants
global settings;

if handles.viewport_train.XLim(2) - handles.viewport_train.XLim(1) > 500 || handles.viewport_train.YLim(2) - handles.viewport_train.YLim(1) > 500
    answer = questdlg('Your training set is very large (Viewport size). This will take a long time. Do you wish to continue?', 'Continue?', 'Yes', 'No', 'No');
    if strcmp(answer, 'No')
        return;
    end
end

trainingFrames = dir([settings.imageDirectory, '*c1*.tif']);
numTrainingFrames = numel(trainingFrames);

if numTrainingFrames > 50
    answer = questdlg('Your training set is very large (Number of frames). This will take a long time. Do you wish to continue?', 'Continue?', 'Yes', 'No', 'No');    
    if strcmp(answer, 'No')
        return;
    end
end

%strip xy positions
for i = 1:numTrainingFrames
    originalName = [settings.imageDirectory, trainingFrames(i).name];
    saveName = [settings.imageDirectory, strrep(trainingFrames(i).name, 'xy', '')];
    if ~strcmp(originalName,saveName)
        movefile(originalName, saveName);
    end
end

skip = 1;
clean_flag = 1;
start_end_steps =  [2 3]; % runs only segmentation, no linking
CONSTtemp = settings.CONST;
CONSTtemp.parallel.verbose = 1;
CONSTtemp.align.ALIGN_FLAG = 0;
CONSTtemp.seg.OPTI_FLAG = 1;
BatchSuperSeggerOpti(settings.imageDirectory, skip, clean_flag, CONSTtemp, 1, start_end_steps);
mkdir([settings.loadDirectory(1:end-1),'_backup'])
copyfile ([settings.loadDirectory,'*seg.mat'],[settings.loadDirectory(1:end-1),'_backup'],'f')
settings.frameNumber = 1;
setWorkingDirectory(settings.loadDirectory(1:end-9));
updateUI(handles);

% --- Executes on button press in try_const.
function try_const_Callback(hObject, eventdata, handles)
global settings;

dirname = fixDir(handles.directory.String);
images = dir([dirname,'*.tif']);

if isempty(images) && ~isempty(dir([dirname, filesep, 'raw_im', filesep, '*.tif']))
    dirname = [dirname, filesep, 'raw_im', filesep];
end

tryDifferentConstants(dirname)



function previous_Callback(hObject, eventdata, handles)
global settings;
 
settings.frameNumber = settings.frameNumber - 1;
settings.frameNumber = max(settings.frameNumber, 1);
loadData(settings.frameNumber)
updateUI(handles);


function undo_Callback(hObject, eventdata, handles)
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




function del_areas_Callback(hObject, eventdata, handles)
global settings;

if settings.dataSegmented
    settings.axisFlag = 3;
    settings.firstPosition = [];
    updateUI(handles);
else
    warning(['Plese segment files first']);
end

function del_reg_Callback(hObject, eventdata, handles)
global settings
if settings.dataSegmented
    settings.axisFlag = 6;
    settings.firstPosition = [];
    updateUI(handles);
else
    warning(['Plese segment files first']);
end


function train_segs_Callback(hObject, eventdata, handles)
global settings;

if isempty(settings.CONST)
    dispError('You must load a CONST file to create bad regions')
    return;
end
set(handles.figure1,'Pointer','watch');
h = msgbox('Training segments, this will take a bit.' );
handles.tooltip.String = 'Training segments... Please wait.';
drawnow;

saveData_Callback();

% hack to put a new segm info calculation - change your pointer 
settings.CONST.seg.segScoreInfo = settings.segsInfo;
settings.CONST.superSeggerOpti.NUM_INFO = settings.numSegsInfo;


disp('loading the segments'' data');
[Xsegs,Ysegs] = getInfoScores (settings.loadDirectory,'segs',settings.recalculateSegs,settings.CONST);
save([settings.currentDirectory,filesep,'segs_training_data'],'Xsegs','Ysegs');
disp('training the segments ..');
[settings.CONST.superSeggerOpti.A,settings.CONST.seg.segmentScoreFun] = settings.trainFun (Xsegs, Ysegs);

settings.constantModified = 1;

% update scores and save data files again
disp('updating the segments'' raw scores with the new coefficients..');
updateScores(settings.loadDirectory,'segs', settings.CONST.superSeggerOpti.A, settings.CONST.seg.segmentScoreFun);
set(handles.figure1,'Pointer','arrow');
try
    close(h);
catch
end

updateUI(handles);


function bad_regs_Callback(hObject, eventdata, handles)
global settings;

if settings.dataSegmented
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
else
    dispError('You must load a CONST file to create bad regions')
end



function train_regs_Callback(hObject, eventdata, handles)
global settings;

if isempty(settings.CONST)
    dispError('You must load a CONST file to create bad regions')
    return;
end

if ~settings.hasBadRegions
    answer = questdlg(['You have not added bad regions. Do you wish to continue?'], 'Continue?', 'Yes', 'No', 'No');
    if strcmp(answer, 'No')
        return;
    end
end
set(handles.figure1,'Pointer','watch');
h = msgbox('Training regions, this will take a bit.' );
handles.tooltip.String = 'Training regions... Please wait.';

drawnow;

saveData_Callback();


settings.CONST.regionScoreFun.props = settings.regsInfo;
settings.CONST.regionScoreFun.NUM_INFO = settings.numRegsInfo;


[Xregs,Yregs] = getInfoScores (settings.loadDirectory,'regs',settings.recalculateRegs, settings.CONST);
save([settings.currentDirectory,filesep,'regs_training_data'],'Xregs','Yregs');
[settings.CONST.regionScoreFun.E,settings.CONST.regionScoreFun.fun] = settings.trainFun (Xregs, Yregs);

settings.constantModified = 1;

% 7) Calculates new scores for regions
disp ('Calculating regions'' scores with new coefficients...');
updateScores(settings.loadDirectory,'regs', settings.CONST.regionScoreFun.E, settings.CONST.regionScoreFun.fun);

try
    close(h);
catch
end
set(handles.figure1,'Pointer','arrow');
loadData(settings.frameNumber);

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

global settings;

CONST = settings.CONST;
[~, ~, constantsPath] = getConstantsList();
[FileName,PathName] = uiputfile('newCONST.mat', 'Save CONST file', [constantsPath, 'newConst']);
if ~isempty(strfind(FileName, '.'))
    FileName = FileName(1:(max(strfind(FileName, '.')) - 1));
end

if FileName ~= 0
    save([PathName, FileName, '.mat'],'-STRUCT','CONST');
    
    settings.constantModified = 0;

    if exist('hObject', 'var') && ~isempty(hObject)
        updateUI(handles);
    end
end


% --------------------------------------------------------------------
function image_folder_ClickedCallback(hObject, eventdata, handles)
newDir = uigetdir;
if newDir ~= 0
    handles.directory.String = newDir;
    setWorkingDirectory(handles.directory.String);
    updateUI(handles);
end


% --- Executes on button press in next.
function next_Callback(hObject, eventdata, handles)

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
handles.currentConstants.String = ['Current: ', settings.nameCONST];

firstFrame = 0;
if numel(handles.viewport_train.Children) == 0
    firstFrame = 1;
end

while numel(handles.viewport_train.Children) > 0
    delete(handles.viewport_train.Children(1))
end

if settings.dataSegmented
    if settings.axisFlag == 1 || settings.axisFlag == 2
        % 1 for segments view, 2 for phase view.
        FLAGS.im_flag = settings.axisFlag;
        FLAGS.S_flag = settings.handles.show_score.Value;
        FLAGS.index_score = str2num(settings.handles.score_txt.String);
        FLAGS.t_flag = 0;
        
        showSegRuleGUI(settings.currentData, FLAGS, handles.viewport_train);
        
        if numel(handles.viewport_train.Children) > 0
            set(handles.viewport_train.Children(1),'ButtonDownFcn',@imageButtonDownFcn);
        end
    elseif settings.axisFlag == 3
        % deleting areas in square
        maskFigure()
        %backer = ag(settings.currentData.phase);
        %imshow(cat(3,0.5*backer+0.5*ag(settings.currentData.mask_cell),0.5*backer,0.5*backer));
       
        if numel(handles.viewport_train.Children) > 0
            set(handles.viewport_train.Children(1),'ButtonDownFcn',@imageButtonDownFcn);
        end
        
        if numel(settings.firstPosition) > 0
            hold on;
            plot( settings.firstPosition(1), settings.firstPosition(2), 'w+','MarkerSize', 30)
        end
    elseif settings.axisFlag == 4
        % showing phase image
        axes(handles.viewport_train);
        imshow(settings.currentData.phase, []);
    elseif settings.axisFlag == 5
        % mask image
        maskFigure()
    elseif settings.axisFlag == 6
        % deleting regions
        maskFigure()
       
        if numel(handles.viewport_train.Children) > 0
            set(handles.viewport_train.Children(1),'ButtonDownFcn',@imageButtonDownFcn);
        end
        
        if numel(settings.firstPosition) > 0
            hold on;
            plot( settings.firstPosition(1), settings.firstPosition(2), 'w+','MarkerSize', 30)
        end
    end
elseif settings.imagesLoaded
    axes(handles.viewport_train);
    imshow(settings.currentData, []);
end

handles.regions_radio.Value = 0;
handles.phase_radio.Value = 0;
handles.segs_radio.Value = 0;
handles.mask_radio.Value = 0;
if settings.axisFlag == 5 || settings.axisFlag == 3 || settings.axisFlag == 6
    handles.mask_radio.Value = 1;
elseif settings.axisFlag == 4
    handles.phase_radio.Value = 1;
elseif settings.axisFlag == 2 
    handles.regions_radio.Value = 1;
elseif settings.axisFlag == 1
    handles.segs_radio.Value = 1;
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
    if numel(handles.viewport_train.Children) > 0
        set(handles.viewport_train.Children(1),'Visible', 'off');
    end
end

if settings.currentIsBad
    badString = ' "Bad regions"';
else
    badString = '';
end

if settings.axisFlag == 5
    handles.tooltip.String = ['Mask.', badString, ' Num frames: ', num2str(settings.numFrames), ', Test data: ', num2str(numel(settings.loadFiles))];
elseif settings.axisFlag == 4
    handles.tooltip.String = ['Phase image.', badString, ' Num frames: ', num2str(settings.numFrames), ', Test data: ', num2str(numel(settings.loadFiles))];
elseif settings.axisFlag == 3
    handles.tooltip.String = ['Click to the two corners to delete the regions inside a square', badString, ' Num frames: ', num2str(settings.numFrames), ', Test data: ', num2str(numel(settings.loadFiles))];
elseif settings.axisFlag == 1
    handles.tooltip.String = ['Click to toggle segments.', badString, ' Num frames: ', num2str(settings.numFrames), ', Test data: ', num2str(numel(settings.loadFiles))];
elseif settings.axisFlag == 2
    handles.tooltip.String = ['Click to toggle regions.', badString, ' Num frames: ', num2str(settings.numFrames), ', Test data: ', num2str(numel(settings.loadFiles))];
elseif settings.imagesLoaded == 1
    handles.tooltip.String = ['Phase image. Zoom in to the part of the image you want to train on.', badString, ' Num frames: ', num2str(settings.numFrames)];
elseif settings.axisFlag == 0
    handles.tooltip.String = 'Load a file with images or segmented files.';
end

handles.currentConstants.String = ['Current: ', settings.nameCONST];
handles.frameSkip.String = num2str(settings.frameSkip);
handles.directory.String = settings.currentDirectory;
numTrainingFrames = floor(numel(dir([settings.imageDirectory, '*c1*.tif'])) / settings.frameSkip);
handles.totalFrames.String = ['Total frames: ', num2str(numTrainingFrames), ' / ', num2str(numel(dir([settings.imageDirectory, '*c1*.tif'])))];

if numel(settings.oldData) > 0
    makeActive(handles.undo);
else
    makeInactive(handles.undo);
end

if settings.hasBadRegions
    handles.bad_regs.String = 'Clear bad regions';
else
    handles.bad_regs.String = 'Create bad regions';
end

if settings.constantModified
    makeActive(handles.save);
else
    makeInactive(handles.save);
end

if exist(settings.saveFolder, 'dir') && numel(dir(settings.saveFolder)) > 2
    makeActive(handles.saveData);
else
    makeInactive(handles.saveData);
end

if settings.imagesLoaded
    makeActive(handles.try_const);
    makeActive(handles.makeData);
else
    makeInactive(handles.try_const);
    makeInactive(handles.makeData);
end

if settings.imagesLoaded || settings.dataSegmented == 1
    makeActive(handles.previous);
    makeActive(handles.next);
else
    makeInactive(handles.previous);
    makeInactive(handles.next);
end

% No CONST file selected
if isempty(settings.CONST)
    makeInactive(handles.cut_and_seg);
else
    makeActive(handles.cut_and_seg);
end

if settings.dataSegmented == 0
    handles.train_actions.Visible = 'off';
    handles.seg_actions.Visible = 'on';
    handles.cut_and_seg.Visible = 'on';
else
    handles.train_actions.Visible = 'on';
    handles.seg_actions.Visible = 'off';
    handles.cut_and_seg.Visible = 'off';
end


function maskFigure()
global settings;
cell_mask = settings.currentData.mask_cell;
cc = bwconncomp(cell_mask, 4);
labeled = labelmatrix(cc);
RGB_label = label2rgb(labeled,'lines',[0 0 0]);%,'shuffle');
imshow(RGB_label);
  

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

try
settings.oldData = [settings.currentData(1), settings.oldData(1)];
catch
settings.oldData = [settings.currentData(1)];
end
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
settings.loadDirectory = [];

%Is in seg folder
settings.currentDirectory = [directory,filesep];
settings.currentDirectory = settings.currentDirectory(1:(max(regexp(settings.currentDirectory, [filesep, '*$']))));
isSegFolder = numel(dir([directory,filesep,'*seg.mat'])) > 0;


if isSegFolder
    settings.loadDirectory = [directory,filesep];
else
    xyPositions = dir([directory,filesep,'xy*',filesep]);
    if numel(xyPositions) > 0
        settings.loadDirectory = [directory,filesep,xyPositions(1).name,filesep,'seg',filesep];        
        settings.currentDirectory = settings.loadDirectory(1:end-9);      
    else
       settings.loadDirectory = [directory,filesep,'xy1/seg/']; 
    end
end

hasCONST = ~isSegFolder && exist([settings.loadDirectory, '..', filesep, '..', filesep, 'CONST.mat'], 'file');
if clearCONST == 1 || hasCONST == 1
    settings.CONST = [];
    settings.nameCONST = 'none';
    settings.constantModified = 0;
    if hasCONST
        settings.CONST = loadConstants([settings.loadDirectory, '..', filesep, '..', filesep, 'CONST.mat'], 0, 0);
        settings.nameCONST = 'local';
    end
end

settings.imagesLoaded = 0;
settings.imageDirectory = [];
if numel(dir([settings.loadDirectory(1:end-8), filesep, '*.tif'])) > 0
    settings.imagesLoaded = 1;
    settings.imageDirectory = settings.loadDirectory(1:end-8);
elseif numel(dir([settings.loadDirectory(1:end-8), filesep, 'raw_im', filesep, '*.tif'])) > 0
    settings.imagesLoaded = 1;
    settings.imageDirectory = [settings.loadDirectory(1:end-8), filesep, 'raw_im', filesep];
end

if exist(settings.loadDirectory, 'dir')
    settings.numFrames = numel(dir([settings.loadDirectory,'*seg.mat']));
    
    % get files with right names
    loadFiles = dir([settings.loadDirectory,'*seg*.mat']);
    filenames = {loadFiles.name}';
    pass_names= regexp(filenames,'seg.mat|seg_\d+_mod.mat');
    pass_flag = ~cellfun('isempty',pass_names);
    loadFiles(~pass_flag) = [];
    settings.loadFiles = loadFiles;
    
    if settings.numFrames > 0
        settings.dataSegmented = 1;
        settings.axisFlag = 4;
        loadData(settings.frameNumber);

        settings.hasBadRegions = 0;
        if settings.numFrames < numel(settings.loadFiles)
            settings.hasBadRegions = 1;
        end

        if isempty(settings.CONST)
            loadConstants_Callback([], [], settings.handles)
        end

        %Make save folder
        try
            settings.saveFolder = [settings.loadDirectory(1:end-1), '_tmp', filesep];
            if ~exist(settings.saveFolder, 'dir')
                mkdir(settings.saveFolder);
            else
                delete([settings.saveFolder, '*']);
            end
        catch ME
            warning(['Could not back up files: ', ME.message]);
        end
    end
elseif settings.imagesLoaded
    settings.numFrames = numel(dir([settings.imageDirectory,'*.tif']));
    settings.loadFiles = dir([settings.imageDirectory,'*.tif']);
    loadData(settings.frameNumber);
else
    settings.numFrames = 0;
    settings.loadFiles = [];
end

%Clear viewport_train
if isfield(settings.handles,'viewport_train') && isvalid(settings.handles.viewport_train)
    while numel(settings.handles.viewport_train.Children) > 0
        delete(settings.handles.viewport_train.Children(1))
    end
end





% --- Executes on mouse press over axes background.
function imageButtonDownFcn(hObject, eventdata, handles)

global settings;

if settings.axisFlag == 1 || settings.axisFlag == 2
    FLAGS.im_flag = settings.axisFlag;
    FLAGS.S_flag = 0;
    FLAGS.t_flag = 0;
    
    addUndo();
    [settings.currentData, list] = updateTrainingImage(settings.currentData, FLAGS, eventdata.IntersectionPoint(1:2));
    if settings.axisFlag == 1 && numel(list) > 0
        settings.currentData = intMakeRegs( settings.currentData, settings.CONST, [], [] );
    end
    saveData();
    

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
    
elseif settings.axisFlag == 6
        plot(eventdata.IntersectionPoint(1), eventdata.IntersectionPoint(2), 'w+','MarkerSize', 30)       
        drawnow;        
        addUndo();
        settings.currentData = killRegionsGUI(settings.currentData, settings.CONST, [eventdata.IntersectionPoint(1),eventdata.IntersectionPoint(2)],[]);
        saveData();      
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

settings.currentIsBad = strfind(settings.loadFiles(frameNumber).name, '_mod.mat');


function shouldCancel = checkIfSave()
global settings;

shouldCancel = 0;

if exist(settings.saveFolder, 'dir')
    if numel(dir(settings.saveFolder)) > 2
        answer = questdlg('You have unsaved changes to the data.', 'Save data changes?', 'Save', 'Ignore', 'Cancel', 'Save');
        
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

if settings.constantModified == 1
    answer = questdlg('You have unsaved changes to the constants.', 'Save constants changes?', 'Save', 'Ignore', 'Cancel', 'Save');
    
    if strcmp(answer, 'Save')
        save_Callback();
    elseif strcmp(answer, 'Cancel')
        shouldCancel = 1;
        
        return;
    end
end




function frameNumber_Callback(hObject, eventdata, handles)
global settings;
settings.frameNumber = str2num(handles.frameNumber.String);
settings.frameNumber = max(1, min(settings.frameNumber, numel(settings.loadFiles)));
loadData(settings.frameNumber);
updateUI(handles);


% --- Executes during object creation, after setting all properties.
function frameNumber_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function saveData_Callback(hObject, eventdata, handles)

global settings;

try
    if numel(dir(settings.saveFolder)) > 2
        movefile([settings.saveFolder, '*'], settings.loadDirectory)
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

global settings;

xSize = handles.viewport_train.XLim(2) - handles.viewport_train.XLim(1);
ySize = handles.viewport_train.YLim(2) - handles.viewport_train.YLim(1);
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

newDir = uigetdir([settings.imageDirectory, '..', filesep], 'Select empty folder for training data');

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
    
    for i = 1:settings.frameSkip:maxFrames
        tempImage = imread([settings.imageDirectory,settings.loadFiles(i).name]);
        saveName = [newDir, filesep, settings.loadFiles(i).name];
        imwrite( tempImage(cropY, cropX), saveName, 'TIFF' );
    end
    
    setWorkingDirectory([newDir, filesep], 0);   
    updateUI(handles);
end


function frameSkip_Callback(hObject, eventdata, handles)
global settings;

settings.frameSkip = str2num(handles.frameSkip.String);

updateUI(handles);

function frameSkip_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function loadConstants_Callback(hObject, eventdata, handles)

global settings;

[~, ~, constantsPath] = getConstantsList();
[FileName,PathName] = uigetfile('.mat', 'Load CONST file', constantsPath);
if FileName ~= 0
    settings.CONST = loadConstants([PathName, FileName],0,0);
    settings.nameCONST = settings.CONST.ResFlag;
    settings.nameCONST = settings.nameCONST((max(strfind(settings.nameCONST, filesep)) + 1):end);
    
    updateUI(handles);
end


function makeActive(button)
button.Enable = 'on';
button.ForegroundColor = [0, 0, 0];

function makeInactive(button)
button.Enable = 'inactive';
button.ForegroundColor = [.5, .5, .5];


function makeGoodRegions_Callback(hObject, eventdata, handles)

global settings;

settings.axisFlag = 2;
addUndo();
settings.currentData.regs.score = ones( settings.currentData.regs.num_regs, 1 );
saveData();

updateUI(handles);


function phase_radio_Callback(hObject, eventdata, handles)

global settings
if get(hObject,'Value')
    settings.axisFlag = 4;    
    handles.regions_radio.Value = 0;
    handles.segs_radio.Value = 0;
    handles.mask_radio.Value = 0;
end
updateUI(handles);


function regions_radio_Callback(hObject, eventdata, handles)

global settings
if get(hObject,'Value')
    settings.axisFlag = 2;
    
    handles.phase_radio.Value = 0;
    handles.segs_radio.Value = 0;
    handles.mask_radio.Value = 0;
    
    if isempty(settings.CONST)
        loadConstants_Callback([], [], settings.handles)
    end
    
    if isempty(settings.CONST)
        questdlg('You must load a CONST file to update the regions', 'Error', 'Okay', 'Okay');
    end
    
    
end
updateUI(handles);

% --- Executes on button press in segs_radio.
function segs_radio_Callback(hObject, eventdata, handles)

global settings
if get(hObject,'Value')
    settings.axisFlag = 1;
    handles.mask_radio.Value = 0;
    handles.regions_radio.Value = 0;
    handles.phase_radio.Value = 0;
end
updateUI(handles);


function frame_text_CreateFcn(hObject, eventdata, handles)

function mask_radio_Callback(hObject, eventdata, handles)
global settings
if get(hObject,'Value')
    settings.axisFlag = 5;
    handles.regions_radio.Value = 0;
    handles.segs_radio.Value = 0;
    handles.phase_radio.Value = 0;
end
updateUI(handles);


function crop_Callback(hObject, eventdata, handles)


function save_cut_Callback(hObject, eventdata, handles)
global settings;

xSize = handles.viewport_train.XLim(2) - handles.viewport_train.XLim(1);
ySize = handles.viewport_train.YLim(2) - handles.viewport_train.YLim(1);
cropX = ceil(handles.viewport_train.XLim(1):handles.viewport_train.XLim(2) - 1);
cropY = ceil(handles.viewport_train.YLim(1):handles.viewport_train.YLim(2) - 1);
i = settings.frameNumber;
filename =[ settings.imageDirectory,filesep,settings.loadFiles(i).name];

tempImage = imread([filename]);
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
% hObject    handle to debug (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global settings;
keyboard;


% --- Executes on button press in show_score.
function show_score_Callback(hObject, eventdata, handles)
% hObject    handle to show_score (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_score
updateUI(handles);


function score_txt_Callback(hObject, eventdata, handles)
% hObject    handle to score_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of score_txt as text
%        str2double(get(hObject,'String')) returns contents of score_txt as a double
updateUI(handles);

% --- Executes during object creation, after setting all properties.
function score_txt_CreateFcn(hObject, eventdata, handles)
% hObject    handle to score_txt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
