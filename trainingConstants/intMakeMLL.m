function mll = intMakeMLL ( E, sigma )
% intMakeMLL : calculate minus log likelihood for a model where ?

if ~exist( 'sigma', 'var' ) || isempty( sigma )
    sigma = ones( size( E ) );
end

mll = -(E/2).*sigma + logCosh(E/2) + log(2);

end