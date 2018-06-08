function intImWrite(im,out_name) 
% More flexible metho of writing images. Can use save if the image name is
% .mat.
if numel( out_name ) > 4
if strcmp( out_name(end-3:end), '.mat' )
   out_name = intFixFileName( out_name, '.mat' );
   save(  out_name, 'im' );            
else
   out_name = intFixFileName( out_name, '.tif' ); 
   imwrite(uint16(im), out_name ,'tif','Compression', 'none');
end

end


