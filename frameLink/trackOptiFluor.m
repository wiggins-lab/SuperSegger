function trackOptiFluor(dirname,CONST,header)
% trackOptiFluor calculates the basic fluorescence information
% such as mean and integrated intensity. It does not do any focus fitting. 
%
% INPUT : 
%   dirname: seg folder eg. maindirectory/xy1/seg
%   CONST: are the segmentation constants.
%   header : string displayed with information
% 
% Copyright (C) 2016 Wiggins Lab 
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


if ~exist('header')
    header = [];
end


SE = strel( 'disk', 5 );


dirseperator = filesep;
if(nargin<1 || isempty(dirname))
    dirname = '.';
end
dirname = fixDir(dirname);

% Get the track file names...
contents=dir([dirname '*_err.mat']);
num_im = numel(contents);

if CONST.show_status
    h = waitbar( 0, 'Fluor Comp.');
else
    h = [];
end

% loop through all the cells.
for i = 1:num_im;
    data_c = loaderInternal([dirname,contents(i  ).name]);
        
    % Compute the background fluorescence level in both channel
    ss = size( data_c.mask_cell );
    
    if isfield( data_c, 'fluor1' )
        
        if isfield( data_c, 'crop_box' );
            
            yycb = max([1,ceil(data_c.crop_box(1))]):min([ss(1),floor(data_c.crop_box(3))]);
            xxcb = max([1,ceil(data_c.crop_box(2))]):min([ss(2),floor(data_c.crop_box(4))]);
            
            fluor_tmp = data_c.fluor1(yycb,xxcb);
            mask_bg   = data_c.mask_bg(yycb,xxcb);
        else
            fluor_tmp = data_c.fluor1;
            mask_bg   = data_c.mask_bg;
        end
        
        back_mask = logical(imdilate(mask_bg,SE));        
        data_c.fl1bg = mean(fluor_tmp( ~back_mask ));
        
        if isfield( data_c, 'fluor2' )
            
            if isfield( data_c, 'crop_box' );              
                fluor_tmp = data_c.fluor2(yycb,xxcb);
                mask_bg   = data_c.mask_bg(yycb,xxcb);
            else
                fluor_tmp = data_c.fluor2;
                mask_bg   = data_c.mask_bg;
            end
            
            data_c.fl2bg = mean(fluor_tmp( ~back_mask ));
        end
    else
        break;
    end

    % save the updated err files.
    dataname = [dirname,contents(i  ).name];
    save(dataname,'-STRUCT','data_c');
    
    if CONST.show_status
        waitbar(i/num_im,h,['Fluor Comp--Frame: ',num2str(i),'/',num2str(num_im)]);
    else
        disp([header, 'Fluor Comp frame: ',num2str(i),' of ',num2str(num_im)]);
    end
    
end

if CONST.show_status
    close(h);
end

end


function data = loaderInternal( filename )
data = load( filename );
end