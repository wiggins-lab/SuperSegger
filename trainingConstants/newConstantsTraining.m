function newConstantsTraining(dirname, constname)
% newConstantsTraining : used to train new constants using neural networks.
% The function trains for the segments and regions and saves the new
% contants under dirname/constname_FULLCONST.mat and the neural nets with the coefficients
% under dirname/constname.mat (A and E).
%
% INPUT :
%       dirname : directory with images
%       constame : name under which new constants will be saved.
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


% initialize
parallel = 0;
skip = 1;

% 1) runs selected constants on one image

% modify this to only look at the initial constants you need
resFlags = {'60XEc','60XA','60XEcLB',...
    '60XPa','60XPaM','60XPaM2','60XBthai',...
    '100XEc','100XPa'};

resFlags = {'60XEc'};

% creates a printable verison of resFlgas
resFlagsPrint = resFlags ; % work on copy
resFlagsPrint(2,:) = {', '};
resFlagsPrint{2,end} = '';
resFlagsPrint = [resFlagsPrint{:}];

dirname = fixDir(dirname);
tryDifferentConstants(dirname,resFlags)


prompt1 = 'Please choose the constants that suit your images better :';
res = input(prompt1,'s');
while ~any(ismember(resFlags,res))
    disp (['choices are :',resFlagsPrint]);
    res = input(prompt,'s');
end
disp (['Loading constants ', res]);

CONST = loadConstants(res,parallel);

% 2) cuts the image series for xy1, every 5 time frames
disp ('Croppping images - choose a small region with a couple of colonies');
% only xy1
trackOptiCropMulti(dirname,1)
segTrainingDir = [dirname,'crop',filesep];

% 3) runs the whole segmentation with your favorite constants
dirname_seg = [segTrainingDir,filesep,'xy1',filesep,'seg',filesep];
mkdir(dirname_seg);

% create time stamps to not run the fluorescence and cell maker parts
time_stamp = clock;

only_seg = 1; % runs only segmentation, no linking
BatchSuperSeggerOpti(segTrainingDir,skip,0,CONST,1,only_seg);

disp ('Segmentation finished - optimize the segments');
disp ('Red are correct segments, blue are incorrect segments');

Eold = CONST.regionScoreFun.E;
Aold = CONST.superSeggerOpti.A;

% 4) user sets good and bad segments
segDir = [segTrainingDir,filesep,'xy1',filesep,'seg',filesep];
segDirMod = [segTrainingDir,filesep,'xy1',filesep,'segMod',filesep];
mkdir(segDirMod);
segData = dir([segDir,'*seg.mat']);
FLAGS.im_flag = 1;
FLAGS.S_flag = 0;
FLAGS.t_flag = 0;
repeat = true

while repeat
    for i = 1 : numel(segData)
        data = load([segDir,segData(i).name]);
        [data,touch_list] = makeTrainingData (data,FLAGS)
        save([segDirMod,segData(i).name],'-STRUCT','data');
    end
    prompt1 = 'Would you like to repeat segment training for all the images? (y/n)';
    answer = input(prompt1,'s');
    if ~any(ismember('Yy',answer))
        repeat = false;
    end
end

% check them
segDataMod = dir([segDirMod,'*seg.mat']);
FLAGS.im_flag = 2;
for i = 1 : numel(segData)
        data = load([segDirMod,segDataMod(i).name]);
        showSegRule(data,FLAGS);
        pause;
end

% 5) train the neural network on the segments
disp ('Training neural network to identify correct and false segments.');
[Xsegs,Ysegs] =  getInfoScores (segDirMod,'segs');
[A] = neuralNetTrain (Xsegs,Ysegs);

% update scores and save data files again
disp ('Updating segments'' scores using the trained neural network.');
updateScores(segDirMod,'segs', A, @scoreNeuralNet);


FLAGS.im_flag = 2;
FLAGS.S_flag = 0;
FLAGS.t_flag = 0;
repeat = true
segData = dir([segDir,'*seg*.mat']);
while repeat
    for i = 1 : numel(segData)
        data = load([segDir,segData(i).name]);
        [data,touch_list] = makeTrainingData (data,FLAGS)
        save([segDirMod,segData(i).name],'-STRUCT','data');
    end
    prompt1 = 'Would you like to repeat segment training for all the images? (y/n)';
    answer = input(prompt1,'s');
    if ~any(ismember('Yy',answer))
        repeat = false;
    end
end


% 4) Creates regions, with the good segments, sets their scores to 1
% and creates bad regions by turning on and off the rest of the segments.
makeBadRegions( segDirMod, CONST)


% 6) Runs neural network training on regions
disp ('Training neural network to identify correct and false regions');
[Xregs,Yregs] =  getInfoScores (segDirMod,'regs');
[netRegions] = neuralNetTrain (Xregs,Yregs);
E = netRegions;

% 7) Calculates new scores for regions
disp ('Calculating regions'' scores with new coefficients...');
updateScores(segDirMod,'regs', E, @scoreNeuralNet);

% saves A,E and whole constants file
CONST.superSeggerOpti.A = A;
CONST.seg.segmentScoreFun = @scoreNeuralNet;
CONST.regionScoreFun.E = E;
CONST.regionScoreFun.fun = @scoreNeuralNet;

% because of the raw score change from - 50 to 50 
CONST.regionOpti.CutOffScoreHi = 10;
CONST.regionOpti.CutOffScoreLo = -10;
CONST.trackOpti.SCORE_LIMIT_DAUGHTER = -30;
CONST.trackOpti.SCORE_LIMIT_MOTHER = - 30;
CONST.regionOpti.minGoodRegScore = 10; %CONST.trackOpti.SCORE_LIMIT_DAUGHTER; % change to 10.. put it in the constants..
CONST.regionOpti.neighMaxScore = 10;

save([dirname,constname,'_FULLCONST'],'-STRUCT','CONST');
save([dirname,constname],'A','E');
disp ('new constants saved');
end

function saveSegData (dataname)
 save(dataname,'-STRUCT','data');
end