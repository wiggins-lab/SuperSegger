function [y,xx,xarr_s,yarr_s,zvals_s] = gateHistDot(clist, ind, xx)
% gateHistDot : plots dot plot of two quantities in the clist.
% The quantities are plot using a jet color map to identify the most dense 
% bins.
%
% INPUT : 
%   clist : array of cells versus variable produced from superSegger 
%   ind : array containing the two clist indices you wish to use
%   xx : (optional) 2x1 array of preset bins for histogram i.e [20 20]
%
% OUTPUT :
%   y : matrix of 2D histogram values
%   xx : 2x1 Cell array where, xx{1} and xx{2} are the bins used to generate y
%   zvals_s : array of number of elements in each bin in increasing order
%   xarr_s : array of x bin centers; x(i) is the x value corresponding zvals_s(i)
%   yarr_s : array of y bin centers; y(i) is the y value corresponding zvals_s(i)
%
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Julie Cass, Stella Stylianidou, Paul Wiggins.
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

ss = size( clist.data );
NUM_BINS = round((sqrt(ss(1))));
clist = gate(clist);

if ~exist( 'xx', 'var' );
    xx = round(([ NUM_BINS, NUM_BINS]));
end

if numel( ind ) ~= 2
    error ('clist indices must be two')
end

if ind(1) > size(clist.data,2)
    error('index one outside clist range')
end

if ind(2) > size(clist.data,2)
    error('index two outside clist range')
end

if ~sum(~isnan(clist.data(:,ind(2)))) || ~sum(~isnan(clist.data(:,ind(1)))) 
    error('no data for the quantities you chose') 
end

% 3d histogram
% y : number of elements in each bin
% xx : 1x2 cell array with positions of bin centers
[y,xx] =hist3([clist.data(:,ind(2)),clist.data(:,ind(1))], xx );

y((y==0))=NaN;
cutoff = 50*min(y(:));
if max(y(:))>cutoff
    y((y>cutoff))=cutoff;
end

% xvasl, yvals : positions of bin centers
xvals = xx{1};
yvals = xx{2};
dim=length(y);
zvals = nan(1,(dim*dim)); % number of elements in bin
xarr = nan(1,(dim*dim)); % positions of x bin centers
yarr = nan(1,(dim*dim)); % positions of y bin centers


for jj=1:size(y,1)
    for ii=1:size(y,2)
        if ~isnan(y(jj,ii)) && ~y(jj,ii)==0
            index = jj+(dim*(ii-1));
            xarr(index)=xvals(jj);
            yarr(index)=yvals(ii);
            zvals(index)=y(jj,ii);
        end
    end
end

% Sort datapoints by z values so highest hits
% will be plotted last (on top)
[sorted,newind,what]=unique(zvals);
inds=[];

for ii=1:length(sorted)
    tmp = find(zvals==sorted(ii));
    for jj=1:length(tmp)
        inds=[inds,tmp(jj)];
    end
end

xarr_s = xarr(inds);
yarr_s = yarr(inds);
zvals_s = zvals(inds);

yname = clist.def{ind(2)};
xname = clist.def{ind(1)};
zvals_log = log(zvals_s);

clf;
sameSize = false;
if sameSize
     scatter (yarr_s,xarr_s,20,zvals_log,'o','filled');
else
    scatter (yarr_s,xarr_s,10*zvals_s,zvals_log,'o','filled');
end
   
colormap(jet)
ylabel( yname );
xlabel( xname );
set(gca,'Box','on');


end