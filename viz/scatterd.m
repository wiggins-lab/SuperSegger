function scatterd( x, y, dx, dy, int )


int_max = max( int );
int_min = min( int );


cc = colormap;


nc = size( cc, 1);




ns = 8;
t = (0:ns)/ns*2*pi;

xs = cos( t );
ys = sin( t );

nn = numel( x );

for ii = 1:nn
    
   xs_ = x(ii) + dx(ii)*xs; 
   ys_ = y(ii) + dy(ii)*ys;

   ind = round(nc*(int(ii)-int_min)/(int_max-int_min));
   if ~ind
       ind = 1;
   end
   
   if ~isnan(ind)
   
    fill( xs_, ys_, cc(ind,:), 'EdgeColor', 'none' );
   end
   hold on;
   
end








end