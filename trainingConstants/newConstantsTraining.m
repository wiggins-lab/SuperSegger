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
% Written by Stella Stylianidou & Paul Wiggins.
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

% initialize
parallel = 0;
skip = 1;

% 1) runs selected constants on one image

% modify this to only look at the initial constants you need
% resFlags = {'60XEc','60XA','60XEcLB',...
%     '60XPa','60XPaM','60XPaM2','60XBthai',...
%     '100XEc','100XPa'};
resFlags = {'60XEc','100XEc','60XEcLB','60XBay','60XPa','100XPa'}

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

CONST = loadConstantsNN(res,parallel);disp ('Croppping images - choose a small region with a couple of colonies');
% only xy1
trackOptiCropMulti(dirname,1)
segTrainingDir = [dirname,'crop',filesep];

% 2) cuts the image series for xy1, every 5 time frames
disp ('Croppping images - choose a small region with a couple of colonies');
% only xy1
trackOptiCropMulti(dirname,1)
segTrainingDir = [dirname,'crop',filesep];

% 3) runs the whole segmentation with your favorite constants
dirname_seg = [segTrainingDir,filesep,'xy1',filesep,'seg',filesep];
mkdir(dirname_seg);

only_seg = 1; % runs only segmentation, no linking
BatchSuperSeggerOpti(segTrainingDir,skip,0,CONST,1,1,only_seg);

disp ('Segmentation finished - optimize the segments');
disp ('Red are correct segments, blue are incorrect segments');

Eold = CONST.regionScoreFun.E;
Aold = CONST.superSeggerOpti.A;

segDir = [segTrainingDir,filesep,'xy1',filesep,'seg',filesep];
segDirMod = [segTrainingDir,filesep,'xy1',filesep,'segMod',filesep];
mkdir(segDirMod);
segData = dir([segDir,'*seg.mat']);

% 4) kill bad regions

for i = 1 : numel(segData)
        data = load([segDir,segData(i).name]);
        data = killRegions (data,CONST)
        save([segDirMod,segData(i).name],'-STRUCT','data');
end

% 5) user sets good and bad segments

FLAGS.im_flag = 1;
FLAGS.S_flag = 0;
FLAGS.t_flag = 0;
repeat = true;

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

% scoring parameters - 21



FLAGS.im_flag = 2;
FLAGS.S_flag = 0;
FLAGS.t_flag = 0;
repeat = true;
segData = dir([segDirMod,'*seg*.mat']);
while repeat
    for i = 1 : numel(segData)
        data = load([segDirMod,segData(i).name]);
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

% you can use different cell properties than the original constants you chose
% if you want by changing this
CONST.regionScoreFun.props = @cellprops3; 
CONST.regionScoreFun.NUM_INFO = 21;

disp ('Training neural network to identify correct and false regions');
[Xregs,Yregs] =  getInfoScores (segDirMod,'regs',CONST);
[netRegions] = neuralNetTrain (Xregs,Yregs);
E = netRegions;

% 7) Calculates new scores for regions
disp ('Calculating regions'' scores with new coefficients...');
updateScores(segDirMod,'regs', E, @scoreNeuralNet);

% saves A,E and whole constants file
CONST.superSeggerOpti.A = A;
CONST.seg.segFun = @ssoSegFunPerReg; % to use the new per region scoring segm
CONST.seg.segmentScoreFun = @scoreNeuralNet;

CONST.regionScoreFun.E = E;
CONST.regionScoreFun.fun = @scoreNeuralNet;

% because of the raw score change from - 50 to 50 
CONST.regionOpti.CutOffScoreHi = 10;
CONST.regionOpti.CutOffScoreLo = -10;
CONST.trackOpti.SCORE_LIMIT_DAUGHTER = -30;
CONST.trackOpti.SCORE_LIMIT_MOTHER = - 30;
CONST.regionOpti.minGoodRegScore = 10; 
CONST.regionOpti.neighMaxScore = 10;

save([dirname,constname,'_FULLCONST'],'-STRUCT','CONST');
save([dirname,constname,'_AE'],'A','E');
disp ('new constants saved');
end

function saveSegData (dataname)
 save(dataname,'-STRUCT','data');
end