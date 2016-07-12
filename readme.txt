==== SUPERSEGGER README=====

SuperSegger is a completely automated MATLAB-based trainable image cell segmentation, fluorescence quantification and analysis suite written by the Wiggins lab. It is particularly well suited for high-throughput time lapse fluorescence microscopy of in vivo bacterial cells. 

SuperSegger is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

For more information about the software please visit the website http://mtshasta.phys.washington.edu/

A protocol with directions on how to use the software suite can be found on the website. 

Some basic information here to get you started with : 

Setting the Path
=================

In order for Matlab to be able to find the different pieces of the code the SuperSegger folder needs to be in your path. In the Home tab, in the Environment section, click Set Path. The Set Path dialog box appears. Click add folder with subfolders and add the SuperSegger folder. 


Software Requirements
=====================

In order to use SuperSegger you need to have the MATLAB software with the following toolboxes:
Image Processing Toolbox
Neural Network Toolbox
Statistics and Machine Learning Toolbox
Global Optimization Toolbox
Parallel Computing Toolbox (not necessary)


Main functions you may need
===========================

GUIs :
superSeggerGui : to segment your images
superSeggerViewerGui : to see the final result after segmentation and use the post processing tools.
trainingGui : to train your own constants.

Non - GUI :
ProcessExp : set your parameters and run BatchSuperSeggerOpti. (You can use this instead of superSeggerGui)

You can download a sample dataset and a bootcamp folder from our website to try the software.


Segmentation Parameters
=======================
Some information about the parameters currently provided with the software :
100XEc : Trained on E.coli, 60nm/pix .
100XPa : Trained on P.aeruginosa, 60nm/pix.
60XEcAB1157 : Trained on E.coli AB1157 on M9 pads, 100nm/pix.
60XEcM9 : Trained on E.coli on M9 pads, 100nm/pix.
60XEc : Trained on E.coli on LB and M9 pads, 100nm/pix.
60XEcLB : Trained on E.coli on LB pads, 100nm/pix.
60XBay : Trained on A.baylyi on LB pads, 100nm/pix.
60XPa : Trained on P.aeruginosa, 100nm/pix.
60XCaulob : Trained on snapshots of C.crescentus, 130 nm/pixel.



General Process and output 
==========================

The fluorescence and phase images are processed and aligned. During segmentation the image cells are partitioned from the background. Then each cell is linked to one cell or a pair of cells in the next frame and the cells receive ID numbers. Next, the properties and fluorescence characteristics of each cell are calculated. Finally, the program outputs the Clist, a table with pertaining information during the cell lifetime, and a file for each cell with all the characteristics during its lifetime. 


Images - Naming Convention
===========================
In order to segment your images they need to follow our naming convention. 
The naming convention of the image files must be of the following format
base_name_t[frame-number]xy[xy-number]c*.tif. c1 must be the bright field 
and c2,c3 etc are different fluorescent channels.

Example of two time points, two xy positions and one fluorescent channel
 filename_t001xy1c1.tif
 filename_t001xy1c2.tif
 filename_t001xy2c1.tif
 filename_t001xy2c2.tif
 filename_t002xy1c1.tif
 filename_t002xy1c2.tif
 filename_t002xy2c1.tif
 filename_t002xy2c2.tif

superSeggerGui provides a function to rename your images


Collecting Images
==================

SuperSegger is unable to correctly segment images where the cell outlines are not clear to the user by eye. Care should still be taken in collecting the best possible focused phase images. We recommend that users crop out-of-focus regions of the image before the segmentation process since these parts of the image are unlikely to yield usable data. superSeggerGui provides a function to crop your images.



