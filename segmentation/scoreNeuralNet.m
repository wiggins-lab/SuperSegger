function  [rawScore] = scoreNeuralNet (x,net)
% scoreNeuralNet : calculates the scores of regions/ segments using a trained neural network 
% Neural network was already trained using a trained Pattern Recognition Problem 
%
% INPUT : 
%   x : input to the network, quantities regarding the segment or region. 
%   net : neural network with parameters optimized for different 
% cells and imaging conditions
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

x = x';
y = net(x); % same as y = net(x) but faster
prob  = y(2,:); % probabilities of second class (score = 1)

% because of the way scores were calculated in the past I will shift the
% rawScore by .5 and multiply by 100 to make them spread out!
rawScore = (prob - 0.5) * 100; 

end

