function showTrainingData (data, FLAGS, viewport)
% makeTrainingData : user can click on segments or regions to change score
% from 0 to 1 or vice versa. It updates scores, cell mask, good and bad
% segs.
%
% INPUT :
%       data : data file with segments to be modified
%       FLAGS : im_flag = 1 for segments, 2 for regions.
% INPUT :
%       data : data file with modified segments
%       touch_list : list with modified segments/regions
%
% Copyright (C) 2016 Wiggins Lab
% Written by Paul Wiggins, Stella Stylianidou.
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


if ~exist('FLAGS','var') ||  ~isfield(FLAGS,'im_flag')
    FLAGS.im_flag  = 1;
    FLAGS.S_flag  = 0;
    FLAGS.t_flag  = 0;
end

showSegRuleGUI( data, FLAGS ,1, viewport);

%disp ('Click on segment/region to modify.');

