function targetd = trackOptiResize(dirname, scale)
% trackOptiResize : Resizes all .tif images in the directory dirname by a 
% factor of 'scale'.
% Resized images are saved in resize folder under the dirname directory.
%
% INPUT:
%       dirname: directory with .tif images named in NIS name-format.
%       scale: returns an image that is scale times the size of the
% original image
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou.
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

if ~isempty(dirname)
    
    % Read images.
    file_filter = '*.tif';
    dirname = fixDir(dirname);
    contents=dir([dirname,file_filter]);
    num_im = numel( contents );
    if num_im < 0
        errordlg('No images found');
    end
    
    % Make target directory.
    if ~exist( 'targetd','var' ) || isempty( targetd )
        targetd = [dirname,'resize',filesep];
    else
        targetd = fixDir(targetd);
    end
    mkdir(targetd);
    
    for i = 1:num_im
        % Resize and save each image.
        image_name  = contents(i).name;
        image_folder = contents(i).folder;
        disp(image_name);
        im = intImRead([image_folder,'/',image_name]);
        out_name = [targetd, image_name];
        imwrite(imresize(im,scale), out_name, 'TIFF');        
    end
end
end