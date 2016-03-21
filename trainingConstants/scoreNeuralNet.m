function  [rawScore] = scoreNeuralNet (x,net)
% return scores for a trained Pattern Recognition Problem with a Neural Network


x = x';
%y = houseFcn(x);
%y = net(x);
y = houseNeuralSimulation(x,net);
prob  = y(2,:); % probabilities of second class (score = 1)
%score = round(prob); 


% because of the way scores were calculated in the past I will shift the
% rawScore by .5 and multiply by 100 to make them spread out!
rawScore = (prob - 0.5) * 100; 

end

