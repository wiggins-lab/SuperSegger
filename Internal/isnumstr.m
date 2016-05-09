function [ flag ] = isnum( str )


numChar = '0123456789';

flag = ismember( str, numChar);

end

