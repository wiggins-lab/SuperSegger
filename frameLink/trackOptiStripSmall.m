function trackOptiStripSmall(dirname,CONST)
% trackOptiStripSmall : removes small regions that are probably
% not real, typically bubbles, dust, or minicells.
%
% INPUT :
%   dirname : seg folder eg. maindirectory/xy1/seg
%   CONST : Constants file
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


MIN_AREA = CONST.trackOpti.MIN_AREA;
dirseperator = filesep;

if(nargin<1 || isempty(dirname))
    dirname = uigetdir();
    dirname = [dirname,dirseperator];
else
    if dirname(length(dirname))~=dirseperator
        dirname=[dirname,dirseperator];
    end
end

contents=dir([dirname '*_seg.mat']);
num_im = length(contents);
clist = [];

if CONST.show_status
    h = waitbar( 0, 'Strip small cells.');
else
    h = [];
end

% Work barkwards starting at the last frame.
for i = 1:num_im;
    
    if CONST.show_status
        waitbar((num_im-i)/num_im,h,['Strip small cells--Frame: ',num2str(i),'/',num2str(num_im)]);
    end

    data_c = loaderInternal([dirname,contents(i  ).name]);  % load data
        
    %% strip off extra stuff
    %mask__ = bwmorph(bwmorph( masktmp, 'erode'), 'dilate' );
    
    %% remove small area regions
    regs_label = bwlabel( data_c.mask_cell );
    props = regionprops( regs_label, 'Area' );
    
    keepers = find([props(:).Area]>MIN_AREA);
    
    data_c.mask_cell= ismember( regs_label, keepers );
    
    %% fill holes
    ss = size( data_c.phase );
    regs_label = bwlabel( data_c.mask_cell );
    props = regionprops( regs_label, {'Area','BoundingBox'} );
    num_props = numel(props);
    mask_new = false(ss);
    
    for ii = 1:num_props
        [xx,yy] = getBBpad(props(ii).BoundingBox, ss,1);
        
        mask = (regs_label(yy,xx)==ii);
        mask__ = bwmorph(bwmorph( mask, 'dilate'), 'erode' );
        mask__ = imfill(mask__,'holes');
        
        mask_tmp = mask_new(yy,xx);
        mask_tmp(mask__) = true;
        mask_new(yy,xx) = mask_tmp;
    end
    
    data_c.mask_cell = mask_new;
    
    % resave the updated *err.mat file and move on to the previous frame.
    dataname=[dirname,contents(i).name];
    save(dataname,'-STRUCT','data_c');
    
    
end

if CONST.show_status
    close(h);
end

end


function data = loaderInternal( filename );
data = load( filename );
end