function [ xx ] = logCosh( y )
% logCosh : expands log(cosh(y)) for large y
%
% It uses use the following expansion
% log(cosh(y)) = log( e^abs|y| + e^-|y| ) - log(2)
%                  = log( e^|y| [ 1+e^-2|y| ] ) - log(2)
%                  = |y| - log( [ 1+e^-2|y| ] ) - log(2)
%                  = |y| - e^-2|y| + e^-4|y|/2 + ... - log(2)
%
% INPUT :
%       y : value of which logCosh is taken
% OUTPUT :
%       xx : result of logCosh(y)
%
% Copyright (C) 2016 Wiggins Lab
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.

xx = log(cosh(y));
flag =  isinf(xx);
y = y(flag);

if ~isempty(y)
xx(flag) = abs(y) + exp( -2*abs(y) ) ...
            - exp( -4*abs(y) )/2 ...
            + exp( -6*abs(y) )/3 ...
            - exp( -8*abs(y) )/4 ...
            + exp( -10*abs(y) )/5 ...
            - exp( -12*abs(y) )/6 - log(2);
end


end

