function mov = makeCellMovie(data, CONST, FLAGS, clist)
% makeCellMovie : creates a movie for a single cell file
% INPUT :
%       data : a Cell data structure
% OUTPUT :
%       mov : movie file
%
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


if ~isfield (CONST.view,'fluorColor')
    CONST.view.fluorColor = {'g','r','b'};
end

figure(2);
num_im = numel(data.CellA);

ss = [0,0];
for ii = 1:num_im
    ss_tmp = size(data.CellA{ii}.phase);
    ss(1) = max([ss(1),ss_tmp(1)]);
    ss(2) = max([ss(2),ss_tmp(2)]);
end


for ii = 1:num_im
    figure(2);
    clf;
    dataA = data.CellA{ii};


%     back  = ag(dataA.phase);
%     
%     if isfield( dataA, 'fluor1' )        
%         fluo  = ag(dataA.fluor1);
%     else
%         fluo = back*0;
%     end;
%     
%     
%     if isfield( dataA, 'fluor2' )        
%         fluo2 = ag(dataA.fluor2);
%     else
%         fluo2 = fluo*0;
%     end;
%     
%     
%     mask_ = imdilate(dataA.mask,strel('square',3));
%     mask  = dataA.mask;
%     outline= mask_-mask;
%     maski = ag(outline);
%     
%     if exist( 'fluo2', 'var' );
%         fluo2_thresh = fluo2(logical(mask));
%         fluo2_thresh = mean(fluo2_thresh);
%     end
%     
%     fluo_thresh = fluo(logical(mask));
%     fluo_thresh = mean(fluo_thresh);
%     gChan = fixIm(0.6*ag(double(uint8(fluo-0*fluo_thresh)).*(0.3+double(mask)*0.6))+0.3*back,ss);
%     [bChan,roffset] = fixIm(0.3*maski+0.3*back,ss);
%     
%     if exist( 'fluo2', 'var' );
%         rChan = fixIm(0.6*ag(double(uint8(fluo2-0*fluo2_thresh)).*(0.3+double(mask)*0.6))+0.3*back,ss);
%     else
%         rChan = fixIm(0.3*back,ss);
%     end
    
    [~,roffset] = fixIm( dataA.phase, ss);

    if FLAGS.autoscale 
        imm = comp( dataA.phase );
    else
        imm = comp( {dataA.phase,  clist.imRangeGlobal(:,1) } );
    end
    
    if ~FLAGS.phase_flag
        imm = 0*imm;
    end
    
    nc = numel(find(~cellfun('isempty',strfind(fieldnames(dataA),'fluor'))));
    
    for jj = 1:nc
        fluorName =  ['fluor',num2str(jj)];
        
        if FLAGS.f_flag == jj || FLAGS.composite
            if isfield(dataA, fluorName )
                cc = CONST.view.fluorColor{jj};
                
                if FLAGS.filt(jj) && isfield( dataA, [fluorName,'_filtered'] )
                    fluor_tmp =  dataA.([fluorName,'_filtered']);
                else
                    fluor_tmp = dataA.(fluorName);
                end
                
                if FLAGS.autoscale || FLAGS.filt(jj)
                    imm = comp( {imm}, {fluor_tmp, cc } );
                else
                    imm = comp( {imm}, ...
                        {fluor_tmp, clist.imRangeGlobal(:,jj+1), cc} );
                end
            end
        end
    end
    
    mask = dataA.mask;
    mask = double(mask)+ 0.33*(1-double(mask));
    
    imm = comp( {imm, 'mask', mask } );
    
    imshow( imm, [],'InitialMagnification','fit');
    
    
    if FLAGS.s_flag
        hold on;
        
        ro = dataA.r_offset;
        r = dataA.r;
        
        %     ro = dataA.r_offset;
        %     r = dataA.r;
        %     plot( r(1)-ro(1)+1+roffset(1), r(2)-ro(2)+1+roffset(2), 'w.' );
        %
        %     ll = dataA.length;
        %     llmaj = [ll(1),-ll(1)];
        %     llmin = [ll(2),-ll(2)];
        %
        %     xx = llmaj*dataA.coord.e1(1)/2;
        %     yy = llmaj*dataA.coord.e1(2)/2;
        %     plot( r(1)-ro(1)+1+xx+roffset(1), r(2)-ro(2)+1+yy+roffset(2), 'b:' );
        %
        %     xx =  llmin*dataA.coord.e2(1)/2;
        %     yy = llmin*dataA.coord.e2(2)/2;
        %     plot( r(1)-ro(1)+1+xx+roffset(1), r(2)-ro(2)+1+yy+roffset(2), 'b:' );
        
        for jj = 1:nc
            fluorName =  ['locus',num2str(jj)];
            if FLAGS.f_flag == jj || FLAGS.composite
                if isfield(dataA, fluorName  )
                    cc = CONST.view.fluorColor{jj};
                    
                    num_spot = numel( dataA.(fluorName) );
                    for jj = 1:num_spot;
                        r = dataA.(fluorName)(jj).r;
                        plot( r(1)-ro(1)+1+roffset(1), r(2)-ro(2)+1+roffset(2),...
                            '.', 'Color', cc);
                    end
                end
            end
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
