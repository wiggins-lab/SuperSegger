function list = makenat( list )
% makenat : returns the list with only natural numbers back
% ie positive and non-zero integers)
%
% INPUT : 
%        list : input array of numbers
% OUTPUT : 
%        list : input with only the natural numbers
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


list = list( isnat( list ));

end