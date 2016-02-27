function [A,B,imArray] = pcanal4(dataCellArray,disp_flag)
% pcanal4 : Principal Component Analysis of Grayscale cell tower images
% from makeConstIm.
%
% INPUT :

% OUTPUT :
% Copyright (C) 2016 Wiggins Lab 
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.


if ~exist( 'disp_flag', 'var' ) || isempty( disp_flag )
   disp_flag = true;
end


numCell = numel( dataCellArray );

mag = 0.5;

im = imresize(  dataCellArray{1}, mag );

ss = size( im );
CC = zeros( ss(1)*ss(2) );

tmp_mean =  zeros( 1, ss(1)*ss(2) );

for ii = 1:numCell

  im = imresize(  dataCellArray{ii}, mag );
  tmp = double( im(:) );
  tmp = tmp/sqrt( sum(tmp(:).^2));
  tmp_mean(:) = tmp_mean(:) + tmp(:)/numCell;
  
    
end

for ii = 1:numCell
  im = imresize(  dataCellArray{ii}, mag );
  tmp = double( im(:) );
  tmp = tmp/sqrt( sum(tmp(:).^2));
  
  CC = CC + (tmp-tmp_mean')*(tmp-tmp_mean')';  
    
end


[A,B] = eig( CC );


A1 = reshape(A(:,end),ss);
A2 = reshape(A(:,end-1),ss);
A3 = reshape(A(:,end-2),ss);
A4 = reshape(A(:,end-3),ss);
A5 = reshape(A(:,end-4),ss);
A6 = reshape(A(:,end-5),ss);
A7 = reshape(A(:,end-5),ss);
A8 = reshape(A(:,end-5),ss);

im = [A1,A2,A3,A4;...
      A5,A6,A7,A8];

mm = max(abs(im(:)));


hccolormap = hotcold( 256 );


imArray = { doColorMap(ag( A1, -mm,mm),hccolormap), ...
            doColorMap(ag( A2, -mm,mm),hccolormap), ...
            doColorMap(ag( A3, -mm,mm),hccolormap), ...
            doColorMap(ag( A4, -mm,mm),hccolormap), ...
            doColorMap(ag( A5, -mm,mm),hccolormap), ...
            doColorMap(ag( A6, -mm,mm),hccolormap), ...
            doColorMap(ag( A7, -mm,mm),hccolormap), ...
            doColorMap(ag( A8, -mm,mm),hccolormap)};
        
        

if  disp_flag
figure(100)
imshow( [im], [] );
colormap( hccolormap );
caxis( [-mm,mm])

figure(200);
lambda = diag( B );

semilogy( lambda(end:-1:end-5), '.-y' );


end


end