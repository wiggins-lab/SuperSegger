function [data, err_flag] = ssoSegFun( phase, CONST, header, dataname, crop_box)
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
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Styliandou & Paul Wiggins.
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

% optimize the regions 
if CONST.seg.OPTI_FLAG
    data = regionOpti( data, 1, CONST,header);
    drawnow;
else
    data = intMakeRegs( data, CONST );
end

end

