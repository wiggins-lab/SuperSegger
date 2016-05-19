function introThreshSeg()
% cell_seg : shows how thresholding can b eused in a phase contrast
% microscopy image to find the masks, centers and pole locations of the
% cells.
% This is a very simplistic version of how superSegger works. 
%
% Copyright (C) 2011,2016 Wiggins Lab 
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


%% Load the entried image and display 
% imread converts the tiff image into a large matrix whose dimensions are
% the same as the pixel dimensions on the camera used for imaging and whose
% matrix elements are pixel intensities.

I = imread('exampleCellFiles/thresh_image.tif');
imshow(I,[]);


%% find a region that contains some cells. 
% I like to use the Data Cursor Tool (located on the figure menu bar next
% to the left of the paint brush.) By clicking on this tool you can click
% on pixels to see the index (value of the image at that pixel as well as
% the location of that pixel). Use the tool to find a range of pixels
% corresponding to a couple cells. My choice is shown below, but feel free
% to choose your own.


%% Crop the image
% Pick out a small region with just a few cells. We choose to examine the
% figure matrix between rows 291-524 and columns 842-1105.

I_crop = I(291:524,842:1105);
imagesc(I_crop);

axis equal

%% Image Segmentation.
% There are many different techniques for teaching the computer to identify
% the pixels corresponding to a cell. Lets consider one of the easiest: 
% thresholding.

% The basic observation is that the cells are darker than the background,
% therefore we can use the intensity of the pixels to indentify cells. Use
% the Data Cursor Tool (located on the figure menu bar next
% to the left of the paint brush) to figure out what range of index values
% correspond to the cells and which to the background. 

% Let me help you out by showning you the LUT (look up table) that maps the
% index to the color.

colorbar;

% Choose a cut off value that separates the background values from the cell
% values and set thresh equal to it. Here is my choice:

thresh = 25000;


%% Make a cell mask.
% To get the pixels that are darker, we ask for the values that are less 
% than the thesh and assign this to a new matrix

mask = I_crop < thresh ;
imshow(mask, []); 

%% Your turn (1): What is a mask?  
% Use the Data Cursor Tool to figure out what values of the mask correspond
% to cells versus background.

%% Your turn (2): What happens if you use the wrong threshold.
% Choose different threshold values to figure out what happens if the
% threshold is too low or too high.

%% Return to a threshold that works.
thresh = 25000;
mask = I_crop < thresh ;
imshow(mask, []); 

%% Label cells.
% To manipulate the cells one at a time, we want to choose a distinct label
% for each cell. Matlab has a function, bwlabel, that labels cells by
% filling positions in the image matrix corresponding to a cell with a
% distinct integer corresponding to each cell. Again... check my claim with
% the Data Cursor Tool.
regs_label = bwlabel( mask );
imshow( regs_label, [] );

%% Region props function
% Lets now find a couple different properties for each cell: Centroid (the
% center of each cell), Area, MajorAxisLength (the length of the cell's
% long axis) and MinorAxisLength (the length of the cell's short axis.
regs_prop = regionprops(regs_label,...
    {'Centroid','Area','MajorAxisLength','MinorAxisLength',...
    'Orientation'});

%% Plot all cell centers on the image
% We go through all the cells and extract the coordinates
% of the centroid to plot them. 

figure(2);
clf
imshow(regs_label, []);
hold on

for ii = 1:numel(regs_prop)
    % this line plots a point at the center of each cell
    plot( regs_prop(ii).Centroid(1),regs_prop(ii).Centroid(2), 'r.', 'MarkerSize', 20 );
    
    % this draws a label
    text(regs_prop(ii).Centroid(1),regs_prop(ii).Centroid(2), num2str(ii), 'Color', 'b', 'FontSize', 14, 'FontWeight' , 'bold' );
end


%% Extract all cell coordinates
% Go through all the cells and save in matrices the centroid, orientation
% angle, half the major axis length for the next piece of the code which is
% plotting the poles.


for ii = 1:numel(regs_prop)    
   X(ii) = regs_prop(ii).Centroid(1) ; 
   Y(ii) = regs_prop(ii).Centroid(2) ;   
   theta(ii) = regs_prop(ii).Orientation ;   
   L(ii) = 0.5*regs_prop(ii).MajorAxisLength ;
end

%% FIND AND PLOT POLE LOCATION
% THE ORIENTATION IS DEFINED AS THE ANGLE AWAY FROM THE POSITIVE X-AXIS.  THE
% GEOMETRY IS A LITTLE UPSIDE DOWN BECAUSE THE WAY MATLAB PLOTTED OUR
% ORIGINAL THRESHOLDED IMAGE, POSITIVE Y IS DOWN, SO WE HAVE TO FLIP THE
% ANGLE TO MAKE OUR POLE LOCATION MATCH OUR IMAGE FOR PLOTTING.  THE
% STRUCTURED VARIABLE 'p' WILL HAVE THE X AND Y POSITION OF ALL 6 POLES.


figure(3);
clf;
imshow( I_crop, [] );
hold on;

for ii = 1:numel(regs_prop)    
    p{ii} = [];
    p{ii}(1,1) = X(ii) + L(ii)*cosd(-theta(ii)) ;
    p{ii}(1,2) = Y(ii) + L(ii)*sind(-theta(ii)) ;
    p{ii}(2,1) = X(ii) - L(ii)*cosd(-theta(ii)) ;
    p{ii}(2,2) = Y(ii) - L(ii)*sind(-theta(ii)) ;
    plot(p{ii}(:,1),p{ii}(:,2),'-go') 
end

%% Your turn (3): Process the entire image, instead of a cropped region.

%% Your turn (4): How do you eliminate the cells that do not segment 
% correctly? Implement this idea to only draw long axes on cell that are
% correctly segmented. (Hint : what is the width of the cell?)

%% Your turn (5): Load the fluor channel and superimpose the long axis 
% on a composite image.
% the path to the fluor image is: exampleCellFiles/fluor_image.tif



%% Conclusions : 
% Use the magnifying tool on the figure to see how well we determined the
% poles. You will noticed that we did pretty well for cells who are not
% touching other cells. Things fall apart for clumps of cells. The
% superSegger software suite has more sophisticated ways to handle that
% problem.

% here is the output from superSegger
% the red lines are the outlines of the cells
CONST = loadConstantsNN('60XPA');
data = ssoSegFunPerReg(I,CONST);


end