function out = drill( dataA, str )
% drill : outputs an array of objects from an array of
% structures or cell array of structures of structures.
%
% for example dril (cellA.coord, A) should output an array of A from
% A = CellA{:}.coord.A
% INPUT :
%       dataA: array of structures
%       str : name of field to be extracted
% OUTPUT :
%       out : extracted array
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

num       = numel(  dataA );
cell_flag = iscell( dataA );

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
end

out = cell2mat( tmp_array );
ss  = size( dataA );
out = reshape( out, ss);




end