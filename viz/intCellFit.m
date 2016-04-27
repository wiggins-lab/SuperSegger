function y = intCellFit( x, x1, x2, h )

y = 0*x;

y( and( x >= (h+x1), x <= (-h+x2) ) ) = 2*h;
ind = and( x >= x1, x < (h+x1) );

y( ind )       = 2*h*sqrt(1-((x(ind)-x1-h)/h).^2);

ind = and( x <= x2, x > (-h+x2) );
y( ind )      = 2*h*sqrt(1-((x(ind)-x2+h)/h).^2);


end