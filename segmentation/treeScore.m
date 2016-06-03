function  [rawScore] = treeScore (x,treeClassifier)
% treeScore : calculates the scores of regions/ segments using given classification tree. 
%
% INPUT : 
%   x : input to the network, quantities regarding the segment or region. 
%   treeClassifier : treeClassifier object.
%
% OUTPUT :
%  score : rawScore from -50 to 50. Above 0 is a good segment/region.
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Stylianidou.
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

[~,prob_per_class] = treeClassifier.predict(x);
prob = prob_per_class (:,2)';

% because of the way scores were calculated in the past I will shift the
% rawScore by .5 and multiply by 100 to make them spread out!
rawScore = (prob - 0.5) * 100; 

end

