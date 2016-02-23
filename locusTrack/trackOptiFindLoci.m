function [clist, clist_def] = trackOptiFindLoci(dirname,CONST,header)
% trackOptiFindLoci fits the foci. Note that this only runs if the number
% of foci to be fit is set in CONST.trackLoci.numSpots.
%
% INPUT : 
%   dirname_xy: is the xy directory
%   skip: frames mod skip are processed 
%   CONST: are the segmentation constants.
%   header : string displayed with information
% 
% Copyright (C) 2016 Wiggins Lab 
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


if ~exist('header')
    header = [];
end

dirname = fixDir( dirname );

% Get the track file names...
contents=dir([dirname  '*_err.mat']);
num_im = numel(contents);
data_c = loaderInternal([dirname  contents(1).name]);
nc = 0;
tmp_fn = fieldnames( data_c );
nf = numel( tmp_fn );

for j = 1:nf;
    if(strfind(tmp_fn{j},'fluor')==1)
        nc = nc+1;
    end
end

% Find Loci can be ||
if isfield( data_c, 'fluor1' );
    if CONST.show_status
        h = waitbar( 0, 'Find Loci.');
    else
        h = [];
    end
    for i = 1:num_im
        %parfor i = 1:num_im;
        intDoLoci( i, dirname, contents, num_im, nc, CONST);
        if CONST.show_status
            waitbar(i/num_im,h,['Find Loci--Frame: ',num2str(i),'/',num2str(num_im)]);
        else
            disp( [header, 'FindLoci: No status bar. Frame ',num2str(i), ...
                ' of ', num2str(num_im),'.']);
        end
    end
    if CONST.show_status
        close(h);
    end
end

end

function data = loaderInternal( filename );
data = load( filename );
end




function intDoLoci( i, dirname, contents, num_im, nc, CONST)
data_c = loaderInternal([dirname,contents(i  ).name]);
for ii = 1:data_c.regs.num_regs
    for j = 1:nc
        if isfield( CONST.trackLoci, 'numSpots' ) && numel(CONST.trackLoci.numSpots)>=j
            numSpots = CONST.trackLoci.numSpots(j);
            if numSpots
                tmp              = getfield( data_c.CellA{ii}, ['fluor',num2str(j)]);
                data_c.CellA{ii} = setfield( data_c.CellA{ii}, ['locus',num2str(j)], intTrackSpots( tmp, numSpots, data_c.CellA{ii}, CONST ));
            end
        end
    end
end

dataname = [dirname,contents(i  ).name];
save(dataname,'-STRUCT','data_c');

end
