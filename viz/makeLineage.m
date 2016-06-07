%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Function makeLineage( clist, ID_, min_width )
%%
%% Stella & Paul 
%% 2016/06/07, 
%% University of Washington
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% clist: clist list of cells and characteristics
%
% ID_: vector of cell ID to include
%
% min_width: min width of trees in cells
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function makeLineage( clist, ID_, min_width )

figure(1)
clf;
figure(2);
clf;
figure(3);
clf;


if ~exist( 'ID_', 'var' );
    ID_ = [];
end

if ~exist( 'min_width' ) || isempty( min_width )
    min_width = 0;
end


clf;
num = size( clist.data, 1 );


starter = [];
hh = [];
hh2 = [];

legend_text = {};
count = 0;

if isempty( ID_ )
    for ii = 1: num
        
        
        if clist.data(ii,61) == 0
            % Make new lineage
            ID = clist.data(ii,1);
            
            [width,list,time,death,stat0,starter] = intGetWidth(ID, clist, starter);
            
            if width >= min_width
                [hh, hh2] = intDoDraw( clist, list, time, death, stat0, starter, hh, hh2 );
                count = count + 1;
                
                legend_text{count} = ['Cell ',num2str( ID )];
            end
            
        end
        
    end
else
    for ii = 1:numel(ID_)
        
        ID = ID_(ii)
        [width,list,time,death,stat0,starter] = intGetWidth(ID, clist, starter);
        
        [hh,hh2] = intDoDraw( clist, list, time, death, stat0, starter, hh, hh2 );
        
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

ylim_ = ylim;
ylim( [0.5,ylim_(end)]);
xlim( [-.1,1.1]*height1 );


figure(3);
ylabel( 'Number of cells' );
xlabel( 'time (frames)' );
legend( hh, legend_text, 'Location' , 'NorthWest' );
set( gca, 'YScale', 'log'  );
title( 'Number of Cells' );

legend( hh2, legend_text, 'Location' , 'NorthWest' );


ylim_ = ylim;
ylim( [0.5,ylim_(end)]);
xlim( [-.1,1.1]*height1 );


end

function [width,list,time,death,stat0,starter] = intGetWidth(ID, clist, starter)

ind = find( clist.data(:,1)==ID );

if isempty(ind) || (ID == 0) || isnan(ID)
    width = 0;
    list  = [];
    time  = [];
    death = [];
    stat0 = [];
else
    ID1 = clist.data(ind,62);
    ID2 = clist.data(ind,63);
    
    if isnan(ID1) || isnan(ID2) || (ID1==0) || (ID2==0)
        starter = [starter,ID];
    end
    
    [w1,l1,t1,d1,s1,starter] = intGetWidth( ID1, clist, starter );
    [w2,l2,t2,d2,s2,starter] = intGetWidth( ID2, clist, starter );
    
    stat0_ = clist.data(ind,9);
    death_ = clist.data(ind,5);
    time_  = clist.data(ind,4);
    
    %death_ = death_ + time_;
    
    width =  1 + w1 + w2;
    list  = [ID,l1,l2];
    time  = [time_,t1,t2];
    death = [death_,d1,d2];
    stat0 = [stat0_,s1,s2];
end
end


function [hh,hh2] = intDoDraw( clist, list, time, death, stat0, starter, hh, hh2  )

%% Show the lineages
figure(1);

num = numel( list );
for ii = 1:num
    
    if stat0(ii) == 2
        cc = 'b';
    elseif stat0(ii) == 1
        cc = 'g';
    else
        cc = 'r';
    end
    
    ID = list(ii);
    
    pos = intGetPos( ID, clist, starter );
    
    
    plot( pos+[0,0], [time(ii)-1,death(ii)], '-', 'Color', cc, 'MarkerSize', 20 );
    hold on;
    
    
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
    
    plot( [pos1,pos2], [0,0] + death(ii), 'Color', 'b' );
    
    
    h = text( pos, time(ii)-1, [' ',num2str( ID )], ...
        'VerticalAlignment', 'middle', 'HorizontalAlignment', 'left' );
    
    set( h, 'rotation', 90 );
    
end

%% Show the cell number;
figure(2);

tt = sort( time );

nn = 1:numel(tt);

h_ = stairs( tt, nn );

hh = [hh, h_];

hold on;

cc = get(h_,'Color' );

first_death_time = min(death(ismember( list, starter )));

ind = sum(first_death_time>tt);
if ~ind
    ind = 1;
end

plot( first_death_time, nn(ind), '.', ...
    'MarkerSize', 20, 'Color', cc );


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

h_ = stairs( ttt, nn, '-', 'Color', cc );
hold on;

ind = sum(first_death_time>ttt);
if ~ind
    ind = 1;
end

plot( first_death_time, nn(ind), '.', ...
    'MarkerSize', 20, 'Color', cc );

hh2 = [hh2, h_];


end


function  pos = intGetPos( ID, clist, starter )

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

ind = find( clist.data(:,1)==ID );

if isempty(ind)
    ID1 = nan;
    ID2 = nan;
else
    ID1 = clist.data(ind,62);
    ID2 = clist.data(ind,63);
end

end

