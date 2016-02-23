function Neo_Crop(dirname_)
% Neo_Crop : cropps off the right and left sides of 'Neo' camera images 
% due to the presence of black bands. Note this function writes over the 
% existing images. Written by Jonathan Sparks 6/27/2012


contents = dir([dirname_,filesep,'*.tif']);
contents_length = numel(contents);


if contents_length && all( size( imread(  [dirname_,filesep,contents(1).name] ) ) == [2160,2592])
    
    disp('Neo camera detected, images will be cropped and saved over')
    
    for i = 1:contents_length;
        
        ImageToCrop = imread([dirname_,filesep,contents(i).name]);
 
        if all( size( ImageToCrop ) == [2160,2592])
            imwrite(ImageToCrop(:,17:2576), [dirname_,filesep,contents(i).name],'tif','Compression', 'none')
        end
        
    end
else
        disp('Neo camera not detected.');

end


end