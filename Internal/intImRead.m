function im = intImRead(out_name)
% More flexible method for loading images... if the file is a mat file, it
% will load the image in that... else it uses imread
im = [];

if numel(out_name) > 4
    if strcmp(out_name([end-3:end]), '.mat' )
        tmp = load(  out_name );
        if isfield( tmp, 'im' );
            im  = tmp.im;
        end
    elseif strcmp(out_name([end-3:end]), '.tif' )
        im = imread( out_name );
    end
    
    if isempty( im )
       error( ['Could not open ', out_name,...
           '. Check to make sure files have the correct name',...
           'structure including consistent case.'] ); 
    end
end


if numel(size(im)) > 2
    disp('Images are in color - attempting to convert to monochromatic.');
    im = convertToMonochromatic(im);
end
end


