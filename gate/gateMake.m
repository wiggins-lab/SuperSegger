function [clist] = gateMake( clist, ind, x0 )
% gate : used to create a gate field in the clist.
%
% INPUT :
%       clist : table of cells with time-independent variables
%       ind : index to gate on, from clist definitions
%       x0 : value to gate on, if it doesn't exist you can choose from the
%       plot
%
% OUTPUT :
%   clist0 : list of cells with gate field
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

ncell = size(clist.data,1);

nind = numel(ind);

if  nind == 1
    clf;
    [y,xx] = gateHist( clist, ind);
    hold on;
  
    c_flag = 1;
    gxx = zeros( 2, 2 );
    disp( 'click on the max and min value');
    
    if ~exist( 'x0', 'var' ) || isempty( x0 )
        for i = 1:2            
            tmp = ginput(1);
            if ~isempty(tmp)
                gxx(i,:) = tmp;                
                plot( gxx(i,1)+[0,0], [min(y(y>0)),max(y)], 'r--' );
            end
        end        
        gxx(:,1)
    else
        gxx(:,1) = x0;        
    end
    
    if isfield( clist, 'gate' )
        ngate = numel(clist.gate)+1;
    else
        ngate = 1;
        clist.gate = [];
    end
    
    clist.gate(ngate).x = gxx(:,1);
    clist.gate(ngate).ind = ind;
    gateHist( clist, ind, xx, 'r' );
    plot( gxx(1)+[0,0], [min(y(y>0)),max(y)], 'r--' );
    plot( gxx(2)+[0,0], [min(y(y>0)),max(y)], 'r--' );
    
elseif nind == 2
    
    clf;
    HIST_LIM = 1e3;
    
    if ncell < HIST_LIM
        gateDot( clist, ind )
    else
        [YY,XX] = gateHist( clist, ind );
        backer = ag(YY);
        imagesc(XX{2},XX{1},cat(3, backer*0,backer*0,backer))
        set( gca, 'YDir', 'normal' );
        
        ylabel( clist.def{ind(2)} );
        xlabel( clist.def{ind(1)} );
    end
    
    hold on;
    
    clist_ = gate( clist);
    tmp1 = clist_.data(:,ind(1));
    tmp2 = clist_.data(:,ind(2));
    dvar = [var(tmp1(~isnan(tmp1))),...
        var(tmp1(~isnan(tmp2)))];
    
    

    % do polygon gate
    c_flag = 1;
    disp('Draw polygon. Finish by pressing return' );
    i = 0;
    xx = zeros( 100, 2 );
    
    while c_flag;
        i = i+1;        
        tmp = ginput(1);        
        if isempty(tmp)
            if i ~= 1
                plot( xx([i-1,1],1), xx([i-1,1],2), 'r-' );
            end
            
            c_flag = false;
            numvert = i-1;
        else     
            dr = (xx(1,:)-tmp );
            if (i>1) && (sum((dr.^2)./dvar) < 0.001 )
                numvert = i-1;
                c_flag = false;
                plot( xx([1,numvert],1), xx([1,numvert],2), 'r-' );   
            else
                xx(i,:) = tmp;
                
                if i == 1
                    plot( xx(1,1), xx(1,2), 'r-' );
                else
                    plot( xx([i,i-1],1), xx([i,i-1],2), 'r-' );
                end
            end
        end
    end
    
    xx = xx(1:numvert,:);

    if isfield( clist, 'gate' )
        ngate = numel(clist.gate)+1;
    else
        ngate = 1;
        clist.gate = [];
    end
    
    clist.gate(ngate).ind = ind;
    clist.gate(ngate).xx = xx;
    
    
    if ncell < HIST_LIM
        gateDot( clist, ind, 'r' );
    else
        
        [xx_,yy_] = meshgrid( XX{2},XX{1} );
        mask_it = inpolygon( xx_, yy_, xx(:,1),xx(:,2) );
        
        backerR = backer;
        backerR(~mask_it) = 0;
        backer(mask_it) = 0;
        
        imagesc(XX{2},XX{1},cat(3, backerR,0*backer,backer));
        hold on;
        set( gca, 'YDir', 'normal' );
        plot( xx([1:end,1],1), xx([1:end,1],2), 'r:' );
        
    end
else
    disp( 'Error: wrong number of indices' );
    return
end


end