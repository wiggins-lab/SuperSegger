function im = intImLoader( imname, CONST )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

 tmp_im = intImRead( imname );

 if isfield( CONST.superSeggerOpti, 'rescale' ) && ...
            CONST.superSeggerOpti.rescale ~= 1
        im = imresize( tmp_im, CONST.superSeggerOpti.rescale );
    else
        im = tmp_im;
 end
    
 
end

