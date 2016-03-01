function [ I ] = fitKymo4( kymo, kymoMask, disp_flag )
% fitKymo4 : fits the intensities to a model of polar localization
%
% INPUT :
%       kymo : kymograph
%       kymoMask : kymograph mask
%       disp_flag : 1 to display images, 0 to not display images
% OUTPUT:
%       I : Fitted intensities
%       where  I(1) is fitted to the Old Pole, I2 to Mid Cell (Old),
%       I3 to Mid Cell (New), I4 to  the New Pole and I5 is the Total
%
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.



epp = 0.65;
tmp = kymoMask(:);
diam = max( tmp ); %  max of mask.. this should give you the diameter of the cell..?
diam = mean( tmp(tmp>0.9*diam ) );
cutter = epp*diam;
kymoMask_ = kymoMask/diam;
kymoMask_(kymoMask_>1) = 1;
kymoMaskCS    = cumsum(kymoMask_);
kymoMaskCSrev = cumsum(kymoMask_(end:-1:1,:));
kymoMaskCSrev = kymoMaskCSrev(end:-1:1,:);
kymoMaskDif = 0.5*(kymoMaskCS-kymoMaskCSrev);
kymoMask_ = double(kymoMaskCS>cutter).*double(kymoMaskCSrev>cutter)+double(abs(kymoMaskDif)>(cutter));

if disp_flag
    figure(88)
    clf;
    title ('Consensus Kymograph with masked middle')
    imagesc( uint8(0.33*(1+cat(3,kymoMask_,kymoMask_,kymoMask_)).*double(colorize(kymo, kymoMask))));
end

depp = 0.2;
ivec = 0:depp:cutter;
ss = size( kymo );
T0   = ss(2); % time frames in the kymograph
I = zeros( T0, 5 );

for ii = 1:T0
    I(ii,1)=intDoInt( kymoMaskCS(:,ii),kymo(:,ii),ivec, depp );
    I(ii,2)=intDoInt(-kymoMaskDif(end:-1:1,ii),kymo(end:-1:1,ii),ivec, depp );
    I(ii,3)=intDoInt( kymoMaskDif(:,ii),kymo(:,ii),ivec, depp );
    I(ii,4)=intDoInt( kymoMaskCSrev(end:-1:1,ii), kymo(end:-1:1,ii),...
        ivec, depp );
    I(ii,5)=sum( kymo(:,ii) );
end

if disp_flag
    figure(99);
    clf;
    imshow( I, [] );
    title ('Intensity per time frame fitted to different models')
    xlabel( 'Different Fits - pole,mid,midnew,new,total' ); % does not show
    ylabel( 'Time Frames in Kymograph');
    colormap jet;
    
    figure(98);
    clf;
    tt = (0:(T0-1))/(T0-1);
    plot( tt, I(:,1), 'r.-');
    hold on;
    plot( tt, I(:,2), 'g.-');
    plot( tt, I(:,3), 'b.-');
    plot( tt, I(:,4), 'y.-');
    plot( tt, I(:,5), 'm.-');
    title ('Intensity during the cell cycle fitted to different models')
    legend('Old Pole','Mid Cell (Old)',...
        'Mid Cell (New)','New Pole','Total');
    xlabel( 'Time (Cell Cycle)' );
    ylabel( 'Intensity (AU)');
    
end

end


function I = intDoInt( x, y, xi, depp )

ind1 = find( x > min(x), 1, 'first' )-1;
ind2 = find( x < max(x), 1, 'last'  )+1;
I = sum( depp * interp1( x(ind1:ind2), y(ind1:ind2), xi ));

end