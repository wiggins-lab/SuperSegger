function processExp( dirname )
% processExp main function for running the segmentation software.
% Used to choose the appropriate settings, and converting the images
% filenames before running BatchSuperSeggerOpti.
% Images need to have the NIS-Elements Format, or they can be converted 
% using convertImageNames.
%
% the naming convention of the image files must be of the following format
% time, xy-positions, fluorescence channel, where c1 is bright field 
% and c2,c3 etc are different fluorescent channels 
% Example of two time points, two xy positions and one fluorescent channel
% filename_t001xy1c1.tif
% filename_t001xy1c2.tif
% filename_t001xy2c1.tif
% filename_t001xy2c2.tif
% filename_t002xy1c1.tif
% filename_t002xy1c2.tif
% filename_t002xy2c1.tif
% filename_t002xy2c2.tif
%
% INPUT :
%       dirname : folder that contains .tif images in NIS elements format. 
% 
% 
%
% Copyright (C) 2016 Wiggins Lab 
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.


%% Converting other microscopes files
% For example if you are using MicroManager and the file format is the 
% followin : date-strain_00000000t_BF.tif, date-strain_00000000t_GFP.tif,
% you can run convertImageNames(dirname, 'whatever_name_you_want', '', 't',
% '','', {'BF','GFP'} )


basename = 'date-strain';
timeFilterBefore ='_';
timeFilterAfter = 't' ;
xyFilterBefore='';
xyFilterAfter='';
channelNames = {'BF','GFP'};

convertImageNames(dirname, basename, timeFilterBefore, ...
    timeFilterAfter, xyFilterBefore,xyFilterAfter, channelNames )

%% Micrscope Resolution
% Using correct resolution ensures correct pixel size and segmentation constants
% '60XEc' : loadConstants 60X Ecoli
% '100XEc': loadConstants 100X Ecoli
res = '60XEc';

%% Paralell Processing Mode
% to run code in parallel mode must have the parallel processing toolbox,
% for convenience default is false (non-parallel)

parallel_flag = true;

%% Load Constants
CONST = loadConstants(res,parallel_flag) ;

%% Calculation Options
% after you load the constants you can modify them according to your needs
% for more options, looks at the loadConstants file.

CONST.trackLoci.numSpots = [5]; % Max number of foci to fit in each fluorescence channel (default = [0 0])
CONST.trackLoci.fluorFlag = true ;    % compute integrated fluorescence (default = true)
CONST.trackOpti.NEIGHBOR_FLAG = false; % calculate number of neighbors (default = false)
CONST.consensus = false; % calculate consensus images for each XY position (Default = true)

%% Skip Frames for Segmentation
% For fast time-lapse or slow growth you can skip phase image frames 
% during segmentation to increase processing speed. Fluorescnce images 
% will not be skipped. 

skip = 1;  % don't skip any phase images while segmenting
%skip = 5; % set skip to five to segment only every fifth phase image

%% Initialize Data for Segmentation
% If set to true, will begin processing on aligned images; if false, will 
% try to restart processing at last successful function (default = false)
cleanflag = false;


%% Start running segmentation

BatchSuperSeggerOpti( dirname, skip, cleanflag, CONST);


end