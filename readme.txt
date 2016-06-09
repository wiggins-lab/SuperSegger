==== SUPERSEGGER README=====

SuperSegger is a completely automated MATLAB-based trainable image cell segmentation, fluorescence quantification and analysis suite written by the Wiggins lab. It is particularly well suited for high-throughput time lapse fluorescence microscopy of in vivo bacterial cells. 

SuperSegger is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

For more information about the software please visit the website http://mtshasta.phys.washington.edu/

A protocol with directions on how to use the software suite can be found on the website. 

Some basic information here to get you started with : 

Setting the Path
=================

In order for Matlab to be able to find the different pieces of the code the SuperSeggerRelease folder needs to be in your path. In the Home tab, in the Environment section, click Set Path. The Set Path dialog box appears. Click add folder with subfolders and add the SuperSeggerRelease folder. We suggest you keep the SuperSeggerRelease / z-removed folder out of your path if it exists in the folders.



Main functions you may need
===========================

GUIs :
superSeggerGui : to run segmentation on your images
superSeggerViewerGui : to see the final result after segmentation and use the post processing tools.
training : to train your own constants.

Non - GUI :
ProcessExp : set your parameters and run BatchSuperSeggerOpti. (You can use this instead of superSeggerGui)


You can download a sample dataset and a bootcamp folder from our website to try the software.


Software Requirements
=================

In order to use SuperSegger you need to have the MATLAB software with the following toolboxes:
Image Processing Toolbox
Neural Network Toolbox
Statistics and Machine Learning Toolbox
Global Optimization Toolbox
Parallel Computing Toolbox (not necessary)



