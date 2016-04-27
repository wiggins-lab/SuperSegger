function mov = makeCellMovie(data)
% makeCellMovie : creates a movie for a single cell file
% INPUT : 
%       data : a Cell data structure
% OUTPUT : 
%       mov : movie file
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


figure(1);
num_im = numel(data.CellA);

ss = [0,0];
for ii = 1:num_im
    ss_tmp = size(data.CellA{ii}.phase);    
    ss(1) = max([ss(1),ss_tmp(1)]);
    ss(2) = max([ss(2),ss_tmp(2)]);
end


for ii = 1:num_im
    clf;
    back  = autogain(data.CellA{ii}.phase);
    
    if isfield( data, 'fluor1' )        
        fluo  = autogain(data.CellA{ii}.fluor1);
    else
        fluo = back*0;
    end;
    
    
    if isfield( data, 'fluor2' )        
        fluo2 = autogain(data.CellA{ii}.fluor2);
    else
        fluo2 = fluo*0;
    end;
    
    
    mask_ = imdilate(data.CellA{ii}.mask,strel('square',3));
    mask  = data.CellA{ii}.mask;
    outline= mask_-mask;
    maski = autogain(outline);
    
    if exist( 'fluo2', 'var' );
        fluo2_thresh = fluo2(logical(mask));
        fluo2_thresh = mean(fluo2_thresh);
    end
    
    fluo_thresh = fluo(logical(mask));
    fluo_thresh = mean(fluo_thresh);
    gChan = fixIm(0.6*autogain(double(uint8(fluo-0*fluo_thresh)).*(0.3+double(mask)*0.6))+0.3*back,ss);
    [bChan,roffset] = fixIm(0.3*maski+0.3*back,ss);
    
    if exist( 'fluo2', 'var' );
        rChan = fixIm(0.6*autogain(double(uint8(fluo2-0*fluo2_thresh)).*(0.3+double(mask)*0.6))+0.3*back,ss);
    else
        rChan = fixIm(0.3*back,ss);
    end
    
    
    imshow( cat(3, rChan, gChan, bChan), [],'InitialMagnification','fit');
    hold on;
    ro = data.CellA{ii}.r_offset;    
    r = data.CellA{ii}.r;
    plot( r(1)-ro(1)+1+roffset(1), r(2)-ro(2)+1+roffset(2), 'w.' );

    ll = data.CellA{ii}.length;
    llmaj = [ll(1),-ll(1)];
    llmin = [ll(2),-ll(2)];    
    
    xx = llmaj*data.CellA{ii}.coord.e1(1)/2;
    yy = llmaj*data.CellA{ii}.coord.e1(2)/2;
    plot( r(1)-ro(1)+1+xx+roffset(1), r(2)-ro(2)+1+yy+roffset(2), 'b:' );
    
    xx =  llmin*data.CellA{ii}.coord.e2(1)/2;
    yy = llmin*data.CellA{ii}.coord.e2(2)/2;
    plot( r(1)-ro(1)+1+xx+roffset(1), r(2)-ro(2)+1+yy+roffset(2), 'b:' );
    
    
    if isfield( data.CellA{ii}, 'locus1'  )
        num_spot = numel( data.CellA{ii}.locus1 );
        for jj = 1:num_spot;
            r = data.CellA{ii}.locus1(jj).r;
            plot( r(1)-ro(1)+1+roffset(1), r(2)-ro(2)+1+roffset(2), 'go' );
        end
    end
    
    if isfield( data.CellA{ii}, 'locus2'  )
        num_spot = numel( data.CellA{ii}.locus2 );
        for jj = 1:num_spot;
            r = data.CellA{ii}.locus2(jj).r;
            plot( r(1)-ro(1)+1+roffset(1), r(2)-ro(2)+1+roffset(2), 'ro' );
        end
    end
    
    drawnow;
    mov(ii) = getframe;
    
end


end

function [imFix,roffset] = fixIm(im, ss)
ssOld = size(im);
imFix = zeros(ss);

offset = floor((ss-ssOld)/2)-[1,1];
if offset(1)<0
    offset(1) = offset(1) + 1;
end
if offset(2)<0
    offset(2) = offset(2) + 1;
end

try
    imFix(offset(1)+(1:ssOld(1)),offset(2)+(1:ssOld(2))) = im;
catch
    '';
end
roffset = offset(2:-1:1);
imFix = uint8(imFix);
end
