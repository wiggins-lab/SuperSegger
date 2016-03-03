function [ data_new, ind ] = fix2to1( data_c, ii_c, data_r, list_r )
% fix2to1 : fixing error when a region in data_c corresponts to two in data_r.
% It turns on some segments to divide the region ii_c in data_c
% provided the region is touching regions list_r in data_r.
%
% INPUT :
%       data_c: current cell / region to be modified
%       ii_c : region number
%       data_r : corresponding cell/region in the reverse frame
%       list_r : list of regions touched by ii_c
%
% OUTPUT :
%       data_new : new modified data_c file
%       ind : indices of regions
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


list_cr = data_c.regs.map.r{ii_c};
bb_c    = data_c.regs.props(ii_c).BoundingBox;

[xx,yy] = getBB(bb_c);

regs_r = data_r.regs.regs_label(yy,xx);
regs_c = (data_c.regs.regs_label(yy,xx)==ii_c);
segs_c = data_c.segs.segs_label(yy,xx);

segs_c_ind = unique( segs_c(regs_c) );
segs_c_ind = segs_c_ind(logical(segs_c_ind));

overlap = 0*regs_r;

se = strel('line',11,90);

str = strel('square', 3 );

for jj_r = list_r
    mask = (regs_r==jj_r);
    tmp = imdilate(mask,str);
    tmp(mask) = 0;
    overlap = overlap + double(tmp);
end

mask =(overlap  > 1);
dist = bwdist( mask );


dist_segs_c = 0*segs_c_ind+100000;

nsegs = numel(segs_c_ind);
for jj = 1:nsegs
    dist_segs_c(jj) = min( dist( segs_c ==segs_c_ind(jj)));
end


[dist_segs_c_ord, ord] = sort( dist_segs_c, 'ascend');
segs_c_ind_ord = segs_c_ind(ord);

DIST_CUT = 5;

segs_c_ind_ord  = segs_c_ind_ord(dist_segs_c_ord<DIST_CUT);
dist_segs_c_ord = dist_segs_c_ord(dist_segs_c_ord<DIST_CUT);

nsegs = numel( dist_segs_c_ord );
flag = false;

for jj = 1:nsegs
    jj_c = segs_c_ind_ord(jj);
    regs_c(segs_c==jj_c) = false;
    new_labels = bwlabel( regs_c );
    if max(new_labels(:)) > 1
        flag = true;
        break;
    end
end

data_new = [];
ind = [];
if flag
    data_new.regs.regs_label = zeros( size(data_c.regs.regs_label) );
    data_new.regs.regs_label(yy,xx) = new_labels;
    ind = unique( new_labels );
    ind = ind(logical(ind));
    ind = reshape( ind, [1,numel(ind)] );
    for jj = ind
        data_new.regs.props(jj) = struct('BoundingBox',bb_c);
    end
end


end

