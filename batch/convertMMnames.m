function convertMMnames(dirname, fluorFilt)
% Convert File Names from Micromanager Format to Elements format
% The file naming convention for Micromanager is "img" prefix followed
% by frame number, channel name (img_00000000t_channel.tif).
% From dirname/*BF*  to dirname/*c1* and dirname/*fluorFilt*  to dirname/*c2*
% Note: Phase image names must include "BF"
%
% INPUT : dirname : directory contains micromanager images
%         fluorFilt : string within the fluorescence images names,
%                   gfp used as default
%
% Copyright (C) 2016 Wiggins Lab
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.


if nargin < 2 || isempty(fluorFilt)
    fluorFilt = 'gfp' ;
end

% Check file status or if segmentation has already been run

imcheck = dir([dirname,filesep,'*tif*']);

if isempty(imcheck)
    if exist([dirname,filesep,'raw_im'])
        disp('Files already aligned');
    elseif ~exist([dirname,filesep,'raw_im']);
        error('No image files found, please check directory');
    end
else
    
    phase = dir([dirname,filesep,'*c1*']) ;
    fluor = dir([dirname,filesep,'*c2*']) ;
    
    if isempty(phase) || isempty(fluor) || numel(phase)~=numel(fluor)
        disp('File names not in Elements format, checking compatibility')
        disp(' ');
        phase2 = dir([dirname,filesep,'*BF*']) ;
        fluor2 = dir([dirname,filesep,'*',fluorFilt,'*']) ;        
        if isempty(phase2) || isempty(fluor2) || numel(phase2)~=numel(fluor2)            
            error('File filters not correct, please check file names')            
        else
            
            destname = 'seg_convert';
            dirFiles = [dirname,filesep] ;
            dirDest  = [dirname,'_original',filesep] ;
            
            if ~exist(dirDest)
                
                mkdir([dirname,'_original']) ;
                
                intCopyFiles(dirFiles,dirDest,destname,fluorFilt) ;
                
                disp('Files converted from MicroManger Format')
                disp(' ');
                disp('Procedeto segmentation')
                disp(' ');
            else
                
                disp('Directory already exists; checking file status')
                
                phase = dir([dirDest,'BF']) ;
                fluor = dir([dirDest,'*',fluorFilt,'*']) ;
                
                if isempty(phase) || isempty(fluor) || numel(phase)~=numel(fluor)
                    
                    error('File filters not correct, please check file names')
                    
                else
                    
                    intCopyFiles(dirFiles,dirDest,destname,fluorFilt) ;
                    disp('Files converted from MicroManger Format')
                    disp(' ');
                    disp('Procede to segmentation')
                    disp(' ');
                end
            end
        end
    else
        
        disp('File names in NIS-Elements format')
        disp(' ');
        disp('Procede to segmentation')
        disp(' ');
    end
    
end
end


function numFrames = intCopyFiles(dirFiles, dirDest, destname, fluorFilt)

BFfilt    = '*BF*' ;

contentsBF = dir([dirFiles,filesep,BFfilt]) ;
contentsFluor = dir([dirFiles,filesep,'*',fluorFilt,'*']) ;

numFrames = numel(contentsFluor) ;

imBF = imread([dirFiles,contentsBF(1).name]) ;

for ii = 1:numFrames
    
    copyfile([dirFiles,contentsBF(ii).name],[dirFiles, destname,'_t',sprintf('%05d',ii),'c1.tif']);
    copyfile([dirFiles,contentsFluor(ii).name],[dirFiles, destname,'_t',sprintf('%05d',ii),'c2.tif']);
    
    movefile([dirFiles,contentsBF(ii).name],dirDest);
    movefile([dirFiles,contentsFluor(ii).name],dirDest);
    
end

end


