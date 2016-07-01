function data = makeLineage( clist, ID_, min_width )
% makeLineage : creates a lineage tree for the cells with ID_.
%
% INPUT :
%   clist : list of cells and characteristics
%   ID_ : vector of cell ID to include. If empty all the cells are used
%   min_width : min number of cells in a tree
%
% Copyright (C) 2016 Wiggins Lab
% Written by Paul Wiggins.
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

global daughter1_index;
global daughter2_index;
global cell_birth_index;
global cell_div_index;
global stat_0_index;
global cell_error_index;
global cell_age_index;
global pole_age_index;

figure(1)
clf;
figure(2);
clf;
figure(3);
clf;
figure(4);
clf;
figure(5);
clf;
figure(6);
clf;

clist_ = gate( clist );
gated  = clist_.data(:,1); 



if isempty(clist) 
    disp ('No clist found');
    return;
end

if ~exist( 'ID_', 'var' );
    ID_ = [];
else
    ID_ = unique(ID_);
end

if ~exist( 'min_width' ) || isempty( min_width )
    min_width = 0;
end


clf;
num = size( clist.data, 1 );


starter = [];
hh = [];
hh2 = [];

data.n0 = [];
data.n  = {};
data.t0 = [];
data.t  = {};

data.n1_max = [];
data.n2_max = [];


legend_text = {};
count = 0;

mother_index = grabClistIndex(clist, 'mother id');
daughter1_index = grabClistIndex(clist, 'daughter1 id');
daughter2_index = grabClistIndex(clist, 'daughter2 id');
cell_div_index = grabClistIndex(clist, 'Cell Division Time');
stat_0_index = grabClistIndex(clist,'stat0');
cell_birth_index = grabClistIndex(clist,'Cell Birth Time');
cell_error_index = grabClistIndex(clist,'Error Frame');
cell_age_index = grabClistIndex(clist,'Cell Age' );
pole_age_index = grabClistIndex(clist,'Old Pole Age' );


if isempty(cell_error_index)
    disp ('no error frame found in clist')
end

if isempty( ID_ )
    for ii = 1: num
        
        
        if clist.data(ii,mother_index) == 0
            % Make new lineage
            ID = clist.data(ii,1);
            
            [width,list,time,death,stat0,starter,error,age,gen,pole] ...
                = intGetWidth(ID, clist, starter,1);
            
            if (width >= min_width) || time(1) == 1
                [hh, hh2, data] = intDoDraw( clist, list, time, death, ...
                    stat0, starter, hh, hh2, error, gated, data );
                count = count + 1;
                
                data.width = width;
                data.ID    = list;
                data.birth = time;
                data.death = death;
                data.stat0 = stat0;
                data.error = error;
                data.age   = age;
                data.gen   = gen;
                data.pole  = pole;
                
                legend_text{count} = ['Cell ',num2str( ID )];
            end
            
        end
        
    end
else
    for ii = 1:numel(ID_)
        
        ID = ID_(ii);
        [width,list,time,death,stat0,starter,error,age,gen,pole] = ...
            intGetWidth(ID, clist, starter, 1);
        
        [hh,hh2,data] = intDoDraw( clist, list, time, death, stat0, starter, ...
            hh, hh2, error, gated, data );
        
        data.width = width;
        data.ID    = list;
        data.birth = time;
        data.death = death;
        data.stat0 = stat0;
        data.error = error;
        data.age   = age;
        data.gen   = gen;
        data.pole  = pole;
        
        legend_text{ii} = ['Cell ',num2str( ID )];
    end
end


figure(1);
set( gca, 'YDir', 'Reverse'  );

ylabel( 'Time (Frames)' );
xlabel( 'Cells' );
title( 'Cell Lineage' );

width1 = numel(starter);
xlim( [-.1,1.1]*width1 );

height1 = max(clist.data(:,5));
ylim( [-.1,1.1]*height1 );


figure(2);
ylabel( 'Number of cells' );
xlabel( 'time (frames)' );
legend( hh, legend_text, 'Location' , 'NorthWest' );
set( gca, 'YScale', 'log'  );
title( 'Cummulative  Number of Cells' );

try
ylim_ = data.n1_max;
ylim( [0.5,2*ylim_]);
xlim( [-.1,1.1]*height1 );
end

figure(3);
ylabel( 'Log_2 Number of cells' );
xlabel( 'Time (frames)' );
legend( hh, legend_text, 'Location' , 'NorthWest' );
%set( gca, 'YScale', 'log'  );
title( 'Number of Cells' );

legend( hh2, legend_text, 'Location' , 'NorthWest' );


try
ylim_ = data.n2_max;
ylim( ceil(log([0.5,2*ylim_(end)])/log(2)) );
xlim( [-.1,1.1]*height1 );
end

set( gca, 'YGrid', 'on')


figure(4);
ylabel( 'Length' );
xlabel( 'Time (frames)' );
legend( hh, legend_text, 'Location' , 'NorthWest' );
set( gca, 'YScale', 'log'  );


figure(5);
ylabel( 'Length' );
xlabel( 'Time (frames)' );
legend( hh, legend_text, 'Location' , 'NorthWest' );
set( gca, 'YScale', 'log'  );

figure(6);
ylabel( 'Length' );
xlabel( 'Time (frames)' );
legend( hh, legend_text, 'Location' , 'NorthWest' );
set( gca, 'YScale', 'log'  );

end

function [width,list,time,death,stat0,starter,error,age,gen,pole] = ...
    intGetWidth(ID, clist, starter, gen__)
global cell_birth_index;
global cell_div_index;
global cell_age_index;
global stat_0_index;
global cell_error_index;
global pole_age_index;

end_time = max( clist.data(:,cell_div_index) );


ind = find( clist.data(:,1)==ID );

if isempty(ind) || (ID == 0) || isnan(ID)
    width = 0;
    list  = [];
    time  = [];
    death = [];
    stat0 = [];
    error = [];
    age   = [];
    gen   = [];
    pole  = [];
else
    [ID1,ID2] = intGetDaughter( ID, clist );
    
    error_ = clist.data(ind,cell_error_index);
    death_ = clist.data(ind,cell_div_index);
    age_   = clist.data(ind,cell_age_index);
    gen_   = gen__;
    
    if isempty(error_)
        error_ = nan;
    end

    if isnan(ID1) || isnan(ID2) || (ID1==0) || (ID2==0) || ~isnan(error_)
        starter = [starter,ID];
        
        if death_ ~= end_time && isnan(error_);
            error_ = death_;
        end
            
    end
    
    [w1,l1,t1,d1,s1,starter,e1,a1,g1,p1] = intGetWidth( ID1, clist, starter,gen__ + 1 );
    [w2,l2,t2,d2,s2,starter,e2,a2,g2,p2] = intGetWidth( ID2, clist, starter,gen__ + 1  );
    
    stat0_ = clist.data(ind,stat_0_index);
    time_  = clist.data(ind,cell_birth_index);
    pole_  = clist.data(ind,pole_age_index);
    %death_ = death_ + time_;
    
    width =  1 + w1 + w2;
    list  = [ID,l1,l2];
    time  = [time_,t1,t2];
    death = [death_,d1,d2];
    stat0 = [stat0_,s1,s2];
    error = [error_,e1,e2];
    age   = [age_,a1,a2];
    gen   = [gen_,g1,g2];
    pole  = [pole_,p1,p2];
end
end


function [hh,hh2,data] = intDoDraw( clist, list, time, death, stat0, starter,...
    hh, hh2, error, gated, data  )

%% Show the lineages
figure(1);

num = numel( list );
for ii = 1:num
    
    if stat0(ii) == 2
        cc = 'b';
    elseif stat0(ii) == 1
        cc = 'g';
    else
        cc = 'g';
    end
    
    ID = list(ii);
    
    pos = intGetPos( ID, clist, starter );
    
    if ismember( ID, gated )
        style = '-';
    else
        style = ':';    
    end
    
    plot( pos+[0,0], [time(ii)-1,death(ii)], style, 'Color', cc, 'LineWidth', 1);
    hold on;
    
    if ~isnan(error(ii))
            plot( pos, error(ii), '.', 'Color', 'r', 'MarkerSize', 20 );
    end
    
    
    [ID1,ID2] = intGetDaughter( ID, clist );
    
    if isnan(ID1) || (ID1==0)
        pos1 = pos;
    else
        pos1 = intGetPos( ID1, clist, starter );
    end
    
    if isnan(ID1) || (ID1==0)
        pos2 = pos;
    else
        pos2 = intGetPos( ID2, clist, starter );
    end
    
    plot( [min(pos1),max(pos2)], [0,0] + death(ii), style, 'Color', 'b', ...
        'LineWidth', .5 );
    
    
    h = text( pos(1), time(ii)-1, [' ',num2str( ID )], ...
        'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left' );
    
    set( h, 'rotation', 90 );
    
end

%% Show the cell number;
figure(2);

tt = sort( time );

nn = 1:numel(tt);

h_ = stairs( tt, nn );

data.n1_max = max( [data.n1_max, max(nn) ] );


hh = [hh, h_];

hold on;

cc = get(h_,'Color' );

first_death_time = min(error);

ind = sum(first_death_time>tt);
if ~ind
    ind = 1;
end

plot( first_death_time, nn(ind), '.', ...
    'MarkerSize', 20, 'Color', cc );

data.t = { data.t{:}, tt };
data.n = { data.n{:}, nn };

data.t0 = [ data.t0, first_death_time];
data.n0 = [ data.n0, nn(ind) ];



figure(3);
tt   = sort( time );
dtt  = sort( death+1 );
ntt  = ones(size(tt));
ndtt = -ones(size(dtt));

ntt = [ntt,ndtt];
tt  = [tt,dtt]; 
[ttt,ord] = sort( tt );
ntt = ntt(ord);
nn = cumsum( ntt );


[ttt,ord] = unique( ttt );
nn = nn(ord);

h_ = stairs( ttt, log(nn)/log(2), '-', 'Color', cc );
hold on;

data.n2_max = max( [data.n2_max, max(nn) ] );

ind = sum(first_death_time>ttt);
if ~ind
    ind = 1;
end

plot( first_death_time, log(nn(ind))/log(2), '.', ...
    'MarkerSize', 20, 'Color', cc );

hh2 = [hh2, h_];

figure(6);
stairs( ttt, nn, '-', 'Color', cc );
hold on;

intDoLengthAn( clist, list )


end


function  pos = intGetPos( ID, clist, starter )
% intGetPos : gets the position of where the cell should be drawn.

[ID1,ID2] = intGetDaughter( ID, clist );

flag1 = isnan(ID1) + (ID1==0);
flag2 = isnan(ID2) + (ID2==0);

pos = find( starter== ID );

if (~flag1) && (flag2)
    pos = (pos + intGetPos( ID1, clist, starter ))/2;
elseif (flag1) && (~flag2)
    pos = (pos + intGetPos( ID2, clist, starter ))/2;
elseif (~flag1) && (~flag2)
    pos = (intGetPos( ID1, clist, starter ) + ...
        intGetPos( ID2, clist, starter ) )/2;
end

end


function [ID1,ID2] = intGetDaughter( ID, clist )
global daughter1_index
global daughter2_index
ind = find( clist.data(:,1)==ID );

if isempty(ind)
    ID1 = nan;
    ID2 = nan;
else
    ID1 = clist.data(ind,daughter1_index);
    ID2 = clist.data(ind,daughter2_index);
end

end

function intDoLengthAn( clist, list )

flagger = ismember( clist.data(:,1), list );


lengths = squeeze( clist.data3D(flagger,2,:) );

figure(4);
semilogy( lengths' );
hold on;


lsum = nansum(lengths,1);
figure(5);
semilogy( lsum );
hold on;

figure(6);
semilogy( lsum/lsum(1),':' );
hold on;


end



