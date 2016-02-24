function [XX,map,error,dA,DA,dF1,dF2,dF1b,dF2b,mapOld,XXOld,dAOld] ...
    = calcRegsInt( data1, data2, CONST )
% calcRegsInt : calculates the max overlap between data1 and data2 regions
% data 1 and data 2 can be the reverse and current, current and forward
% regions (order does not matter).
%
% INPUT :
%       data_c: region (cell) data structure 1
%       data2 : region (cell) data structure 2
%       CONST :  segmentation constants
% OUTPUT :
%       XX : areal overlap fraction for a region with all other regions
%       map : list of regions that overlap with the current region above the
%      cut off
%       error : is an error flag that is set if the area difference between the
%   primary overlap region is too big or there is not one region in map
%       dA : min(A1,A2)/max(A2,A1) between regions of overlap
%       DA : Change in area between regions of overlap
%       dF1 : Change in fluorescence between regions of overlap
%       dF2 : Change in fluorescence between regions of overlap
%       dF1b : Change in fluorescence between regions of overlap
%       dF2b : Change in fluorescence between regions of overlap
%       mapOld :
%       XXOld :
%       dAOld :
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


OVERLAP_LIMIT_MAX = CONST.trackOpti.OVERLAP_LIMIT_MAX;
OVERLAP_LIMIT_MIN = CONST.trackOpti.OVERLAP_LIMIT_MIN;
dA_LIMIT          = CONST.trackOpti.dA_LIMIT;

if ~isempty( data1 )
    loop_ind    = 1:data1.regs.num_regs;
    XX    = cell( 1, data1.regs.num_regs);
    map   = cell( 1, data1.regs.num_regs);
    error = zeros(1, data1.regs.num_regs);
    dA    = zeros(1, data1.regs.num_regs);
    DA    = zeros(1, data1.regs.num_regs);
    nB    = zeros(1, data1.regs.num_regs);   
    dF1   = 2*ones(1, data1.regs.num_regs);
    dF2   = 2*ones(1, data1.regs.num_regs);
    dF1b  = 2*ones(1, data1.regs.num_regs);
    dF2b  = 2*ones(1, data1.regs.num_regs);
    
    if ~isempty( data2 )        
        for ii = loop_ind
            XX{ii} = zeros(2,5);
            X     = zeros(1,data2.regs.num_regs);
            
            % Get a list of region numbers that overlap with region ii in
            % data 1
            try
                [xx,yy] = getBB( data1.regs.props(ii).BoundingBox );
                mask1 = (data1.regs.regs_label(yy,xx)==ii);
                regs2 = data2.regs.regs_label(yy,xx);
                ind = unique(regs2(mask1));
                ind = ind(data2.regs.num_regs>=ind);
                ind = ind(~~ind);
                ind = reshape( ind(:), 1, numel(ind(:)) );
            catch
                keyboard;
            end
            
            % consider overlapping regions jj = ind.
            for jj = ind
                try
                    % tmp2 is a mask for the overlap region jj
                    tmp2 = double(regs2==jj);
                catch
                    keyboard
                end
                try
                    
                    % area of overlap = sum(tmp2(mask1(:)))
                    % X is area of overlap / max( area of two regions ii
                    % and jj)
                    X(jj) = sum(tmp2(mask1(:)))/...
                        max([data1.regs.props(ii).Area,data2.regs.props(jj).Area]);
                    
                catch ME
                    printError(ME);
                end
            end
            
            % find the biggest fraction
            % ind is NOW the region with the biggest overlap
            [junk, ind] = max(X(:));
            
            if junk == 0
                dA(ii) = 0;
                DA(ii) = 0;
            else
                dA(ii) =  min([data1.regs.props(ii).Area,data2.regs.props(ind).Area])/...
                    max([data1.regs.props(ii).Area,data2.regs.props(ind).Area]);
                DA(ii) =  (data2.regs.props(ind).Area-data1.regs.props(ii).Area)/...
                    data1.regs.props(ii).Area;
            end
            
            [overlap, B] = sort(X,'descend');
            
            nnn = min([5,data2.regs.num_regs]);
            
            XX{ii}(1,1:nnn) = overlap(1:nnn);
            XX{ii}(2,1:nnn) = B(1:nnn);
            
            try
                %B = B(overlap > max([0.5*overlap,OVERLAP_LIMIT_MIN]) );
                B = B(overlap > OVERLAP_LIMIT_MIN );
            catch ME
                printError(ME);
            end
            map{ii} = B;
            
        end
        
        mapOld = map;
        XXOld  = XX;
        dAOld  = dA;
        
        if CONST.trackOpti.HARDLINK_FLAG
            [map, XX] = intDoHardLinkDel( map, XX, DA, CONST );           
            [dA, nB, dF1, dF2, dF1b, dF2b, DA] = intDoInt( data1, data2, map, CONST );           
            [map, XX] = intDoHardLinkDel( map, XX, DA, CONST );
        end
        [dA, nB, dF1, dF2, dF1b, dF2b, DA] = intDoInt( data1, data2, map, CONST );
        
        %if(numel(B) ~= 1) || (dA(ii) < dA_LIMIT)
        %error = or(nB ~= 1, dA < dA_LIMIT);
        error = genError( map, DA, CONST );
        
    end
    
else
    XX     = {};
    map    = {};
    error  = [];
    dA     = [];
    DA     = [];
    dF1    = [];
    dF2    = [];
    dF1b   = [];
    dF2b   = [];
    mapOld = map;
    XXOld  = XX;
    dAOld  = dA;
end
end


function [dA, nB, dF1, dF2, dF1b, dF2b, DA] = intDoInt( data1, data2, map, CONST )
dA    = zeros(1, data1.regs.num_regs);
DA    = zeros(1, data1.regs.num_regs);

nB    = zeros(1, data1.regs.num_regs);

loop_ind    = 1:data1.regs.num_regs;

if CONST.trackOpti.LYSE_FLAG
    dF1   = 2*ones(1, data1.regs.num_regs);
    dF2   = 2*ones(1, data1.regs.num_regs);
    dF1b  = 2*ones(1, data1.regs.num_regs);
    dF2b  = 2*ones(1, data1.regs.num_regs);
else
    dF1 = [];
    dF2 = [];
    dF1b = [];
    dF2b = [];
end

% calculate background levels for the fluor fields.
if CONST.trackOpti.LYSE_FLAG
    if isfield( data1,'fluor1');
        m1back =max([mean( data1.fluor1(:)), mean( data2.fluor1(:))]);
        s1back =max([std( double(data1.fluor1(:))), std( double(data2.fluor1(:)))]);
    end

    if isfield( data1,'fluor2');
        m2back =max([mean( data1.fluor2(:)), mean( data2.fluor2(:))]);
        s2back =max([std( double(data1.fluor2(:))), std( double(data2.fluor2(:)))]);
    end
end

for ii = loop_ind
    % Get a list of region numbers that overlap with region ii in
    % data 1
    try
        [xx,yy] = getBB( data1.regs.props(ii).BoundingBox );
        mask1 = (data1.regs.regs_label(yy,xx)==ii);
        regs2 = data2.regs.regs_label(yy,xx);
    catch
        keyboard;
    end
    
    
    if ~isempty( map{ii} )
        ind = map{ii}(1);
        dA(ii) =  min([data1.regs.props(ii).Area,data2.regs.props(ind).Area])/...
            max([data1.regs.props(ii).Area,data2.regs.props(ind).Area]);
        DA(ii) = (data2.regs.props(ind).Area-data1.regs.props(ii).Area)/...
            data1.regs.props(ii).Area;
        nB(ii) = numel( map{ii} );
        
        if CONST.trackOpti.LYSE_FLAG
            % Calculate the change in mean fluor level in each channel
            % between the regions of max overlap.
            [xx2,yy2] = getBB( data2.regs.props(ind).BoundingBox );
            mask2 = (data2.regs.regs_label(yy2,xx2)==ind);

            if isfield( data1, 'fluor1' )
                fluor_d1 = data1.fluor1(yy,xx);
                fluor_d2 = data2.fluor1(yy2,xx2);
                
                mf1 = mean( fluor_d1(mask1) )-m1back;
                mf2 = mean( fluor_d2(mask2) )-m1back;
                
                mmax = max([mf1,mf2]);
                
                if mmax > s1back
                    dF1(ii) =  min([mf1,mf2])/max([mf1,mf2]);
                else
                    dF1(ii) = 1;
                end
                
                %blind
                fluor_d1 = data1.fluor1(yy,xx);
                fluor_d2 = data2.fluor1(yy,xx);
                
                mf1 = mean( fluor_d1(mask1) )-m1back;
                mf2 = mean( fluor_d2(mask1) )-m1back;
                
                mmax = max([mf1,mf2]);
                
                if mmax > s1back
                    dF1b(ii) =  min([mf1,mf2])/max([mf1,mf2]);
                else
                    dF1b(ii) = 1;
                end
            end
            
            if isfield( data1, 'fluor2' )
                fluor_d1 = data1.fluor2(yy,xx);
                fluor_d2 = data2.fluor2(yy2,xx2);
                
                mf1 = mean( fluor_d1(mask1) )-m2back;
                mf2 = mean( fluor_d2(mask2) )-m2back;
                
                mmax = max([mf1,mf2]);
                
                if mmax > s2back
                    dF2(ii) =  min([mf1,mf2])/max([mf1,mf2]);
                else
                    dF2(ii) = 1;
                end              
                
                %blind
                fluor_d1 = data1.fluor2(yy,xx);
                fluor_d2 = data2.fluor2(yy,xx);
                
                mf1 = mean( fluor_d1(mask1) )-m2back;
                mf2 = mean( fluor_d2(mask1) )-m2back;
                
                mmax = max([mf1,mf2]);
                
                if mmax > s2back
                    dF2b(ii) =  min([mf1,mf2])/max([mf1,mf2]);
                else
                    dF2b(ii) = 1;
                end
            end
            
        end
    end
end
end


