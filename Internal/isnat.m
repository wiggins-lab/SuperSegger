
function [ naturalNum ] = isnat( list )
% isnat : finds if numbers in an array are natural
% ie positive and non-zero integers)
%
% INPUT : 
%        list : array of numbers
% OUTPUT : 
%        naturalNumb : array of 1 and 0, with 1 where
%        natural numbers are found in the list
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


naturalNum = ~isnan( list );


naturalNum(naturalNum) = and((list(naturalNum)>0),list(naturalNum)==floor(list(naturalNum)));


end

