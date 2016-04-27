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
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


x = x';
y = houseNeuralSimulation(x,net); % same as y = net(x) but faster
prob  = y(2,:); % probabilities of second class (score = 1)

% because of the way scores were calculated in the past I will shift the
% rawScore by .5 and multiply by 100 to make them spread out!
rawScore = (prob - 0.5) * 100; 

end

