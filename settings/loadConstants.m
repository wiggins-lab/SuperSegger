function CONST = loadConstants( res, PARALLEL_FLAG )
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
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

if nargin < 1 || isempty( res )
    res = 60;
end

if ~exist('PARALLEL_FLAG','var') || isempty( PARALLEL_FLAG )
    PARALLEL_FLAG = true;
end


disp( 'loadConstants: Initializing.');

% Octoscope setting
CONST.imAlign.DAPI    = [-0.0354   -0.0000    1.5500   -0.3900];
CONST.imAlign.mCherry = [-0.0512   -0.0000   -1.1500    1.0000];
CONST.imAlign.GFP     = [ 0.0000    0.0000    0.0000    0.0000];

CONST.imAlign.out = {CONST.imAlign.GFP, ...    % c1 channel name
    CONST.imAlign.GFP,...  % c2 channel name
    CONST.imAlign.GFP};        % c3 channel name


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% Parallel processing on multiple cores :
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% PARALLEL FOR MATLAB 2015
if PARALLEL_FLAG
    poolobj = gcp('nocreate'); % If no pool, do not create new one.
    if isempty(poolobj)
        poolobj = parpool('local')
    end
    CONST.parallel_pool_num = poolobj.NumWorkers
else
    CONST.parallel_pool_num = 0;
end

CONST.xy_parallel = 0;
CONST.PARALLEL_FLAG = PARALLEL_FLAG;
CONST.show_status   = ~(CONST.parallel_pool_num);

% PARALLEL FOR MATLAB 2014
% if PARALLEL_FLAG
%     if exist( 'matlabpool', 'file' )
%         CONST.parallel_pool_num = matlabpool('size');
%         if ( CONST.parallel_pool_num == 0 )
%             matlabpool
%             try
%                 CONST.parallel_pool_num =  matlabpool('size');
%             catch
%                 distcomp.feature('LocalUseMpiexec',false)
%                 CONST.parallel_pool_num =  matlabpool('size');
%             end
%             disp( ['loadConstants: Parallel processing pool opened. Size ', num2str(CONST.parallel_pool_num),'.' ] );
%             
%         else
%             disp( ['loadConstants: Parallel processing pool already open. Size ', num2str( CONST.parallel_pool_num),'.']);
%         end
%     else
%         disp( 'loadConstants: Attempted to open matlab pool, but no parallel processing toolbox.' );
%         CONST.parallel_pool_num = 0;
%     end
% else
%     CONST.parallel_pool_num = 0;
%     %pause( 2 );
% end
% 
% 
% 
% 
% CONST.PARALLEL_FLAG = PARALLEL_FLAG;
% CONST.show_status   = ~(CONST.parallel_pool_num);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% Specify scope resolution here                                           %
%                                                                         %
% Set the res flag to apply to your exp.                                  %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Values for setting res
%
% '100XPa': loadConstants 100X Pseudomonas
% '60XEc' : loadConstants 60X Ecoli
% '100XEc': loadConstants 100X Ecoli

R100X    = 1; % for 100X unbinned, 6 um pixels
R100XB   = 2; % for 100X 2x2 binned, 6 um pixels
R60X     = 3; % for 60X, 6 um pixels
R100XPa  = 4; % for 100X, Pseudomonas
R60XPa   = 5; % for 60X, Pseudomonas
R60XEcHR = 6; % for 60X, coli slow high density.
R60XEcLB = 7; % for 60X, coli slow high density.
R60XA    = 8; % for 60X, coli ASKA
R60XPaM  = 9; % for 60X, Pseudomonas Minimal
R60XPaM2 = 10; % for 60X, Pseudomonas Minimal
R60XBthai = 11;

CONST.R100X    = R100X;
CONST.R100XB   = R100XB;
CONST.R60X     = R60X;
CONST.R100XPa  = R100XPa;
CONST.R60XPa   = R60XPa;
CONST.R60XEcHR = R60XEcHR;
CONST.R60XEcLB = R60XEcLB;
CONST.R60XA    = R60XA;
CONST.R60XPaM  = R60XPaM;
CONST.R60XPaM2 = R60XPaM2;
CONST.R60XPaM2 = R60XBthai;



cl = class(res);

if strcmp(cl,'double' )   
    if res == 60
        disp('loadConstants: 60X');
        ResFlag = R60X;
    else
        disp('loadConstants:  100X');
        ResFlag = R100X;
    end
elseif strcmp(cl, 'char' );
    if strcmp(res,'100XPa');
        disp('loadConstants:  100X Pseudomonas');
        ResFlag = R100XPa;
    elseif strcmp(res,'60XEc')
        disp('loadConstants:  60X Ecoli');
        ResFlag = R60X;
     elseif strcmp(res,'100XEc')
        disp('loadConstants:  100X Ecoli');
        ResFlag = R100X;
    elseif strcmp(res,'60XPa')
        disp('loadConstants:  60X Pseudomonas');
        ResFlag = R60XPa;
    elseif strcmp(res,'60XEcHR')
        disp('loadConstants:  60X Ecoli Highres');
        ResFlag = R60XEcHR;
    elseif strcmp(res,'60XA')
        disp('loadConstants:  60X ASKA');
        ResFlag = R60XA;
    elseif strcmp(res,'60XEcLB')
        disp('loadConstants:  60X Ecoli LB');
        ResFlag = R60XEcLB;
    elseif strcmp(res,'60XPaM')
        disp('loadConstants:  60X Pseudomonas Minimal');
        ResFlag = R60XPaM;
    elseif strcmp(res,'60XPaM2')
        disp('loadConstants:  60X Pseudomonas Minimal 2');
        ResFlag = R60XPaM2;
    elseif strcmp(res,'60XBthai')
        disp('loadConstants:  60X B Thai');
        ResFlag = R60XBthai;
    else
        disp(' No match found - loading default : loadConstants:  60X Ecoli');
        ResFlag = R60X;
    end
else
    disp(' No match found - loading default : loadConstants:  60X Ecoli');
    ResFlag = R60X;
end


CONST.ResFlag = ResFlag;
CONST.align.ALIGN_FLAG = true;

% This is where the function pointer to the segmentation back-end is set.
% By changing this field you can change the segmentation back-end of
% BatchSuperSeggerOpti.

CONST.seg.segmentScoreFun = @segmentScoreFun
CONST.seg.segFun = @ssoSegFun;

if ResFlag == R60XPaM2
    CONST.seg.segFun = @ssoSegFunPa;
end

% optimize regions based on cell shape (slower)
CONST.seg.OPTI_FLAG = true;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% Parameters used for segmentation by superSeggerOpti                     %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This is the minimum area of cells/cell clumps in the creation of the
% background mask.
CONST.superSeggerOpti.MIN_BG_AREA = 150;

% set a max number of segs so that the code does die when doing big batch
% jobs.
CONST.superSeggerOpti.MAX_SEG_NUM = 10000;

% These constants are used in generating the cell clump mask.
CONST.superSeggerOpti.THRESH1  =   50;
CONST.superSeggerOpti.THRESH2  =    0;
CONST.superSeggerOpti.Amax     = 5000;

% Size in pixels of the structuring element in the contrast-enhancing filter. It
% should be proportional to the width of a cell.
if ResFlag == R60X
    CONST.superSeggerOpti.MAGIC_RADIUS =  6;
    CONST.superSeggerOpti.CUT_INT      = 70;
    CONST.superSeggerOpti.Amax         = 1000;
    CONST.superSeggerOpti.MAX_SEG_NUM  = 10000000;
elseif ResFlag == R60XEcHR
    CONST.superSeggerOpti.MAGIC_RADIUS =  5;
    CONST.superSeggerOpti.CUT_INT      = 70;
elseif ResFlag == R60XPa
    CONST.superSeggerOpti.MAGIC_RADIUS =  5;
    CONST.superSeggerOpti.CUT_INT      = 100;
elseif ResFlag == R60XEcLB
    CONST.superSeggerOpti.MAGIC_RADIUS =  6;
    CONST.superSeggerOpti.CUT_INT      = 70;
elseif ResFlag == R100X
    CONST.superSeggerOpti.MAGIC_RADIUS =  6;
    CONST.superSeggerOpti.CUT_INT      = 50;
elseif ResFlag == R100XPa
    CONST.superSeggerOpti.MAGIC_RADIUS =  6;
    CONST.superSeggerOpti.CUT_INT      = 50;
    CONST.superSeggerOpti.MAX_SEG_NUM = 10000000;
elseif ResFlag == R60XA
    CONST.superSeggerOpti.MAGIC_RADIUS =  6;
    CONST.superSeggerOpti.CUT_INT      = 50;
    CONST.superSeggerOpti.Amax         = 80;
elseif (ResFlag == R60XPaM)
    CONST.superSeggerOpti.MAGIC_RADIUS =  6;
    CONST.superSeggerOpti.CUT_INT      = 50;
    CONST.superSeggerOpti.Amax         = 80;
    CONST.superSeggerOpti.MAX_SEG_NUM  = 10000000;
elseif (ResFlag == R60XPaM2)
    CONST.superSeggerOpti.MAGIC_RADIUS =  3;
    CONST.superSeggerOpti.CUT_INT      = 50;
    CONST.superSeggerOpti.Amax         = 80;
    CONST.superSeggerOpti.MAX_SEG_NUM  = 10000000;
    CONST.superSeggerOpti.MIN_BG_AREA = 30;
elseif (ResFlag == R60XBthai)
    CONST.superSeggerOpti.MAGIC_RADIUS =  3;
    CONST.superSeggerOpti.CUT_INT      = 50;
    CONST.superSeggerOpti.Amax         = 150;
    CONST.superSeggerOpti.MAX_SEG_NUM  = 10000000;
    CONST.superSeggerOpti.MIN_BG_AREA  = 30;
    CONST.superSeggerOpti.THRESH1      = 85;
    CONST.superSeggerOpti.THRESH2      = 40;
end

% Intensity threshold for output of the contrast enhancement. it should be
% a number close to zero. Intensities below it are set to zero.
CONST.superSeggerOpti.MAGIC_THRESHOLD = 5;

% Intensity threshold to define good segments. Segments which intersect a
% pixel whose intensity is lower than this number are bad segments.
CONST.superSeggerOpti.MIN_THRESHOLD = 10;

% Another intensity threshold to define good segments. If the mean
% intensity of all pixels intersected by a segment is less than this
% number, the segment is bad.
CONST.superSeggerOpti.MEAN_THRESHOLD = 18;

% Width in pixels of the gaussian used to smooth the raw phase image. It
% should be on the order of a pixel.
if ResFlag == R60X
    CONST.superSeggerOpti.SMOOTH_WIDTH = 1;
elseif ResFlag == R60XEcHR
    CONST.superSeggerOpti.SMOOTH_WIDTH = 1/2;
elseif ResFlag == R100X
    CONST.superSeggerOpti.SMOOTH_WIDTH = 1;
elseif ResFlag == R100XPa
    CONST.superSeggerOpti.SMOOTH_WIDTH = 1;
elseif ResFlag == R60XA
    CONST.superSeggerOpti.SMOOTH_WIDTH = 1;
elseif ResFlag == R60XPaM
    CONST.superSeggerOpti.SMOOTH_WIDTH = 1;
elseif ResFlag == R60XPaM2
    CONST.superSeggerOpti.SMOOTH_WIDTH = 1;
elseif ResFlag == R60XBthai
    CONST.superSeggerOpti.SMOOTH_WIDTH = 1;
elseif ResFlag == R60XPa
    CONST.superSeggerOpti.SMOOTH_WIDTH = 1;
elseif ResFlag == R60XEcLB
    CONST.superSeggerOpti.SMOOTH_WIDTH = 1;
end

% MAX_WIDTH
% Width threshold for the iterative segment refinement. Masked regions
% whose minor axis is greater than this number are considered for further
% segmentation. All other masked regions are assumed to correctly define
% a cell.
if ResFlag == R60X
    CONST.superSeggerOpti.MAX_WIDTH = 10;
    CONST.superSeggerOpti.crop_rad  =  2;
elseif ResFlag == R100X
    CONST.superSeggerOpti.MAX_WIDTH = 20;
    CONST.superSeggerOpti.crop_rad  =  2;
elseif ResFlag == R100XPa
    CONST.superSeggerOpti.MAX_WIDTH = 20;
    CONST.superSeggerOpti.crop_rad  =  2;
elseif ResFlag == R60XA
    CONST.superSeggerOpti.MAX_WIDTH = 20;
    CONST.superSeggerOpti.crop_rad  =  2;
elseif ResFlag == R60XPaM
    CONST.superSeggerOpti.MAX_WIDTH = 10;
    CONST.superSeggerOpti.crop_rad  =  2;
elseif ResFlag == R60XPaM2
    CONST.superSeggerOpti.MAX_WIDTH = 10;
    CONST.superSeggerOpti.crop_rad  =  2;
elseif ResFlag == R60XBthai
    CONST.superSeggerOpti.MAX_WIDTH = 10;
    CONST.superSeggerOpti.crop_rad  =  2;
elseif ResFlag == R60XPa
    CONST.superSeggerOpti.MAX_WIDTH = 10;
    CONST.superSeggerOpti.crop_rad  =  2;
elseif ResFlag == R60XEcLB
    CONST.superSeggerOpti.MAX_WIDTH = 20;
    CONST.superSeggerOpti.crop_rad  =  2;
end


% A is the vector used to generate the segment score.
if ResFlag == R60X
    tmp = load( 'Ec60.mat' );
elseif ResFlag == R60XEcHR
    tmp = load( 'Ec60.mat' );
elseif ResFlag == R100X
    tmp = load( 'Ec100X.mat' );
elseif ResFlag == R100XPa
    tmp = load( 'Pseud.mat' );
elseif ResFlag == R60XA
    tmp = load( 'Ec60XASKA.mat' );
elseif ResFlag == R60XPaM
    tmp = load( 'Pseud60Min.mat' );
elseif ResFlag == R60XPaM2
    tmp = load( 'Pseud60Min.mat' );
elseif ResFlag == R60XBthai
    tmp = load( 'Bthai.mat' );
elseif ResFlag == R60XPa
    tmp = load( 'Pseud60.mat' );
elseif ResFlag == R60XEcLB
    tmp = load( 'Ec60XLB.mat' );
end

CONST.superSeggerOpti.A = tmp.A;
CONST.superSeggerOpti.NUM_INFO = 19;




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% Constants for regionOpti                                                %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% MAX_NUM_RESOLVE is the max number of segments that regionOpti will try
% to explore systematically (vs simulated anneal). With the current
% incarnation of the code, the speed crossover is about 8.
CONST.regionOpti.MAX_NUM_RESOLVE    = 5000;
CONST.regionOpti.MAX_NUM_SYSTEMATIC = 8;

% regionOpti explores turning on and off segments that have marginal
% scores and tries to optimize the cell score computed by regionScoreFun--
% constants below. Margninal is defined as
% CutOffScoreHi < scoreRaw < CutOffScoreLo
CONST.regionOpti.CutOffScoreHi =  5;
CONST.regionOpti.CutOffScoreLo = -5;
CONST.regionOpti.Emax          = 1e2;
CONST.regionOpti.fignum        = 1;
CONST.regionOpti.dt            = 50;
CONST.regionOpti.Nt            = 500;

% per region opti constants 
CONST.regionOpti.minGoodRegScore = 0; % regions with scores below this are optimized
CONST.regionOpti.neighMaxScore = 5; % neighbors with scores below this are used to optimize the small regions


% automatically length sim anneal period linearly with the number of
% segments
CONST.regionOpti.ADJUST_FLAG   = true;

% For regionOpti, this is  minimum region size, below which neighbor 
% segments are switched on during optimization.
CONST.regionOpti.MAX_WIDTH  = CONST.superSeggerOpti.MAX_WIDTH;

% For regionOpti, this is  minimum region size, below which neighbor 
% segments are switched on during optimization - should be named
% MIN_LENGTH.
if ResFlag == R60X
    CONST.regionOpti.MAX_LENGTH  = 15;
elseif ResFlag == R60XEcHR
    CONST.regionOpti.MAX_LENGTH  = 15;
elseif ResFlag == R100X
    CONST.regionOpti.MAX_LENGTH  = 25;
elseif ResFlag == R100XPa
    CONST.regionOpti.MAX_LENGTH  = 25;
elseif ResFlag == R60XA
    CONST.regionOpti.MAX_LENGTH  = 25;
elseif ResFlag == R60XPaM
    CONST.regionOpti.MAX_LENGTH  = 8;
elseif ResFlag == R60XPaM2
    CONST.regionOpti.MAX_LENGTH  = 8;
elseif ResFlag == R60XBthai
    CONST.regionOpti.MAX_LENGTH  = 8;
elseif ResFlag == R60XPa
    CONST.regionOpti.MAX_LENGTH  = 10;
elseif ResFlag == R60XEcLB
    CONST.regionOpti.MAX_LENGTH  = 25;
end

% To calculate the total score:
% Score_Total = Score_Cell + DE_norm * ( -Score_SegOn + Score_SegOff )
% DE_norm controls the relative importance of segment scores versus cell
% scores.
CONST.regionOpti.DE_norm = 0.5;



%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% Constants for regionScoreFun                                            %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% L20 is the optimal cell width
% L10 is the lower soft cutoff of cell length
% mu is a score constant.
% E0 is the multiplier that sets the balance between cell width and cell
% length.
if ResFlag == R60X
    CONST.regionScoreFun.NUM_INFO = 21;
    CONST.regionScoreFun.fun      = @regionScoreFunMatrix;
    CONST.regionScoreFun.props    = @cellprops5;
    CONST.regionScoreFun.E        = tmp.E;
    CONST.regionScoreFun.names    = @getRegNames3;
elseif ResFlag == R60XEcHR
    CONST.regionScoreFun.E        = tmp.E;
    CONST.regionScoreFun.NUM_INFO = 11;
    CONST.regionScoreFun.fun      = @regionScoreFun0;
    CONST.regionScoreFun.props    = @cellprops0;
elseif ResFlag == R60XEcLB
    CONST.regionScoreFun.E        = tmp.E;
    CONST.regionScoreFun.NUM_INFO = 8;
    CONST.regionScoreFun.fun      = @regionScoreFunPseud2;
    CONST.regionScoreFun.props    = @cellpropsPseud;
elseif ResFlag == R100X
    CONST.regionScoreFun.E        = tmp.E;
    CONST.regionScoreFun.NUM_INFO = 21;
    CONST.regionScoreFun.fun      = @regionScoreFunMatrix;
    CONST.regionScoreFun.props    = @cellprops3;   
elseif ResFlag == R100XPa
    CONST.regionScoreFun.E        = tmp.E;
    CONST.regionScoreFun.NUM_INFO = 8;
    CONST.regionScoreFun.fun      = @regionScoreFunPseud2;
    CONST.regionScoreFun.props    = @cellpropsPseud;
elseif ResFlag == R60XA
    CONST.regionScoreFun.E        = tmp.E;
    CONST.regionScoreFun.NUM_INFO = 21;
    CONST.regionScoreFun.fun      = @regionScoreFunMatrix;
    CONST.regionScoreFun.props    = @cellprops3;
elseif ResFlag == R60XPaM
    CONST.regionScoreFun.E        = tmp.E;
    CONST.regionScoreFun.NUM_INFO = 21;
    CONST.regionScoreFun.fun      = @regionScoreFunMatrix;
    CONST.regionScoreFun.props    = @cellprops3;
elseif ResFlag == R60XPaM2
    CONST.regionScoreFun.E        = tmp.E;
    CONST.regionScoreFun.NUM_INFO = 21;
    CONST.regionScoreFun.fun      = @regionScoreFunMatrix;
    CONST.regionScoreFun.props    = @cellprops3;
elseif ResFlag == R60XBthai
    CONST.regionScoreFun.E        = tmp.E;
    CONST.regionScoreFun.NUM_INFO = 21;
    CONST.regionScoreFun.fun      = @regionScoreFunMatrix;
    CONST.regionScoreFun.props    = @cellprops3;
elseif ResFlag == R60XPa    
    CONST.regionScoreFun.NUM_INFO = 21;
    CONST.regionScoreFun.fun      = @regionScoreFunMatrix;
    CONST.regionScoreFun.props    = @cellprops3;
    CONST.regionScoreFun.E        = tmp.E;
    CONST.regionScoreFun.names    = @getRegNames3;
end


CONST.trackOpti.MIN_AREA = 12;


%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% Constants for trackOpti                                                 %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% trackOpti.
% OVERLAP_LIMIT_MIN: defines overlap between frames
% OVERLAP_LIMIT_MAX: no longer used.
% AREA_CHANGE_LIMIT: No longer used.
% dA_LIMIT_ErRes   : area ratio necessary for 1 to 1.
% dA_LIMIT         : if min(A_1,A_2)/max(A_1,A_2) < dA_Limit set a mapping error
% SCORE_LIMIT      : no longer used
% SCORE_LIMIT_DAUGHTER : limiting score for daughter cell on cell division
% SCORE_LIMIT_MOTHER   : limiting score for mother cell on cell division

% THIS TURNS ON FUNCTIONALITY TO GUESS NEW AND OLD POLES IN RECENCTLY
% DIVIDED CELLS IN A SNAPSHOT ANALYISIS
CONST.trackOpti.pole_flag             = 1 ;
CONST.trackOpti.FSKIP_FLAG            = true;

% lysis detection
CONST.trackOpti.LYSE_FLAG        = false;
CONST.trackOpti.MERGED_FLAG     = true;
CONST.trackOpti.HARDLINK_FLAG   = false;
CONST.trackOpti.DA_MAX          =  0.2;
CONST.trackOpti.DA_MIN          = -0.2;


if ResFlag == R100X
    CONST.trackOpti.REMOVE_STRAY      = 1;
    CONST.trackOpti.NEIGHBOR_FLAG     = 0;    
    CONST.trackOpti.OVERLAP_LIMIT_MIN = 0.08;
    CONST.trackOpti.OVERLAP_LIMIT_MAX = 0.8;
    CONST.trackOpti.AREA_CHANGE_LIMIT = 0.2;
    CONST.trackOpti.dA_LIMIT_ErRes    = 0.8;
    CONST.trackOpti.dA_LIMIT          = 0.7;
    CONST.trackOpti.MAX_WIDTH         = CONST.regionOpti.MAX_WIDTH;   
    CONST.trackOpti.SCORE_LIMIT       = -1;
    CONST.trackOpti.SCORE_LIMIT_DAUGHTER = -1;
    CONST.trackOpti.SCORE_LIMIT_MOTHER   = -1;
    CONST.trackOpti.MIN_CELL_AGE      = 3;
    
elseif ResFlag == R60X
    CONST.trackOpti.REMOVE_STRAY      = 0;
    CONST.trackOpti.NEIGHBOR_FLAG     = 0;
    CONST.trackOpti.OVERLAP_LIMIT_MIN = 0.08;
    CONST.trackOpti.OVERLAP_LIMIT_MAX = 0.8;
    CONST.trackOpti.AREA_CHANGE_LIMIT = 0.2;
    CONST.trackOpti.dA_LIMIT_ErRes    = 0.7;
    CONST.trackOpti.dA_LIMIT          = 0.7;
    CONST.trackOpti.MAX_WIDTH         = CONST.regionOpti.MAX_WIDTH;    
    CONST.trackOpti.SCORE_LIMIT       = -15;
    CONST.trackOpti.SCORE_LIMIT_DAUGHTER = -5;
    CONST.trackOpti.SCORE_LIMIT_MOTHER   = -15;
    CONST.trackOpti.MIN_CELL_AGE      = 1;
    
elseif ResFlag == R100XPa
    CONST.trackOpti.REMOVE_STRAY      = 0;
    CONST.trackOpti.NEIGHBOR_FLAG     = 0;    
    CONST.trackOpti.OVERLAP_LIMIT_MIN = 0.08;
    CONST.trackOpti.OVERLAP_LIMIT_MAX = 0.8;
    CONST.trackOpti.AREA_CHANGE_LIMIT = 0.2;
    CONST.trackOpti.dA_LIMIT_ErRes    = 0.7;
    CONST.trackOpti.dA_LIMIT          = 0.7;
    CONST.trackOpti.MAX_WIDTH         = CONST.regionOpti.MAX_WIDTH;    
    CONST.trackOpti.SCORE_LIMIT       = -15;
    CONST.trackOpti.SCORE_LIMIT_DAUGHTER = -5;
    CONST.trackOpti.SCORE_LIMIT_MOTHER   = -15;
    CONST.trackOpti.MIN_CELL_AGE      = 5;
    
elseif ResFlag == R60XA
    CONST.trackOpti.REMOVE_STRAY      = 0;
    CONST.trackOpti.NEIGHBOR_FLAG     = 0;   
    CONST.trackOpti.OVERLAP_LIMIT_MIN = 0.08;
    CONST.trackOpti.OVERLAP_LIMIT_MAX = 0.8;
    CONST.trackOpti.AREA_CHANGE_LIMIT = 0.2;
    CONST.trackOpti.dA_LIMIT_ErRes    = 0.7;
    CONST.trackOpti.dA_LIMIT          = 0.7;
    CONST.trackOpti.MAX_WIDTH         = CONST.regionOpti.MAX_WIDTH;
    CONST.trackOpti.SCORE_LIMIT       = -15;
    CONST.trackOpti.SCORE_LIMIT_DAUGHTER = -5;
    CONST.trackOpti.SCORE_LIMIT_MOTHER   = -15;
    CONST.trackOpti.MIN_CELL_AGE      = 5;
    
elseif ResFlag == R60XPaM
    CONST.trackOpti.REMOVE_STRAY      = 0;
    CONST.trackOpti.NEIGHBOR_FLAG     = true;
    CONST.trackOpti.OVERLAP_LIMIT_MIN = 0.08;
    CONST.trackOpti.OVERLAP_LIMIT_MAX = 0.8;
    CONST.trackOpti.AREA_CHANGE_LIMIT = 0.2;
    CONST.trackOpti.dA_LIMIT_ErRes    = 0.7;
    CONST.trackOpti.dA_LIMIT          = 0.7;
    CONST.trackOpti.MAX_WIDTH         = CONST.regionOpti.MAX_WIDTH;
    CONST.trackOpti.SCORE_LIMIT       = -15;
    CONST.trackOpti.SCORE_LIMIT_DAUGHTER = -5;
    CONST.trackOpti.SCORE_LIMIT_MOTHER   = -15;
    CONST.trackOpti.MIN_CELL_AGE      = 5;
    
elseif ResFlag == R60XPaM2
    CONST.trackOpti.REMOVE_STRAY      = 0;
    CONST.trackOpti.NEIGHBOR_FLAG     = true;    
    CONST.trackOpti.OVERLAP_LIMIT_MIN = 0.08;
    CONST.trackOpti.OVERLAP_LIMIT_MAX = 0.8;
    CONST.trackOpti.AREA_CHANGE_LIMIT = 0.2;
    CONST.trackOpti.dA_LIMIT_ErRes    = 0.7;
    CONST.trackOpti.dA_LIMIT          = 0.7;
    CONST.trackOpti.MAX_WIDTH         = CONST.regionOpti.MAX_WIDTH;    
    CONST.trackOpti.SCORE_LIMIT       = -15;
    CONST.trackOpti.SCORE_LIMIT_DAUGHTER = -5;
    CONST.trackOpti.SCORE_LIMIT_MOTHER   = -15;
    CONST.trackOpti.MIN_CELL_AGE      = 5;    
    CONST.trackOpti.LYSE_FLAG             = true;
    CONST.trackOpti.FLUOR1_CHANGE_MIN     = .2;
    CONST.trackOpti.FLUOR2_CHANGE_MIN     = .2;
    CONST.trackOpti.LSPHEREMIN            = 10;
    CONST.trackOpti.LSPHEREMAX            = 20;
    CONST.trackOpti.ECCENTRICITY          = .7;
elseif ResFlag == R60XBthai
    CONST.trackOpti.REMOVE_STRAY      = 0;
    CONST.trackOpti.NEIGHBOR_FLAG     = true;    
    CONST.trackOpti.OVERLAP_LIMIT_MIN = 0.08;
    CONST.trackOpti.OVERLAP_LIMIT_MAX = 0.8;
    CONST.trackOpti.AREA_CHANGE_LIMIT = 0.2;
    CONST.trackOpti.dA_LIMIT_ErRes    = 0.7;
    CONST.trackOpti.dA_LIMIT          = 0.7;
    CONST.trackOpti.MAX_WIDTH         = CONST.regionOpti.MAX_WIDTH;    
    CONST.trackOpti.SCORE_LIMIT       = -15;
    CONST.trackOpti.SCORE_LIMIT_DAUGHTER = -5;
    CONST.trackOpti.SCORE_LIMIT_MOTHER   = -15;
    CONST.trackOpti.MIN_CELL_AGE      = 5;    
    CONST.trackOpti.LYSE_FLAG             = true;
    CONST.trackOpti.FLUOR1_CHANGE_MIN     = .2;
    CONST.trackOpti.FLUOR2_CHANGE_MIN     = .2;
    CONST.trackOpti.LSPHEREMIN            = 10;
    CONST.trackOpti.LSPHEREMAX            = 20;
    CONST.trackOpti.ECCENTRICITY          = .7;
elseif ResFlag == R60XPa
    CONST.trackOpti.REMOVE_STRAY      = 0;
    CONST.trackOpti.NEIGHBOR_FLAG     = 1;    
    CONST.trackOpti.OVERLAP_LIMIT_MIN = 0.08;
    CONST.trackOpti.OVERLAP_LIMIT_MAX = 0.8;
    CONST.trackOpti.AREA_CHANGE_LIMIT = 0.2;
    CONST.trackOpti.dA_LIMIT_ErRes    = 0.7;
    CONST.trackOpti.dA_LIMIT          = 0.7;
    CONST.trackOpti.MAX_WIDTH         = CONST.regionOpti.MAX_WIDTH;
    CONST.trackOpti.SCORE_LIMIT       = -15;
    CONST.trackOpti.SCORE_LIMIT_DAUGHTER = -5;
    CONST.trackOpti.SCORE_LIMIT_MOTHER   = -15;
    CONST.trackOpti.MIN_CELL_AGE      = 5;
    
elseif ResFlag == R60XEcHR
    CONST.trackOpti.REMOVE_STRAY      = 0;
    CONST.trackOpti.NEIGHBOR_FLAG     = 0;
    CONST.trackOpti.OVERLAP_LIMIT_MIN = 0.08;
    CONST.trackOpti.OVERLAP_LIMIT_MAX = 0.8;
    CONST.trackOpti.AREA_CHANGE_LIMIT = 0.2;
    CONST.trackOpti.dA_LIMIT_ErRes    = 0.7;
    CONST.trackOpti.dA_LIMIT          = 0.7;
    CONST.trackOpti.MAX_WIDTH         = CONST.regionOpti.MAX_WIDTH;
    CONST.trackOpti.SCORE_LIMIT       = -15;
    CONST.trackOpti.SCORE_LIMIT_DAUGHTER = -5;
    CONST.trackOpti.SCORE_LIMIT_MOTHER   = -15;
    CONST.trackOpti.MIN_CELL_AGE      = 5;
    
elseif ResFlag == R60XEcLB
    CONST.trackOpti.REMOVE_STRAY      = 0;
    CONST.trackOpti.NEIGHBOR_FLAG     = 0;   
    CONST.trackOpti.OVERLAP_LIMIT_MIN = 0.08;
    CONST.trackOpti.OVERLAP_LIMIT_MAX = 0.8;
    CONST.trackOpti.AREA_CHANGE_LIMIT = 0.2;
    CONST.trackOpti.dA_LIMIT_ErRes    = 0.7;
    CONST.trackOpti.dA_LIMIT          = 0.7;
    CONST.trackOpti.MAX_WIDTH         = CONST.regionOpti.MAX_WIDTH;   
    CONST.trackOpti.SCORE_LIMIT       = -15;
    CONST.trackOpti.SCORE_LIMIT_DAUGHTER = -5;
    CONST.trackOpti.SCORE_LIMIT_MOTHER   = -15;
    CONST.trackOpti.MIN_CELL_AGE      = 5;
end




%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% Constants for trackLoci                                                 %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%    CONST.trackLoci.crop      : size of region cropped out of fluor image to fit loci;
%
%    CONST.trackLoci.numSpots  : numSpots[j] Array of the max number of loci to fit in channel
%                              : empty leads to no spots fit.
%    For example
%    CONST.trackLoci.numSpots = [3 2] will find:
%                                     * up to 3 spots in channel 2 (fluor1)
%                                     * up to 2 spots in channel 3 (fluor2)
%                                     * 0 spots in subsequent channels
%
%    CONST.trackLoci.fluorFlag : Computes statistics of fluorescence image
%                              : for each cell
%                              : These include the summed fluor intensity
%                              : the center of intensity
%                              : and the second moments of the intensity
%                              : distribution
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CONST.trackLoci.gaussR = 1;


if ResFlag == R60X
    CONST.trackLoci.crop = 4;
    CONST.trackLoci.numSpots  = [];
    CONST.trackLoci.fluorFlag = 1;
elseif ResFlag == R100XB
    CONST.trackLoci.crop = 2;
    CONST.trackLoci.numSpots = [];
    CONST.trackLoci.fluorFlag = 0;
elseif ResFlag == R100X
    CONST.trackLoci.crop = 4;
    CONST.trackLoci.numSpots = [];
    CONST.trackLoci.fluorFlag = 0;
    CONST.trackLoci.gaussR = 1.5;    
elseif ResFlag == R100XPa
    CONST.trackLoci.crop = 6;
    CONST.trackLoci.numSpots = [4];
    CONST.trackLoci.fluorFlag = 0;
elseif ResFlag == R60XA
    CONST.trackLoci.crop = 4;
    CONST.trackLoci.numSpots = [];
    CONST.trackLoci.fluorFlag = 1;
elseif ResFlag == R60XPaM
    CONST.trackLoci.crop = 4;
    CONST.trackLoci.numSpots = [];
    CONST.trackLoci.fluorFlag = 1;
elseif ResFlag == R60XPaM2
    CONST.trackLoci.crop = 4;
    CONST.trackLoci.numSpots = [0,3];
    CONST.trackLoci.fluorFlag = 1;
elseif ResFlag == R60XBthai
    CONST.trackLoci.crop = 4;
    CONST.trackLoci.numSpots = [0,3];
    CONST.trackLoci.fluorFlag = 1;
elseif ResFlag == R60XPa
    CONST.trackLoci.crop = 4;
    CONST.trackLoci.numSpots = [];
    CONST.trackLoci.fluorFlag = 1;
elseif ResFlag == R60XEcHR
    CONST.trackLoci.crop = 4;
    CONST.trackLoci.numSpots = [];
    CONST.trackLoci.fluorFlag = 0;
elseif ResFlag == R60XEcLB
    CONST.trackLoci.crop = 4;
    CONST.trackLoci.numSpots = [];
    CONST.trackLoci.fluorFlag = 0;
end


% Do gating....
if ResFlag == R60XA
    gate_file_name = 'default_gate.mat';
    if exist(gate_file_name, 'file' );
        disp(['loading default gate file: ', gate_file_name] );
        tmp = load(gate_file_name);
        CONST.trackLoci.gate = tmp.gate;
    else
        CONST.trackLoci.gate = [];
    end
else
    CONST.trackLoci.gate = [];
end

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% Constants for getLocusTracks                                            %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
CONST.getLocusTracks.FLUOR1_MIN_SCORE = 1;
CONST.getLocusTracks.FLUOR2_MIN_SCORE = 3;
CONST.getLocusTracks.FLUOR1_REL       = 0.3;
CONST.getLocusTracks.FLUOR2_REL       = 0.3;
CONST.getLocusTracks.TimeStep         = 1;

if ResFlag == R60X
    CONST.getLocusTracks.PixelSize        = 6/60;
elseif ResFlag == R100XB
    CONST.getLocusTracks.PixelSize        = 6/100;
elseif ResFlag == R100X
    CONST.getLocusTracks.PixelSize        = 6/100;
elseif ResFlag == R100XPa
    CONST.getLocusTracks.PixelSize        = 6/100;
elseif ResFlag == R60XA
    CONST.getLocusTracks.PixelSize        = 6/60;
elseif ResFlag == R60XPaM
    CONST.getLocusTracks.PixelSize        = 6/60;
elseif ResFlag == R60XPaM2
    CONST.getLocusTracks.PixelSize        = 6/60;
elseif ResFlag == R60XBthai
    CONST.getLocusTracks.PixelSize        = 6/60;
elseif ResFlag == R60XPa
    CONST.getLocusTracks.PixelSize        = 6/60;
elseif ResFlag == R60XEcHR
    CONST.getLocusTracks.PixelSize        = 6/60;
elseif ResFlag == R60XEcLB
    CONST.getLocusTracks.PixelSize        = 6/60;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Const for trackOptiView / superSeggerViewer
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CONST.view.showFullCellCycleOnly = true;
CONST.view.orientFlag            = true;
CONST.view.falseColorFlag        = false;
CONST.view.maxNumCell            = [];

% show log fluor reduce variation at high intensity
CONST.view.LogView         = false;

if ResFlag == R60XPaM2
    CONST.trackOpti.LogView               = true;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Const for consesnus
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CONST.consensus = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Const for findFocusSR
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Const for SR
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
CONST.SR.rcut = 10; % The maximum distance between frames that two PSFs 
% can be before they are considered two seperate PSFs.
% If there is more separation than this from one frame to the next they 
% will be considered two seperate PSFs!


% this is the threshold intensity for including loci in analysis measured
% in std
CONST.SR.Ithresh = 2;

end
