function processExp( dirname )
% processExp : main function for running the segmentation software.
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
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins, Nathan Kuwada, Stella Stylianidou.
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

%% Converting other microscopes files
% For example if you are using MicroManager and the file format is the 
% followin : date-strain_00000000t_BF.tif, date-strain_00000000t_GFP.tif,
% you can run convertImageNames(dirname, 'whatever_name_you_want', '', 't',
% '','', {'BF','GFP'} )

basename = 'date-strain';
timeFilterBefore ='t';
timeFilterAfter = '_' ;
xyFilterBefore='_x';
xyFilterAfter='_';
channelNames = {'BF','GFP'};

convertImageNames(dirname, basename, timeFilterBefore, ...
    timeFilterAfter, xyFilterBefore,xyFilterAfter, channelNames )

%% Set the segmentations constants for your bacteria and micrscope resolution
% Using correct resolution ensures correct pixel size and segmentation constants
% if you do not know which constants to use you can run 
% tryDifferentConstants(dirname) with a phase image to choose.
% 60X indicates 100nm/pix and 100X indicates 60nm/pix

% for E. coli we mainly use : 
% '60XEc' : loadConstants 60X Ecoli - 100 nm/pix
% '100XEc': loadConstants 100X Ecoli  - 60 nm/pix

% To see the possible constants type : 
%[~, list] = getConstantsList;
% list'

res = '60XEcLB';

%% Paralell Processing Mode
% to run code in parallel mode must have the parallel processing toolbox,
% for convenience default is false (non-parallel)

parallel_flag = false;

%% Load Constants
CONST = loadConstants(res,parallel_flag) ;

%% Calculation Options
% after you load the constants you can modify them according to your needs
% for more options, looks at the loadConstants file.

CONST.trackLoci.numSpots = [5 0]; % Max number of foci to fit in each fluorescence channel (default = [0 0])
CONST.trackLoci.fluorFlag = false ;    % compute integrated fluorescence (default = true)
CONST.trackOpti.NEIGHBOR_FLAG = false; % calculate number of neighbors (default = false)
CONST.imAlign.AlignChannel = 1; % change this if you want the images to be aligned to fluorescence channel

CONST.view.fluorColor = {'y','r','b'};

%% Skip Frames for Segmentation
% For fast time-lapse or slow growth you can skip phase image frames 
% during segmentation to increase processing speed. Fluorescence images 
% will not be skipped. 

skip = 1;  % segment every frame
%skip = 5; % segment every fifth phase image

%% Clean previous segmented data
% If set to true, will begin processing on aligned images; if false, will 
% try to restart processing at last successful function (default = false)

cleanflag = false;


%% Start running segmentation

BatchSuperSeggerOpti( dirname, skip, cleanflag, CONST);


end
