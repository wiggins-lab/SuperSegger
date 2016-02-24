function nameInfo = ReadFileName( str )
% ReadFileName extracts the numbers after t,x,y,z in a string *t*c*xy*z* 
%
% INPUT :
%       str : String that contains any of the the strings in strD
% OUTPUT :
%       nameInfo.
%           npos: [4x4 double]
%           strD: {'t'  'c'  'xy'  'z'}
%           basename: before first found strD, eg. 'tsyfp-p-'
%           suffix: after last found number of strD, eg. '.tif'
% npos contains the information for each of the strings in strD
% npos (i,1) is the number after strD(i) in the string
% npos (i,2) is the position of strD(i) in the string
% npos (i,3) is the position of the last number after strD(i) in the string
% npos (i,4) is the length of the numbers after strD(i) in the string
%
% Copyright (C) 2016 Wiggins Lab 
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.

nameInfo = [];
strD = {'t',      'c',      'xy',      'z'};
numD = numel(strD);
npos = zeros(numD,4);

for i = 1:numD
    npos(i,:) = intReadIt( strD{i}, str );
end

basename = str( 1:min(npos(logical(npos(:,2)),2))-1);
suffix_pos = max(npos(:,3))+1;

if ~isempty( suffix_pos )
    suffix = str(suffix_pos:end);
else
    suffix = '';
end

nameInfo.npos = npos;
nameInfo.strD = strD;
nameInfo.basename = basename;
nameInfo.suffix = suffix;

end




function nn = intReadIt( str_search, str );

ns = numel(str_search);
is_num_mask = ismember( str,'01234567890'); % 1 where there are numbers
pos = max(regexpi(str,[str_search,'[0123456789]'])); % finds position of str_search 

if ~isempty(pos)
    pad = min(find( ~is_num_mask(pos+ns:end) ))-1; % find length to next not number
    pos = [pos, pos+pad+ns-1, pad];
    n = str2num(str(pos(1)+ns:pos(2)));
else
    pos = [0,0,0];
    n = -1;
end

nn = [n,pos];

end