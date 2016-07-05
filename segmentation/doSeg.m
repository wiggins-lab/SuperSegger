function  [err_flag] = doSeg(i, nameInfo, nc, nz, nt, num_z, num_c, ...
    dirname_xy,  skip, CONST, header, crop_box)
% doSeg : Segments and saves data in the seg.mat files in the seg/ directory.
% If the seg files are already found it does not repeat the segmentation.
% It calls the segmentation function found in CONST.seg.segFun to achieve
% this. The images are not ideally segmented at this stage because they do
% not use temporal information, i.e. what came before or after, to optimize 
% the segment choices; this comes at the linking stage.
% After it segments the data it copies the fluor fields into the data 
% structure and saves this structure in the seg directory.
%
% INPUT :
%         i : frame number
%         nameInfo :
%         nc : array of channel numbers
%         nz : array of z values
%         nt : array of time frames 
%         num_z : number of z's
%         num_c : number of channels
%         dirname_xy : xy directory
%         clean_flag : redo segmentation if set to true
%         skip : how many frames to skip
%         CONST : segmentation constants
%         header : information string
%         crop_box : alignment information
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins & Stella Stylianidou.
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


% Init
data = [];

% make the segment file name and check if it already exists
nameInfo_tmp = nameInfo;
nameInfo_tmp.npos([2,4],:) = 0;
nameInfo_tmp.npos(1,1) = nt(i);
name = MakeFileName( nameInfo_tmp );
nameInfo_tmp = ReadFileName(name);
name = name( 1:max(nameInfo_tmp.npos(:,3))); % has format imagename-tXX

data.basename = name;

if ~exist([dirname_xy,'seg',filesep],'dir')
    mkdir([dirname_xy,'seg',filesep]);
end

dataname=[dirname_xy,'seg',filesep,name,'_seg.mat'];


if ~exist(dataname,'file')
    nameInfo_tmp = nameInfo;
    nameInfo_tmp.npos(1,1) = nt(i);
    nameInfo_tmp.npos(4,1) = 1; % z value
    name = MakeFileName(nameInfo_tmp);
    namePhase = [dirname_xy,'phase',filesep,name];    
    phase = imread( namePhase );
    
    if num_z > 1 % if there are z frames
        phaseCat = zeros( [size(phase), num_z], 'uint16' );
        phaseCat(:,:,1) = phase;
        
        for iz = 2:num_z
            nameInfo_tmp.npos(4,1) = iz;
            name = MakeFileName(nameInfo_tmp);
            phaseCat(:,:,iz) = imread( [dirname_xy,'phase',filesep,name] );
        end        
        phase = mean( phaseCat, 3);      
    end
    
    if ~mod(i-1,skip)
        % do the segmentation here
        [data, ~] = CONST.seg.segFun( phase, CONST, header, dataname, crop_box);
        if ~isempty( crop_box )
            data.crop_box = crop_box;
        end
        
        % Copy fluor data into the seg data structure 
        nameInfo_tmp = nameInfo;
        for k = 2:num_c
            nameInfo_tmp.npos(1,1) = nt(i);
            nameInfo_tmp.npos(2,1) = nc(k);
            nameInfo_tmp.npos(4,1) = 1;
            name = MakeFileName( nameInfo_tmp );
            fluor_tmp = imread( [dirname_xy,'fluor',num2str(nc(k)-1),filesep,name] );         
            data.(['fluor',num2str(nc(k)-1)])=fluor_tmp;            
        end
                
        save(dataname,'-STRUCT','data'); % Save data structure into the seg file.
    end
else
    disp([dataname, ' already exists.']);
end

end