function [ flag ] = isnum( str )
% isnum : returns true if string is a number

numChar = '0123456789';
flag = ismember( str, numChar);

end

