function dirname = fixDir( dirname )
% fixDir : adds a directory separator eg '/' at the end
% of dirname if it doesn't exist
% INPUT :
%   dirname : String of directory name
% OUTPUT :
%   dirname : String of directory name with '/' at the end
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

if ~isempty( dirname )
    if strcmp(dirname,'.')
        dirname = pwd;
    end
    
    if dirname(end) ~= filesep
        dirname = [dirname,filesep];
    end
end

end