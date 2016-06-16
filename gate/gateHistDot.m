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
x2 = clist.data(:,ind(2));
x1 = clist.data(:,ind(1));

x1_min = min(x1);
x1_max = max(x1);
x1_mean  = (x1_max+x1_min)/2;
x1_delta = 1.33*(x1_max-x1_min);

x1_dd = ((0:xx(1))/xx(1)-0.5)*x1_delta + x1_mean;

x2_min = min(x2);
x2_max = max(x2);
x2_mean  = (x2_max+x2_min)/2;
x2_delta = 1.33*(x2_max-x2_min);

x2_dd = ((0:xx(2))/xx(2)-0.5)*x2_delta + x2_mean;


xx = {x2_dd,x1_dd};


[y,xx] =hist3([clist.data(:,ind(2)),clist.data(:,ind(1))], xx );


% xvasl, yvals : positions of bin centers
xvals = x2;
yvals = x1;
y2 = interp2( xx{1}, xx{2}, y', xvals, yvals, 'linear');
y = y2;


[y,ord] = sort(y, 'ascend');
xvals = xvals(ord);
yvals = yvals(ord);

%y = log(y);

scatter( yvals, xvals, 10, y, 'filled' );

colormap(jet)

if size(clist.def,2) >= ind
    yname = clist.def{ind(2)};
    xname = clist.def{ind(1)};
    ylabel( yname );
    xlabel( xname );
end

set(gca,'Box','on');
set(gca,'YScale','log');



end