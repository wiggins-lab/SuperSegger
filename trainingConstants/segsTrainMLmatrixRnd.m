function [A_fit,wrong] = segsTrainMLmatrixRnd( score, info, A0, ...
    num_im, num_seg, c )
% segsTrainMLmatrixRnd : fits A using AIC (Akaike information criterion)
% 
% INPUT :
%       score : score for each segment
%       info : segments parameters (look at superSeggerOpti for more info)
%       A0 : initial A matrix (scoring vector to be optimized for different 
%           cells and imaging conditions )
%       num_im : not used
%       num_seg : not used
%       c : string input
%
% OUTPUT :
%       A_fit : final A scoring vector fitted by AIC
%       wrong : number of disagreeing segments between algorithm and user





% Set the number of evals.
c_num = c(isnumchar( c ));
if ~isempty( c_num )
    total_num = str2num( c_num );
else
    total_num = 20000;
end

wrong = [];
MLL   = [];

% set up graphics
num_calls = 0;
plot_every_n = 500;
ss = size(info);
sum_of_segs = ss(1);
counter = 0;
counter_max = floor(total_num/plot_every_n);
AIC_vec = nan([1,counter_max]);
err_vec = nan([1,counter_max]);
AIC0 = 0;

% symmeterize A0
A0 = (A0'+A0)/2;
A = A0;

% get nonzero elements
flagger = logical(triu(A0 ~= 0.0));
flagger0 = flagger;

% compute an initial AIC value
AIC0 = fitFunScore(A0(flagger));
wrong0 = wrong;
MLL0   = MLL;

if (numel(c)==1) || isnumchar(c(2))
    % use existing flagger
    disp( 'Using existing flagger' );
    
elseif c(2) == 'a'
    % try to add an element
    ind = find( triu(A0 == 0.0) );
    nz = numel( ind );
    qflag = true;
    
    while qflag
        ii = ceil( rand*nz );
        qflag = ~and( ii>0, ii<= nz );
    end
    
    flagger(ind(ii)) = true;
    
    disp( ['Try to add element ', num2str( ii ),'.'] );
elseif c(2) == 'R'
    % try to remove an element
    ind = find( flagger );
    
    nz = numel( ind );
    
    % choose randomly
    qflag = true;
    
    while qflag
        ii = ceil( rand*nz );
        qflag = ~and( ii>0, ii<= nz );
    end
    
    flagger = flagger0;
    flagger(ind(ii)) = false;
    disp( ['Try to remove element ', num2str( ii ),'.'] );
    
elseif c(2) == 'r'
    
    ind = find( flagger );
    nz = numel( ind );
    
    % greedy... choose best
    for ii = 1:nz
        flagger = flagger0;
        flagger(ind(ii)) = false;
        Etmp(ii) = fitFunScore( A(flagger) );
    end
    
    [~,ii] = min( Etmp );
    
    flagger = flagger0;
    flagger(ind(ii)) = false;
    disp( ['Try to remove element ', num2str( ii ),'.'] );
end

% make the symmetric A0 matrix
A = intMakeA( A0(flagger), flagger );
AIC1 = fitFunScore( A(flagger) );
disp( ['Current wrong = ', num2str( wrong0 ), '/', ...
    num2str( sum_of_segs ),' = ',...
    num2str( wrong0/sum_of_segs ),...
    ] );

disp( ['Current  MLL = ', num2str( MLL0 ), '.'] );
disp( ['Current  AIC = ', num2str( AIC0 ), '.'] );
disp( ['Starting AIC = ', num2str( AIC1 ), '.'] );

opt = optimset('MaxFunEvals',total_num, ...
    'MaxIter',total_num, ...
    'Display', 'off' );
[A_fit_] = fminsearch( @fitFunScore, A0(flagger), opt);
A_fit = intMakeA( A_fit_, flagger );
AIC1 = fitFunScore( A_fit(flagger) );

disp(' ');
disp(['Current wrong = ', num2str( wrong ), '/', ...
    num2str( sum_of_segs ),' = ',num2str( wrong/sum_of_segs )]);

disp( ['D AIC = ', num2str( AIC1-AIC0 ), '.'] );
if AIC1 < AIC0
    disp( 'Keeping new A' );
else
    disp( 'Keeping old A' );
    A_fit =  A0;
end

figure(3);
imshow(A_fit ~= 0, []);
figure(1);


    function AIC = fitFunScore( A_ )
        % fitFunScore : calculates AIC for A.
        % The Akaike information criterion (AIC) is a measure of the
        % relative quality of statistical models for a given set of data.
        
        DOF = sum(flagger(:)); % number of non zero terms in A
        A__ = intMakeA( A_, flagger );
        
        %global num_calls
        num_calls = num_calls + 1;
        
        % calculates score / energy of segments
        E = segmentScoreFun(info, A__ );
        
        scoreX = E>0;
        sigma = sign( score-0.5 );
        mll = -(E/2).*sigma + logCosh(E/2) + log(2);
        MLL = sum(mll);
        AIC = MLL + DOF;
        
        if 1 == mod( num_calls, plot_every_n )
            counter = counter + 1;
            AIC_vec(counter) = AIC;
            [ya, xx] = hist(E,100);
            [y1] = hist(E(logical(score)), xx);
            [y0] = hist(E(~score), xx);
            figure(2);
            clf
            subplot(2,2,1);
            
            semilogy(xx, ya,'-k');
            hold on;
            semilogy(xx, ya.*(exp(xx/2)./(exp(xx/2)+exp(-xx/2))),':r');
            semilogy(xx, ya.*(exp(-xx/2)./(exp(xx/2)+exp(-xx/2))),':b');
            semilogy(xx, y1,'.-r');
            semilogy(xx, y0,'.-b');
            ylim( [1, max(ya)] );
            ylabel( 'Number' );
            xlabel( 'Energy' );
            
            subplot(2,2,2);
            xx = -50:1:50;
            [ya] = hist(E, xx);
            [y1] = hist(E(logical(score)), xx);
            [y0] = hist(E(~score), xx);
            
            semilogy(xx, ya,'-k');
            hold on;
            semilogy(xx, ya.*(exp(xx/2)./(exp(xx/2)+exp(-xx/2))),':r');
            semilogy(xx, ya.*(exp(-xx/2)./(exp(xx/2)+exp(-xx/2))),':b');
            semilogy(xx, y1,'.-r');
            semilogy(xx, y0,'.-b');
            ylim( [1, max(ya)] );
            ylabel( 'Number' );
            xlabel( 'Energy' );
            drawnow;
            
            % wrong : user says score is not 0 but program found E<0
            % or user says score is 0 but program found E>0
            wrong = sum(double(E(score~=0)<0))...
                +sum(double(E(score==0)>0));
            
            err_vec(counter) = wrong;
            
            subplot(2,2,3);
            plot( err_vec, '-r' );
            ylabel( 'Errors' );
            xlabel( 'Iterations' );
            drawnow;
            
            subplot(2,2,4);
            plot( AIC_vec, '-r' );
            hold on;
            plot(zeros(size(AIC_vec)) + AIC0, ':b' );
            
            ylabel( 'AIC' );
            xlabel( 'Iterations' );
            drawnow;
        end
    end

end


function y = sig1(x)

y = atan(x-.5)/pi+.5;

end

function y = freeE(x)

y = exp(x)./(1+exp(x));

end

function A = intMakeA( A_, flagger )

A = zeros( size(flagger) );
A(flagger) = A_;
A = A + triu( A, 1 )';

end


function flag = isnumchar( str )
% isnumchar : create a flag of 1 where there are numbers in str
% INPUT :
%       str : string
% OUTPUT :
%       flag : 1's where there are numbers

charnum = '0123456789';
flag = ismember( str, charnum );

end