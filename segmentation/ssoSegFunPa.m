function [ data, err_flag ] = ssoSegFunPa( phase, CONST, header, dataname, crop_box )
% ssoSegFunPa : starts segmentation of phase image and sets error flags
% 
% INPUT :
%       phase_ : phase image
%       CONST : segmentation constants
%       header : string displayed with infromation
%       dataname : 
%       crop_box : information about alignement of the image
% 
%  OUTPUT :
%       data : contains information about the segments and mask, for more
%       information look at superSeggerOpti.
%       err_flag : set to true if there are more segments than max
%       
% Written by Paul Wiggins and Keith Cheveralls
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

disp('superSeggerOptiP');

data = superSeggerOptiP( phase ,[], ~CONST.seg.OPTI_FLAG ,CONST,1,header, crop_box);
drawnow;

if numel(data.segs.score) > CONST.superSeggerOpti.MAX_SEG_NUM;
    err_flag = true;
    save([dataname,'_too_many_segs'],'-STRUCT','data');
    disp( [header,'BSSO ',dataname,'_too_many_segs'] );
    return
else
    err_flag = false;    
end

% optimize the regions here
if CONST.seg.OPTI_FLAG
    data = regionOpti( data, 1, CONST,header);
    drawnow;
end
end

