function trackOptiCropMulti(dirname,xydir)
% trackOptiCropMulti user chooses two corners to crops multiple images
% Images must be in NIS name-format. 
% New cut images are saved in dirname/crop folder.
%
% INPUT :
%       dirname : directory with .tif images named in NIS name-format.
%       xydir : number of xydirectory you would like to crop, it cuts all
%       if none.
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins.
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
    
    file_filter = '*.tif';
    dirname = fixDir(dirname);
    
    contents=dir([dirname,file_filter]);
    num_im = numel( contents );
    
    nt  = [];
    nc  = [];
    nxy = [];
    nz  = [];
    
    for i = 1:num_im
        nameInfo = ReadFileName(contents(i).name);
        nt  = [nt, nameInfo.npos(1,1)];
        nc  = [nc, nameInfo.npos(2,1)];
        nxy = [nxy,nameInfo.npos(3,1)];
        nz  = [nz, nameInfo.npos(4,1)];
    end
    
    nt  = sort(unique(nt));
    nc  = sort(unique(nc));
    nz  = sort(unique(nz));    
    nxy = sort(unique(nxy));
    if exist('xydir','var')
       nxy = xydir;
    end
    
    targetd = [dirname,'crop',filesep];
    mkdir(targetd);
    
    for nnxy = nxy;
        
        % displays the first and last image on top of each other
        nameInfo.npos(:,1) = [nt(1); nc(1); nnxy; nz(1)];
        im1   = imread( [dirname, MakeFileName(nameInfo) ]);
        
        nameInfo.npos(:,1) = [nt(end); nc(1); nnxy; nz(1)];
        imEnd = imread( [dirname, MakeFileName(nameInfo) ]);
        figure(1);
        clf;
        im = cat(3, ag(im1), ag(imEnd), 0*ag(imEnd));
        imshow(im)
        
        % user picks two corners to crop the image
        disp('Pick the two corners of the crop region.');
        ss = size(im);
        corner1 = ginput (1);
        
        hold on; plot (corner1(1) * ones (1,ss(1)),1:ss(1),'r');
        hold on; plot (1:ss(2),corner1(2) * ones (1,ss(2)),'r');
        
        corner2 = ginput (1);
        x = floor(sort([corner1(1),corner2(1)]));
        y = floor(sort([corner1(2),corner2(2)]));
        
        if x(1)<1
            x(1) = 1;
        elseif x(2)>ss(2)
            x(2) = ss(2);
        end
        
        if y(1)<1
            y(1) = 1;
        elseif y(2)>ss(1)
            y(2) = ss(1);
        end
        
        yy = y(1):y(2);
        xx = x(1):x(2);
        figure(1);
        clf;
        imshow(im(yy,xx,:));
        
        % reads all the images, crops them and saves them
        for it = nt;
            for ic = nc;
                for iz = nz;
                    nameInfo.npos(:,1) = [it; ic; nnxy; iz];
                    in_name = [dirname, MakeFileName(nameInfo)];
                    im = imread( in_name );
                    out_name = [targetd, MakeFileName(nameInfo)];
                    imwrite( im(yy,xx), out_name, 'TIFF' );
                end
                
            end
        end
        
    end
end
end
