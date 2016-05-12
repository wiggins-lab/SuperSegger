function CONST = loadConstantsNN( res, PARALLEL_FLAG, dispText )
% loadConstants loads the parameters for the superSegger/trackOpti package.
% If you want to customize the constants DO NOT CHANGE
% THIS FILE! Rename this file loadConstantsMine.m and
% put in somehwere in the path.
% That file will load automatically rather than this one.
% When you make loadConstantsMine.m, change
% disp( 'loadConstants: Initializing.')
% to loadConstantsMine to avoid confusion.
%
% INPUT :
%   res : number for resolution of microscope used (60 or 100) for E. coli
%         or use a string as shown below
%   PARALLEL_FLAG : 1 if you want to use parallel computation
%                   0 for single core computation
%   dispText : to display the name of the constants that are loaded.
%
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou
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

if nargin < 1 || isempty( res )
    res = 60;
end

if ~exist('PARALLEL_FLAG','var') || isempty( PARALLEL_FLAG )
    PARALLEL_FLAG = false;
end

if ~exist('dispText','var') || isempty( dispText )
    dispText = true;
end


                                                                     %
%% Specify scope resolution                                                %                                                                       %                                %
% Values for setting res
% '60XEc' : constants for 60X Ecoli
% '100XEc': constants for 100X Ecoli
% '60XEcLB': constants for 60X LB Ecoli
% '60XBay' : constants for 60X Baylyi
% '60XPa': constants for 60X Pseudemonas
% '100XPa': constants for 100X Pseudemonas
% res : {'60XEc','100XEc','60XEcLB','60XBay','60XPa','100XPa'}

[possibleConstants, ~, filepath] = getConstantsList();

% default values for numbers
resFlag = [];
if isa(res,'double' ) && res == 60
    res = '60XEc';
elseif isa(res,'double' ) && res == 100
    res = '100XEc';
end



% Settings for alignment in differnt channels - modify for your microscope
CONST.imAlign.DAPI    = [-0.0354   -0.0000    1.5500   -0.3900];
CONST.imAlign.mCherry = [-0.0512   -0.0000   -1.1500    1.0000];
CONST.imAlign.GFP     = [ 0.0000    0.0000    0.0000    0.0000];

CONST.imAlign.out = {CONST.imAlign.GFP, ...   % c1 channel name
    CONST.imAlign.GFP,...  % c2 channel name
    CONST.imAlign.GFP};        % c3 channel name

CONST.align.ALIGN_FLAG = 1;


% region optimization parameters
CONST.regionOpti.MAX_NUM_RESOLVE = 5000; % no further optimization above this number of segments 
CONST.regionOpti.MAX_NUM_SYSTEMATIC = 8; % max number of segments for systematic
CONST.regionOpti.CutOffScoreHi = 10; % cut off score for segments
CONST.regionOpti.CutOffScoreLo = -10; % cut off score for segments
CONST.regionOpti.fignum =  1;
CONST.regionOpti.Nt = 500; % max number of steps in simulated anneal
CONST.regionOpti.minGoodRegScore = 10; % minimum score for region to not be optimized.
CONST.regionOpti.neighMaxScore = 10; % max score for neighbor to be optimized with a bad region
CONST.regionOpti.ADJUST_FLAG = 1; % adjusts simulated anneal with number of segs
CONST.regionOpti.DE_norm = 0.5000; % segments' weight for global region opti scoring 

% trackOpti : general constants
CONST.trackOpti.NEIGHBOR_FLAG = 0; % finds cell neighbors
CONST.trackOpti.pole_flag = 1; % guesses old and new pole in snapshots

% trackOpti : linking constants
CONST.trackOpti.OVERLAP_LIMIT_MIN = 0.0800;
CONST.trackOpti.DA_MAX = 0.3; % maximum area change in linking from r->c
CONST.trackOpti.DA_MIN = -0.1; % minimum area change in linking from r->c
CONST.trackOpti.LYSE_FLAG = 0;
CONST.trackOpti.REMOVE_STRAY = 1; % deletes stray regions and their children
CONST.trackOpti.SCORE_LIMIT_DAUGHTER = -30; % mother score for good division
CONST.trackOpti.SCORE_LIMIT_MOTHER = -30; % daughter score for good division
CONST.trackOpti.MIN_CELL_AGE = 5; % minimum cell age for full cell cycle
CONST.trackOpti.linkFun = @multiAssignmentFastOnlyOverlap; % function used for linking cells


% Fluorescence calculations : locates foci and caclulates fluorescence
% statistics.
CONST.trackLoci.crop = 4;
CONST.trackLoci.numSpots = []; % number of spots per channel per cell
CONST.trackLoci.fluorFlag = 0; % to calculate statistics
CONST.trackLoci.gate = [];


% pixelsize
if all(ismember('100X',res))
    CONST.getLocusTracks.PixelSize        = 6/60;
elseif all(ismember('60X',res))
    CONST.getLocusTracks.PixelSize        = 6/100;
else
    CONST.getLocusTracks.PixelSize        = [];
end

% getLocusTracks Constants
CONST.getLocusTracks.FLUOR1_MIN_SCORE = 3;
CONST.getLocusTracks.FLUOR2_MIN_SCORE = 3;
CONST.getLocusTracks.FLUOR1_REL       = 0.3;
CONST.getLocusTracks.FLUOR2_REL       = 0.3;
CONST.getLocusTracks.TimeStep         = 1;

% view constants
CONST.view.showFullCellCycleOnly = false;
CONST.view.orientFlag = true;
CONST.view.falseColorFlag = false;
CONST.view.LogView = false;
CONST.view.maxNumCell = [];


% super resolution constants
% Const for findFocusSR
CONST.findFocusSR.MAX_FOCUS_NUM = 8;
CONST.findFocusSR.crop          = 4;
CONST.findFocusSR.gaussR        = 1;
CONST.findFocusSR.MAX_TRACE_NUM = 1000;
CONST.findFocusSR.WS_CUT        = 50;
CONST.findFocusSR.MAX_OFF       = 3;
CONST.findFocusSR.I_MIN         = 150;
CONST.findFocusSR.mag           = 16;
CONST.findFocusSR.MIN_TRACE_LEN = 0;
CONST.findFocusSR.R_LINK        = 2;
CONST.findFocusSR.R_LINK        = 2;
CONST.findFocusSR.SED_WINDOW    = 10;
CONST.findFocusSR.SED_P         = 10;
CONST.findFocusSR.A_MIN         =  6;

% Const for SR
CONST.SR.opt =  optimset('MaxIter',1000,'Display','off', 'TolX', 1e-8);

% Setup CONST calues for image processing
CONST.SR.GausImgFilter_HighPass = fspecial('gaussian',141,10);
CONST.SR.GausImgFilter_LowPass3 = fspecial('gaussian',21,3);
CONST.SR.GausImgFilter_LowPass2 = fspecial('gaussian',21,2);
CONST.SR.GausImgFilter_LowPass1 = fspecial('gaussian',7,1.25);
CONST.SR.maxBlinkNum = 2;

% this is the pad size for cropping regions for fitting
CONST.SR.pad = 8;
CONST.SR.crop = 4;
CONST.SR.Icut = 1000;
CONST.SR.rcut = 10; % maximum distance between frames for two PSFs
% to be considered two seperate PSFs.

CONST.SR.Ithresh = 2; % threshold intensity in std for including loci in analysis


indexConst = find(strcmpi({possibleConstants.name},[res,'.mat']));
if ~isempty(indexConst)
     constFilename = possibleConstants(indexConst).name;
     ConstLoaded = load ([filepath,filesep,constFilename]);
     CONST.ResFlag = constFilename(1:end-4);
     if dispText
        disp(['loading Constants : ', constFilename]);
     end
     
elseif exist(res, 'file')
    ConstLoaded = load(res);
    CONST.ResFlag = res;
else
    errordlg('loadConstants: Constants not loaded : no match found. Aborting.');
    return;
end


% values that are loaded separatelly for each constant
% you can add here values that you have changed from the default
% and should be loaded from your constants file.

% segmentation parameters
CONST.superSeggerOpti.MIN_BG_AREA = ConstLoaded.superSeggerOpti.MIN_BG_AREA;
CONST.superSeggerOpti.MAX_SEG_NUM = ConstLoaded.superSeggerOpti.MAX_SEG_NUM;
CONST.superSeggerOpti.THRESH1= ConstLoaded.superSeggerOpti.THRESH1;
CONST.superSeggerOpti.THRESH2 = ConstLoaded.superSeggerOpti.THRESH2;
CONST.superSeggerOpti.MAGIC_RADIUS = ConstLoaded.superSeggerOpti.MAGIC_RADIUS;
CONST.superSeggerOpti.CUT_INT= ConstLoaded.superSeggerOpti.CUT_INT;
CONST.superSeggerOpti.MAGIC_THRESHOLD = ConstLoaded.superSeggerOpti.MAGIC_THRESHOLD;
CONST.superSeggerOpti.SMOOTH_WIDTH= ConstLoaded.superSeggerOpti.SMOOTH_WIDTH;
CONST.superSeggerOpti.MAX_WIDTH= ConstLoaded.superSeggerOpti.MAX_WIDTH;
CONST.superSeggerOpti.Amax = ConstLoaded.superSeggerOpti.Amax;
CONST.superSeggerOpti.crop_rad= ConstLoaded.superSeggerOpti.crop_rad;
CONST.superSeggerOpti.A = ConstLoaded.superSeggerOpti.A;
CONST.superSeggerOpti.NUM_INFO= ConstLoaded.superSeggerOpti.NUM_INFO;

% defines segmentation functions used
CONST.seg = ConstLoaded.seg;

% defines region optimization parameters used
if isfield(ConstLoaded.regionOpti, 'MIN_LENGTH')
    CONST.regionOpti.MIN_LENGTH = ConstLoaded.regionOpti.MIN_LENGTH ;
end
% defines region functions used
CONST.regionScoreFun = ConstLoaded.regionScoreFun;

% minimum area a cell region can have, otherwise it is discarded.
CONST.trackOpti.MIN_AREA= ConstLoaded.trackOpti.MIN_AREA;


% Parallel processing on multiple cores settings :
if PARALLEL_FLAG
    poolobj = gcp('nocreate'); % If no pool, do not create new one.
    if isempty(poolobj)
        poolobj = parpool('local');
    end
    poolobj.IdleTimeout = 360; % close after idle for 3 hours
    CONST.parallel.parallel_pool_num = poolobj.NumWorkers;
else
    CONST.parallel.parallel_pool_num = 0;
end

CONST.parallel.xy_parallel = 0;
CONST.parallel.PARALLEL_FLAG = PARALLEL_FLAG;
CONST.parallel.show_status = ~(CONST.parallel.parallel_pool_num);
CONST.parallel.verbose = 1;

% orders the fields alphabetically
CONST = orderfields(CONST);

end
