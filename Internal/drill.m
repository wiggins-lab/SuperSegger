function out = drill( dataA, str )
% drill : outputs an array of objects from an array of
% structures or cell array of structures of structures.
%
% For example for superSegger's cell files, if structure is CellA{:}.coord.A
% calling A = drill ( CellA{:}, '.coord.A'), outputs A.
% (note : don't forget the dot at the beginning of str!)
%
% INPUT :
%       dataA: array of structures
%       str : string for name of field to be extracted
% OUTPUT :
%       out : extracted array
%
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins.
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

num = numel(dataA);
cell_flag = iscell(dataA);
tmp_array = cell(1,num);

for ii = 1:num
    if cell_flag
        try
            eval(['tmp_array{ii} = double(dataA{ii}', str,');']);
        catch
            tmp_array{ii} = NaN;
        end
    else
        try
            eval(['tmp_array{ii} = dataA(ii)', str,';']);
        catch
            tmp_array(ii) = {NaN};
        end
    end
    if isempty(tmp_array{ii})
        tmp_array(ii) = {NaN};
    end
end

try
    out = cell2mat(tmp_array);
    ss  = size(dataA);
    out = reshape(out, ss);
catch
    out=tmp_array;
end

end