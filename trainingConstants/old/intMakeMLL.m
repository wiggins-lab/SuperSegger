function mll = intMakeMLL ( E, sigma )
% intMakeMLL : calculate minus log likelihood for the model of on and off.
% The model assumes the following :
% Probability of being on : 
% exp (sigma * E / 2) / ( exp (sigma * E / 2) + exp ( - sigma * E / 2) )
% Probability of being off : 
% exp ( - sigma * E / 2) / ( exp (sigma * E / 2) + exp ( - sigma * E / 2) )
% The maximum likelihood is then mll = Sum log P (sigma | X) 
% which comes down to  -(E/2).*sigma + logCosh(E/2) + log(2);
%
% INPUT :
%       E : is the scoring vector
%       sigma : is the sigma vector

if ~exist( 'sigma', 'var' ) || isempty( sigma )
    sigma = ones( size( E ) );
end

mll = -(E/2).*sigma + logCosh(E/2) + log(2);

end