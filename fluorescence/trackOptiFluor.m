function trackOptiFluor(dirname,CONST,header)
% trackOptiFluor calculates the mean background fluorescence for each frame.
% This is the mean fluorescence of the non cell regions. No focus fitting is
% done at this stage. It saves the information in the err/seg
% files under data_c.fl1bg for channel 1, data_c.fl2bg for channel 2, etc.
%
% INPUT :
%   dirname: seg folder eg. maindirectory/xy1/seg
%   CONST: segmentation constants.
%   header : string displayed with information
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou & Paul Wiggins.
% University of Washington, 2016
% This file is part of SuperSegger.
%
% SuperSegger is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% SuperSegger is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with SuperSegger.  If not, see <http://www.gnu.org/licenses/>.


if ~exist('header','var')
    header = [];
end

SE = strel( 'disk', 5 );

if(nargin<1 || isempty(dirname))
    dirname = '.';
end
dirname = fixDir(dirname);

% Get the track file names...
contents=dir([dirname '*_err.mat']);
num_im = numel(contents);

if CONST.parallel.show_status
    h = waitbar( 0, 'Fluorescence Computation');
    cleanup = onCleanup( @()( delete( h ) ) );
else
    h = [];
end

nc = 0;
if numel(contents) > 0
    data_c = loaderInternal([dirname,contents(1).name]);
    datacFields = fieldnames(data_c);
    nf = numel(datacFields);
    % goes through the fields in data_c and calculates the number of fluorescence channels
    for j = 1:nf;
        if numel(strfind(datacFields{j},'fluor')==1) && ...
                ~numel(strfind(datacFields{j},'filtered')) && ...
                ~numel((strfind(datacFields{j},'fluor0')))
            nc = nc+1;
        end
    end
end

% loop through all the cells.
if nc > 0
    for i = 1:num_im
        data_c = loaderInternal([dirname,contents(i).name]);
        
        % Compute the background fluorescence level in every channel
        ss = size( data_c.mask_cell );
        
        for j = 1 : nc
            fluor_name = ['fluor',num2str(j)];
            fluor_field = data_c.(fluor_name);
            if isfield( data_c, 'crop_box' );
                yycb = max([1,ceil(data_c.crop_box(1))]):min([ss(1),floor(data_c.crop_box(3))]);
                xxcb = max([1,ceil(data_c.crop_box(2))]):min([ss(2),floor(data_c.crop_box(4))]);
                fluor_tmp = fluor_field(yycb,xxcb);
                mask_bg   = data_c.mask_bg(yycb,xxcb);
            else
                fluor_tmp = fluor_field;
                mask_bg   = data_c.mask_bg;
            end
            
            bgFluorName = ['fl',num2str(j),'bg'];
            back_mask = logical(imdilate(mask_bg,SE));
            data_c.(bgFluorName) = mean(fluor_tmp(~back_mask ));
        end
        
        % save the updated err files.
        dataname = [dirname,contents(i).name];
        save(dataname,'-STRUCT','data_c');
        
        if CONST.parallel.show_status
            waitbar(i/num_im,h,['Fluor Comp--Frame: ',num2str(i),'/',num2str(num_im)]);
        else
            disp([header, 'Fluor Comp frame: ',num2str(i),' of ',num2str(num_im)]);
        end
        
    end
end

if CONST.parallel.show_status
    close(h);
end

end


function data = loaderInternal( filename )
data = load( filename );
end