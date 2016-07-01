function [ im ] = comp( phase, imr, img, imb )
% comp  : creates composite image 

backer = 0.8*ag( phase );

im = cat( 3, backer, backer, backer );

if exist( 'imr', 'var' ) && ~isempty( imr );
    
    im(:,:,1) = im(:,:,1) + ag( imr );
end


if exist( 'img', 'var' ) && ~isempty( img );
    
    im(:,:,2) = im(:,:,2) + ag( img );
end

if exist( 'imb', 'var' ) && ~isempty( imb );
    
    im(:,:,3) = im(:,:,3) + ag( imb );
end


end

