function trackOptiPD(dirname, CONST)
% trackOptiPD : Sets up directories and moves files for SuperSeggerOpti.
% It sets up directory structure for cell segmentation
% analysis and moves aligned images to their respective folders.
%
% INPUT : 
%       dirname : directory that contains images
%       CONST : segmentation constants
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Stylianidou
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
file_filter = '*.tif*';

if(nargin<1 || isempty(dirname))    
    dirname = uigetdir();
end

dirname = fixDir(dirname);

% Make and move subdirs
contents=dir([dirname file_filter]);

if ~isempty(contents);
    
    num_im = numel(contents);
       
    nc  = zeros(1, num_im); % channel
    nxy = zeros(1, num_im); % xy
        
    for i = 1:num_im;
        % creates an array with the the numbers after the strings t,c,xy,z
        % for the filename of each image
        nameInfo = ReadFileName(contents(i).name);    
        nc(i)  = nameInfo.npos(2,1);
        nxy(i) = nameInfo.npos(3,1);
    end
    
    nc  = sort(unique(nc));
    nxy = sort(unique(nxy));

    num_xy = numel(nxy);
    num_c  = numel(nc);
    
    dirname_list = cell(1,num_xy);
    
    if nxy(1)==-1
        nxy = 1;
    end
    
    if nxy == 0
        xyPadSize = 1;
    else
        xyPadSize = floor(log(max(nxy))/log(10))+1;
    end
    
    padString = ['%0',num2str(xyPadSize),'d'];
    
    for i = 1:num_xy 
        % creates the needed xy directories with phase, fluor, seg and cell
        % sub-directories
        dirname_list{i} = [dirname,'xy',num2str(nxy(i), padString),filesep];
        mkdir(dirname_list{i});
        mkdir([dirname_list{i},'phase',filesep]);
        mkdir([dirname_list{i},'seg',filesep]);
        mkdir([dirname_list{i},'cell',filesep]);
        for j = 2:num_c
            mkdir( [dirname_list{i},'fluor',num2str(j-1),filesep] );
        end
    end
    
    if CONST.parallel.show_status
        h = waitbar(0, 'Moving Files');
        cleanup = onCleanup( @()( delete( h ) ) );
    else
        h = [];
    end
    
    for i = 1:num_im; % goes through all the images
        if CONST.parallel.show_status
            waitbar(i/num_im,h);
        end
        
        nameInfo = ReadFileName( contents(i).name );
        
        ic  = nameInfo.npos(2,1); % channel
        ixy = nameInfo.npos(3,1); % xy position
               
        if ixy == -1
            ii = 1;
        else
            ii = find(ixy==nxy);
        end
        
        if ic == -1
            ic  = 1;
        end
        
        
        if ic == 1
            tmp_target =  [dirname_list{ii},'phase', filesep];
        else
            tmp_target =  [dirname_list{ii},'fluor',num2str(ic-1),filesep];
        end
        
        tmp_source = [dirname,contents(i).name];
        movefile( tmp_source, tmp_target ,'f');
                
    end
    if CONST.parallel.show_status
        close(h);
    end
    
end
end
