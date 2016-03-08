function dirname = fixDir( dirname )
% fixDir : adds a directory separator eg '/' at the end 
% of dirname if it doesn't exist
% INPUT :
%   dirname : String of directory name
% OUTPUT :
%   dirname : String of directory name with '/' at the end
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

if strcmp(dirname,'.')
    dirname = pwd;
end

if dirname(end) ~= filesep
    dirname = [dirname,filesep];
end

end