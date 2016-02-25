function [M_, G_, C1_, C2_, M, G, C1, C2] = curveFilter( im, b )

%% Make filter 
x = -10:10;

[X,Y] = meshgrid( x, x);
R2 = X.^2+Y.^2;

% filter width
if ~exist( 'b', 'var' ) || isempty( b )
    b = 1.5;
end

v = b^2;

gau = 1/(2*pi*v) * exp( -R2/(2*v) );
f_xx = (2*pi*v^2)*((X/v).^2-1/v).*gau;
f_yy = (2*pi*v^2)*((Y/v).^2-1/v).*gau;
f_xy = (2*pi*v^2)*X.*Y.*gau/v^2;

%% Do filtering
im_xx = imfilter(  im, f_xx, 'replicate' );
im_yy = imfilter(  im, f_yy, 'replicate' );
im_xy = imfilter(  im, f_xy, 'replicate' );

% gaussian curvature
G = im_xx.*im_yy-im_xy.^2;

% mean curvature
M = -(im_xx+im_yy)/2;

% compute principal curvatures
C1 = (M-sqrt(abs(M.^2-G)));
C2 = (M+sqrt(abs(M.^2-G)));

% remove negative values
G_ = G;
G_(G<0) = 0;

M_ = M;
M_(M<0) = 0;

C1_ = C1;
C1_(C1<0) = 0;

C2_ = C2;
C2_(C2<0) = 0;

end

