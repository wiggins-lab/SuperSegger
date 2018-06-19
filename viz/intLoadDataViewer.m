function [data_r, data_c, data_f] = intLoadDataViewer(dirname, contents, nn, num_im, clist, FLAGS)
% intLoadDataViewer : used to load data in superSeggerViewer
% INPUT :
%       dirname : seg directory name
%       contents: contains all names of files in the directory
%       nn : image number to be loaded
%       num_im : total number of images
%       clist : clist 
%       FLAGS : current flags
%
% OUTPUT : 
%   data_r: reverse frame data file (err/seg)
%   data_c: current frame data file (err/seg)
%   data_f: forward frame data file (err/seg)
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


data_c = loaderInternal([dirname,contents(nn).name], clist);
data_r = [];
data_f = [];
if shouldLoadNeighborFrames(FLAGS)
    'boom'
    if nn > 1
        data_r = loaderInternal([dirname,contents(nn-1).name], clist);
    end
    if nn < num_im
        data_f = loaderInternal([dirname,contents(nn+1).name], clist);
    end
end
end

function value = shouldLoadNeighborFrames(FLAGS)
% shouldLoadNeighborFrames : checks if reverse and forward frame should be
% loaded.
value = (FLAGS.m_flag == 1 || FLAGS.showLinks == 1) || ...
    (isfield(FLAGS,'edit_links') && FLAGS.edit_links == 1);
end

function data = loaderInternal(filename, clist)
% loaderInternal : loads the clist and creates outlines of the cells in the
% clist.
data = load(filename);
ss = size(data.phase);
if isfield( data, 'mask_cell' )
    data.outline = xor(bwmorph( data.mask_cell,'dilate'), data.mask_cell);
end
if ~isempty(clist)
    clist = gate(clist);
    data.cell_outline = false(ss);
    if isfield( data, 'regs' ) && isfield( data.regs, 'ID' )
        ind = find(ismember(data.regs.ID,clist.data(:,1)));
        mask_tmp = ismember( data.regs.regs_label, ind );
        data.cell_outline = xor(bwmorph( mask_tmp, 'dilate' ), mask_tmp);       
   end
end
end