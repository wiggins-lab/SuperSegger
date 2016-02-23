function processExp( dirname )
% processExp main function for running the segmentation software.
% Used to choose the appropriate settings, and converting the images
% filenames before running BatchSuperSeggerOpti.
% Parameters :
% dirname : folder that contains .tif images. Images need to have the
% NIS-Elements Format, or the MicroManagerFormat
% 
%
% Copyright (C) 2016 Wiggins Lab 
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.

%% File Naming Format (NIS-Elements Format)
% the naming of the image files must be of the following format :
% time, xy-positions, fluorescence channel, where c1 is bright field 
% and c2,c3 etc can be the different fluorescent channels 
% Example of two time points, two xy positions and one fluorescent channel
% filename_t001xy1c1.tif
% filename_t001xy1c2.tif
% filename_t001xy2c1.tif
% filename_t001xy2c2.tif
% filename_t002xy1c1.tif
% filename_t002xy1c2.tif
% filename_t002xy2c1.tif
% filename_t002xy2c2.tif

%% Converting MicroManager Files
% MicroManager images can be converted for a single XY postition. 
% To do so include "BF" in the phase image and a unique identifier 
% "fluorFilt" for the fluorescence images, e.g. "488" for GFP, 
% and run the following function

fluorFilt = 'gfp';

%convertMMnames(dirname,fluorFilt);

%% Micrscope Resolution
% Using correct resolution ensures correct pixel size and segmentation constants
% '60XEc' : loadConstants 60X Ecoli
% '100XEc': loadConstants 100X Ecoli
res = '60XEc';

%% Paralell Processing Mode
%
% to run code in parallel mode must have parallel processing toolbox,
% for convenience default is false (non-parallel)
parallel_flag = false;

%% Load Constants
CONST = loadConstants(res,parallel_flag) ;

%% Calculation Options

CONST.trackLoci.numSpots = [ 5 0 ]; % Max number of foci to fit in each channel (default = [0 0])
CONST.trackLoci.fluorFlag = true ;    % compute integrated fluorescence (default = true)
CONST.trackOpti.NEIGHBOR_FLAG = true; % calculate number of neighbors (default = false)
CONST.consensus = false; % calculate consensus images for each XY position (Default = true)

%% Skip Frames for Segmentation
% For fast time-lapse or slow growth you can skip phase image frames during segmentation to 
% increase processing speed. Fluorescnce images will NOT be skipped. 

skip = 1;  % don't skip any phase images while segmenting
%skip = 5; % set skip to five to segment only every fifth phase image

%% Initialize Data for Segmentation
%
% If set to true, will begin processing on aligned images; if false, will try to restart processing
% at last successful function (default = false)

cleanflag = false;


%% Run Segmentation

BatchSuperSeggerOpti( dirname, skip, cleanflag, CONST);


end