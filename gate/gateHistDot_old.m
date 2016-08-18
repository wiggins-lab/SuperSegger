function [y,xx,xarr_s,yarr_s,zvals_s] = gateHistDot(clist, ind, xx, cc)

%Outputs:
%
%y = matrix of 2D histogram values
%xx = 2x1 Cell array where, xx{1} and xx{2} are the bins used to generate y
%zvals_s =  array of all 2D hist values in increasing, sorted orde
%xarr_s =  array of x values; x(i) is the x value corresponding zvals_s(i)
%yarr_s =  array of y values; y(i) is the y value corresponding zvals_s(i)
%
%Inputs:
%
%clist
%ind = array containing the two clist indices you wish to use
%xx = (optional) 2x1 Cell array of preset bins for histogram
%%

clist = gate(clist);

ss = size( clist.data );

NUM_BINS = round((sqrt(ss(1))));
NUM_BINS = 200;

if ~exist( 'xx', 'var' );
    xx = [];
end

nind = numel( ind );

if nind == 2
    
    
    if isempty( xx)
        [y,xx] =hist3( [clist.data(:,ind(2)),clist.data(:,ind(1))], round(([ NUM_BINS, NUM_BINS])) );
    else
        [y,xx] =hist3( [clist.data(:,ind(2)),clist.data(:,ind(1))], xx );    
    end
    
    y(find(y==0))=NaN;
%     cutoff = 50*min(min(y));
%     if max(max(y))>cutoff
%         y(find(y>cutoff))=cutoff;
%     end
    
    xvals = xx{1};
    yvals = xx{2};
    dim=length(y);
    zvals = nan(1,(dim*dim));
    xarr = nan(1,(dim*dim));
    yarr = nan(1,(dim*dim));
    for ii=1:dim
        for jj=1:dim
            if ~isnan(y(jj,ii)) && ~y(jj,ii)==0
                index = jj+(dim*(ii-1));
                xarr(index)=xvals(jj);
                yarr(index)=yvals(ii);
                zvals(index)=y(jj,ii);
            end
        end
    end
    
    % Sort datapoints by z values so highest hits will be plotted last (on
    % top)
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
    
%     figure(5);
%     clf;
%     scatter(yarr_s,xarr_s,10,zvals_s,'o','filled');
%     colormap(jet)
    if(ind(2)<100)
     yname = clist.def{ind(2)};
    end
    if(ind(1)<100)
     xname = clist.def{ind(1)};
    end
    
    zvals_log = log(zvals_s);
    scatter(yarr_s,xarr_s,20,zvals_log,'o','filled');
    colormap(jet)
    if(ind(2)<100)
    ylabel( yname );
    end
    if(ind(1)<100)
     xlabel( xname );
    end
       
    
    set(gca,'Box','on');
    

    
end



end