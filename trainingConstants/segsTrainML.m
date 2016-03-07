function A_fit = segsTrainML( score, vector, A0 )

figure(2);
ss = size(vector);
activeInd = 1:(ss(2)+1);

% minimizing of fitFunScore starting at A0(activeInd)
% stops when maximum coordinate difference between current A and old A is
% 1e-4 and corresponding difference in function values is less than or
% equal to 1e-4, or  Maximum number of function evaluations or iterations 
% reached *200 * num of variables).
[A_fit_] = fminsearch( @fitFunScore, A0(activeInd));

A_fit = A0;
A_fit(activeInd) = A_fit_;


    function ELL = fitFunScore( A__ )
        
        A_ = A0;
        A_(activeInd) = A__;
        E = A_(ss(2)+1) + vector*A_(1:ss(2))';        
        scoreX = E>0;        
        sigma = sign( score-0.5 );
        
        try
            % same thing as intMakeMLL ?
            ell = intMakeMLL(E,sigma);           
        catch ME           
            printError(ME);
        end

        ELL = sum(ell);        
        [y1,x1] = hist(E(logical(score)),100);
        [y0,x0] = hist(E(~score),100);
        
        clf
        semilogy(x1,y1,'.-r');
        hold on;
        semilogy(x0,y0,'.-b');
        
        drawnow;
        
        err = (sum(double(E(~~score)<0))...
            +sum(double(0<E(~score))))/ss(1);
        
        disp(['Error: ',num2str(err)]);
    end
end


function y = sig1(x)

y = atan(x-.5)/pi+.5;

end

function y = freeE(x)

y = exp(x)./(1+exp(x));

end


