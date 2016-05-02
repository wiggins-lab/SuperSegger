function [names,num] = getRegNamesPseud()
% getRegNames3 : contains the names of the parameters used for scoring regions.
% The parameters are calculates in cellpropsPseud.m
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou
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

names = { 'long axis: ', ...
    'short axis max: ', ...
    'neck width: ', ...
    'short axis mean: ', ...
    'stm: ', ...
    'RoundIndOver: ', ...
    'RoundIndUnder ', ...
    'Area: ', ....
     };

    names = names';
    num  = 8;
end