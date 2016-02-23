function [ I ] = fitKymo4( kymo, kymoMask, disp_flag )
%fitKymo4 

epp = 0.65;

tmp = kymoMask(:);
diam = max( tmp );
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
imagesc( uint8(0.33*(1+cat(3,kymoMask_,kymoMask_,kymoMask_)).*double(colorize(kymo, kymoMask))));

end
depp = 0.2;
ivec = 0:depp:cutter;



ss = size( kymo );
T0   = ss(2);
xmax = ss(1);

I = zeros( T0, 5 );

for ii = 1:T0
    I(ii,1)=intDoInt( kymoMaskCS(:,ii),           kymo(:,ii), ...
        ivec, depp );
    I(ii,2)=intDoInt(-kymoMaskDif(end:-1:1,ii),   kymo(end:-1:1,ii),...
        ivec, depp );
    I(ii,3)=intDoInt( kymoMaskDif(:,ii),          kymo(:,ii),...
        ivec, depp );
    I(ii,4)=intDoInt( kymoMaskCSrev(end:-1:1,ii), kymo(end:-1:1,ii),...
        ivec, depp );
    I(ii,5)=sum( kymo(:,ii) );
end

if disp_flag
    figure(99);
    clf;
    imshow( I, [] );
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
    
    legend('Old Pole','Mid Cell (Old)',...
        'Mid Cell (New)','New Pole','Total');
    xlabel( 'Time (Cell Cycles)' );
    ylabel( 'Intensity (AU)');
    
end

end


function y = fitFun( x, ymask, I0, x1, s1, I1, x2, s2, I2, x3, s3, I3 )

y = I0.*ymask + ...
    sqrt(1/(2*pi*s1^2))*abs(I1)*exp( -(x-x1).^2/(2*s1^2) ) + ...
    sqrt(1/(2*pi*s2^2))*abs(I2)*exp( -(x-x2).^2/(2*s2^2) ) + ...
    sqrt(1/(2*pi*s3^2))*abs(I3)*exp( -(x-x3).^2/(2*s3^2) );

end


function I = intDoInt( x, y, xi, depp )


    ind1 = find( x > min(x), 1, 'first' )-1;
    ind2 = find( x < max(x), 1, 'last'  )+1;

    I = sum( depp * interp1( x(ind1:ind2), y(ind1:ind2), xi ));

end