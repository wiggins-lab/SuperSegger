function [ I_left_pole, I_right_pole, Itot ] = singleCellManipul( filename )
% single_cell.m : Boot camp example for using a cell file. 
% There are parts in the function that the user needs to complete.
%
% INPUT : 
%   filename : cell file the bootcamp uses
% OUTPUT : 
%    I_left_pole : intensity in the first 20% of the cell
%    I_right_pole : intensity in the right 20% of the cell
%    Itot : total intensity
%
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Stylianidou, Nathan Kuwada, Paul Wiggins
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



%% Init the functions
% provide a default filename... don't worry to much about this
if ~exist( 'filename', 'var' ) || isempty( filename )
    % the disp function writes onto the sceen...
    % single quotes are used to make strings.
    disp( ['No argument has been passed so I am opening the', ...
           'default file.'] );
       
    filename = 'exampleCellFiles/Cell0000013.mat';
end

%% Load data
% we will load up some data to analyze from a file. The load command
% 'opens' the data file and places the variable in memory.

disp( ['Opening the file ', filename ] );
data = load( filename );

%% Display the contents of the cell file
disp(data)

%% Get the images from the data file
% images are matrices. The rows and columns contain the pixel intensities.

% look at the third time step
time_step = 3;

phase  = data.CellA{time_step}.phase;  % phase image
fluor1 = data.CellA{time_step}.fluor1; % fluor image


%% View an image
% Open a new figure 
figure(1);
% clear the figure
clf;

% show the image
imshow( phase, [] );

% A Look Up Table (LUT) is used to convert the intensity values to colors/
% intensities on the screen. Passing [] as the second argument of imshow
% tells the function to choose the LUT automatically.

%% Make a multi-channel image. 
% Often one wants to superimpose the phase and fluor images to make a
% composite image. Color images are 3D matricies that have three values at
% every pixel representing red, green, and blue respectively. To make a
% composite images, use the cat command which concatinates matrices:

% since the different channels have different ranges of intensities we need
% to rescale them using the ag command (autogain).

phaseS = ag( phase );
fluor1S = ag( fluor1 );
redChannel =  0.3*phaseS;
greenChannel = 0.3*phaseS +  0.7*fluor1S;
blueChannel =  0.3*phaseS;
imRGB = cat(3,redChannel, greenChannel, blueChannel);
imshow( imRGB )

%% Your turn: (1) Make a function that displays a composite image
% This is more than you want to type therefore we probably want to define a
% function that performs these manipulations for you.

%% Cell Masks.
% To analyze a cell, we want to define which pixels correspond to the cell
% and which are part of the background. To do this we define a cell mask
% where pixels belonging to the cell have value 1 whereas other pixels have
% value 0. We'll show you how to do this soon. Lets use one that we loaded
% already in the data file.

mask  = data.CellA{time_step}.mask;

%% Your turn: (2) View the mask.
% Display the image and use the image explore tool to persuade yourself 
% that the mask does correspond to the cell in the center of the image.


%% Your turn: (3) Make a new composite image.
% Modify the code below to make regions outside the cell red.

phaseS = ag(phase);
fluor1S = ag(fluor1);
mask1S = ag(mask);
redChannel =  0.3*phaseS + 0.7 * mask1S;
greenChannel = 0.3*phaseS +  0.7*fluor1S;
blueChannel =  0.3*phaseS;
imRGB = cat(3,redChannel, greenChannel, blueChannel);
imshow( imRGB )


%% Compute cell properties.
% We will often need to know how long or how wide a cell is.

% get the cell center 
centroid = data.CellA{time_step}.coord.r_center';

% the coordinates of the centroid are for the full image so we need to use
% the offset in the cell file to plot it on our smaller image
offset = data.CellA{time_step}.r_offset;
centroid_offset = centroid - offset+1;
hold on; % Don't erase the exist image, but hold it there.
plot(centroid_offset(1), centroid_offset(2), 'b.', ...
    'MarkerSize', 20 );

% We can show text on the figure too
text( centroid_offset(1) + 1, ...
      centroid_offset(2) + 1, ...
      'Cell Centroid', 'Color', 'b' );

%% Rotate the image
% Often we'll want to orient the cell. Lets rotate the cell so that it is
% aligned with the xaxis. 'Orientation' is the angle of the cell

clf;
angle = data.CellA{time_step}.coord.orientation;
maskrot    = imrotate( mask,  angle);
phaseSrot  = imrotate( phaseS, angle);
fluor1Srot = imrotate( fluor1S, angle );

maskrotS  = ag( ~maskrot );

imRGB = cat(3, 0.2*maskrotS  + 0.3*phaseSrot, ...
               0.3*phaseSrot + 0.7*fluor1Srot, ...
               0.3*phaseSrot );

imshow( imRGB )

%% Analyze cell width
% open a new figure for the analysis:
figure(2);
% clear figure
clf

% Compute the width of the cell as a function of long axis position
% this function sums the first index of the image: 
cellWidth = sum(double(maskrot),1); 

% Generate a vector for the long axis positions
ss = size( maskrot );
xx = 1:ss(2);
plot( xx, cellWidth, '.-r' );
ylabel( 'Width (Pixels)'             );
xlabel( 'Long Axis Position (Pixels)');

%% Analyze fluorescence localization
% Compute the integrate fluorescence at each long axis position
figure(3);
clf;
% Compute the width of the cell as a function of long axis position
% this function sums the first index of the image. 
% multiply by the mask to zero out all pixels not corresponding to the cell
int = sum(double(fluor1Srot).*double(maskrot),1); 

% Generate a vector for the long axis positions
ss = size( maskrot );
xx = 1:ss(2);
plot( xx, int, '.-r' );
ylabel( 'Integrated Intensity (AU)'  );
xlabel( 'Long Axis Position (Pixels)');

%% Threshold fluor image by mean fluor
fmean = mean(double(fluor1S(:)));

fluor1Srot(fluor1Srot<fmean) = fmean;
fluor1SrotThres = fluor1Srot - fmean;

figure(3);
clf
% Compute the width of the cell as a function of long axis position
% this function sums the first index of the image: 
int = sum(double(fluor1SrotThres).*double(maskrot),1); 

% Generate a vector for the long axis positions
ss = size( maskrot );
xx = 1:ss(2);
plot( xx, int, '.-r' );
ylabel( 'Integrated Intensity (AU)'  );
xlabel( 'Long Axis Position (Pixels)');
                                
%% How much fluor is polar?
% Compute the fraction of fluorescence within 20% of the end of the cell
cellInd = double( logical( cellWidth ));

% cellInd has 1 at postions corresponding to the cell and zeros elsewhere
len     = sum( cellInd );

% calculate 20% of the length
dlen    = floor( len * 0.2 );

% find each end of the cell by finding the first and last non-zero pixel 
% index in cellInd.
ind1 = find( cellWidth>0, 1, 'first' );
ind2 = find( cellWidth>0, 1, 'last'  );

% calculate the indices corresponding to the first and last 20% of the cell
ind1_ = ind1:(ind1 + dlen);
ind2_ = (ind2 - dlen + 1):ind2;

% make right and left ends blue.
hold on;
plot( xx(ind1_), int(ind1_), '.-b' );
plot( xx(ind2_), int(ind2_), '.-b' );

% sum up the intensity at each end
% int(ind1_) is just the elements of int corresponding to the indices 
% ind1_.
I_left_pole   = sum( int(ind1_)     );
I_right_pole   = sum( int(ind2_)     );
Itot = sum( int(ind1:ind2) );

% display the faction (p1) of fluorescence at each side of the cell
p1 = I_left_pole/Itot;
disp(['Fraction at left side: ', num2str( p1 )]);

% display the faction (p2) of fluorescence at each side of the cell
p2 = I_right_pole/Itot;
disp(['Fraction at right side: ', num2str( p2 )]);

%% Your turn: (4) Compute the intensity with 20% of the middle of the cell
% and store this value in I_middle

%% Your turn: (5) Look at the time dependence of polar localization
% Write a function that returns the polar intensity. Then use a for loop 
% to loop through the different frames. Here is a start:

figure(4)
% clear the figure
clf;

% get the number of frames 
numTime = numel( data.CellA );

for ii = 1:numTime
    % return the left, right, and total intensity here 
    [ I_left_pole(ii), I_right_pole(ii), Itot(ii) ] = yourFunctionHere( data.CellA{ii} );
end

% plot the intensity 
plot( tt, I_left_pole,   'r.-' );
hold on;
plot( tt, I_right_pole,   'g.-' );
plot( tt, Itot, 'b.-' );

ylabel( 'Intensity (AU)' );
xlabel( 'Time (frames)'  );
title( 'Intensity'       );

% make a figure legend
legend( 'Left Intensity', 'Right Intensity', 'Total Intensity' );

%% Your turn: (6) Analyze the rest of the cells