function [data, err_flag] = ssoSegFunPerReg( phase, CONST, header, dataname, crop_box )
% ssoSegFun : starts segmentation of phase image and sets error flags
% It creates the first set of good, bad and permanent segments and if
% CONST.seg.OPTI_FLAG is set to true it optimizes the region sizes.
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

if ~exist('header','var')
    header = '';
end

if ~exist('dataname','var')
    dataname = '';
end

if ~exist('crop_box','var')
    crop_box = '';
end



% create the masks and segments
data = superSeggerOpti( phase ,[], 1 ,CONST, 1, header, crop_box);

if numel(data.segs.score) > CONST.superSeggerOpti.MAX_SEG_NUM;
    err_flag = true;
    save([dataname,'_too_many_segs'],'-STRUCT','data');
    disp( [header,'BSSO ',dataname,'_too_many_segs'] );
    return
else
    err_flag = false;    
end

% optimize the regions with bad scores
if CONST.seg.OPTI_FLAG
    data = perRegionOpti( data, 1, CONST,header); 
    drawnow;
end

end

