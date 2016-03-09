function newConstantsTraining(dirname, constname)
% full new constants training


parallel = 0;
skip = 5;

resFlags = {'60XEc','60XA','60XEcLB',...
    '60XPa','60XPaM','60XPaM2','60XBthai',...
    '100XEc','100XPa'};
resFlags = {'60XEc','60XA','60XEcLB'};

resFlagsPrint = resFlags ; % work on copy
resFlagsPrint(2,:) = {', '};
resFlagsPrint{2,end} = '';
resFlagsPrint = [resFlagsPrint{:}];

dirname = fixDir(dirname);

% 1) run select constants and select best

tryDifferentConstants(dirname,resFlags)

prompt1 = 'Please choose the constants that suit your images better :';
res = input(prompt1,'s');
while ~any(ismember(resFlags,res))
    disp (['choices are :',resFlagsPrint]);
    res = input(prompt,'s');
end
disp (['Loading constants ', res]);

CONST = loadConstants(res,parallel);

% 2) cut image, copy xy1, every 5 time frames
disp ('Croppping images');
% only xy1
trackOptiCropMulti(dirname,1)
segTrainingDir = [dirname,'crop',filesep];

% 3) run the whole segmentation with your favorite constants
dirname_seg = [segTrainingDir,filesep,'xy1',filesep,'seg',filesep];
mkdir(dirname_seg);
% to run less things...
time_stamp = clock;

stamp_name = [dirname_seg,'.trackOptiCellMarker.mat'];
save( stamp_name, 'time_stamp');
stamp_name = [dirname_seg,'.trackOptiFluor.mat'];
save( stamp_name, 'time_stamp');
stamp_name = [dirname_seg,'.trackOptiMakeCell.mat'];
save( stamp_name, 'time_stamp');
stamp_name = [dirname_seg,'.trackOptiMakeCell.mat'];
save( stamp_name, 'time_stamp');
stamp_name = [dirname_seg,'.trackOptiFindFociCyto.mat'];
save( stamp_name, 'time_stamp');
stamp_name = [dirname_seg,'.trackOptiClist.mat'];
save( stamp_name, 'time_stamp');
stamp_name = [dirname_seg,'.trackOptiCellFiles.mat'];
save( stamp_name, 'time_stamp');
   
BatchSuperSeggerOpti(segTrainingDir,skip,0,CONST,1);

disp ('Segmentation finished - optimize the segments');
disp ('Red are correct segments, blue are incorrect segments');

Eold = CONST.regionScoreFun.E;
Aold = CONST.superSeggerOpti.A;

% 4) set good and bad segments
% pick a frame or go from frame to frame?
segDir = [segTrainingDir,filesep,'xy1',filesep,'seg',filesep];
segDirMod = [segTrainingDir,filesep,'xy1',filesep,'segMod',filesep];
mkdir(segDirMod);
segData = dir([segDir,'*seg.mat']);
FLAGS.im_flag = 1;

for i = 1 : numel(segData)
    data = load([segDir,segData(i).name]);
    [data,touch_list] = makeTrainingData (data,FLAGS)
    save([segDirMod,segData(i).name],'-STRUCT','data');
end

% 5) run regularized logistic regression on segments
disp ('starting training on segments...');
[Xsegs,Ysegs] = getInfoScores (segDirMod,'segs');
A = lassoLogisticRegression (Xsegs,Ysegs,parallel);

% update scores and save data files again
disp ('updating segments'' scores with new coefficients...');
updateScores(segDirMod,'segs',A);

% load('/Users/Stella/Documents/MATLAB/training_constants/100X/lasso100x.mat')% B1
% CONST.superSeggerOpti.A  = B1;
% phase_im = imread('raw_im/tsyfp-p-t029c1.tif');
% ssoSegFunLasso( phase_im, CONST, 'test', 'hi', [] )

% 4) update the regions with the newly made segments


% 5) create regions if they don't exist,
% create bad region examples using current E
% chops all cells up and places bad regions in _mod_seg files

makeBadRegions( dirname,Eold, CONST )


% 6) run regularized logistic regression on regions
disp ('starting training on regions...');
[Xregs,Yregs] =  getInfoScores (segTrainingDir,'regs');

E = lassoLogisticRegression (Xregs,Yregs,parallel);


% save constants
CONST.superSeggerOpti.A = A;
CONST.regionScoreFun.E = E;
CONST.seg.segFun = @ssoSegFunLasso
CONST.regionScoreFun.fun = @calculateLassoScores

save([constname,'_FULLCONST'],'-STRUCT','CONST');

% save A,E, and whole constants file
save(constname,'-STRUCT','A','E');

end



function saveSegData (dataname)
 save(dataname,'-STRUCT','data');
end