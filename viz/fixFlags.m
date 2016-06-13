function FLAGS = fixFlags(FLAGS)
% fixFlags : fixes and initializes flags for superSeggerViewer.
%   INPUT :
%       FLAGS : previous flags
%   OUTPUT : 
%       FLAGS : fixed flags
% 
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins, Stella Stylianidou, Connor Brennan.
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


if ~isfield(FLAGS,'legend')
    FLAGS.legend = 1;
end
if ~isfield(FLAGS,'lyse_flag')
    FLAGS.lyse_flag  = 0;
end
if ~isfield(FLAGS,'cell_flag')
    FLAGS.cell_flag  = 1;
end
if ~isfield(FLAGS,'m_flag')
    FLAGS.m_flag  = 0;
end
if ~isfield(FLAGS,'ID_flag')
    FLAGS.ID_flag  = 0;
end
if ~isfield(FLAGS,'T_flag')
    FLAGS.T_flag  = 0;
end
if ~isfield(FLAGS,'P_flag')
    FLAGS.P_flag  = 0;
end
if ~isfield(FLAGS,'Outline_flag')
    FLAGS.Outline_flag  = 1;
end
if ~isfield(FLAGS,'e_flag')
    FLAGS.e_flag  = 0;
end
if ~isfield(FLAGS,'f_flag')
    FLAGS.f_flag  = 0;
end
if ~isfield(FLAGS,'p_flag')
    FLAGS.p_flag  = 0;
end
if ~isfield(FLAGS,'s_flag')
    FLAGS.s_flag  = 1;
end
if ~isfield(FLAGS,'c_flag')
    FLAGS.c_flag  = 1;
end
if ~isfield(FLAGS,'P_val')
    FLAGS.P_val = 0.2;
end
if ~isfield(FLAGS,'filt')
    FLAGS.filt = 1;
end


if ~isfield(FLAGS,'lyse_flag')
    FLAGS.lyse_flag = 0;
end

if ~isfield(FLAGS,'regionScores')
    FLAGS.regionScores = 0;
end

if ~isfield(FLAGS,'useSegs')
    FLAGS.useSegs = 0;
end
if ~isfield(FLAGS,'showLinks')
    FLAGS.showLinks = 0;
end
if ~isfield(FLAGS,'showMothers')
    FLAGS.showMothers = 0;
end
if ~isfield(FLAGS,'showDaughters')
    FLAGS.showDaughters = 0;
end