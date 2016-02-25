%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [clist, clist_def] = trackOptiFindFociCyto(dirname,CONST,header)

% trackOptiFindFociAutoFluor : Finds foci in cells.
% This is done by :
% (1) Fits autofluor/cytoplasmic fluor background in cells, cell-by-cell
% (2) Makes a mega region of all cells and fits foci in all cell
%     simultaneously as opposed fitting foci cell-by-cell.
% INPUT :
%       dirname : seg folder
%       CONST : segmentation constants
%       header : information string
% OUTPUT :
%       clist :
%       clist_def :
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
data_c = loaderInternal([dirname  contents(1  ).name]);

nc = 0;
tmp_fn = fieldnames( data_c );
nf = numel( tmp_fn );

for j = 1:nf;
    if numel(strfind(tmp_fn{j},'fluor')==1) && ~numel((strfind(tmp_fn{j},'fluor0')))
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
    
    CONST.show_status = 0;
    %for 1:num_im
    parfor i = 1:num_im;
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

gf  = fspecial( 'gaussian', 21, 3 );
gf2 = fspecial( 'gaussian', 21, 2 );

% make filtered images to fit
im_filt = cell([1,nc]);
for j = 1:nc
    fl_im = getfield( data_c, ['fluor',num2str(j)]);
    fl_im = medfilt2( double(fl_im), [3,3], 'symmetric' );
    
    Istd(j)  = std(fl_im(data_c.mask_bg));
    tmp = (fl_im-imfilter( fl_im, gf, 'replicate' ))/Istd(j);
    tmp(tmp<0) = 0;
    im_filt{j} = tmp;
end




% Loop through the different fluo channels
for j = 1:nc
    
    if isfield( CONST.trackLoci, 'numSpots' ) && numel(CONST.trackLoci.numSpots)>=j
        numSpots = CONST.trackLoci.numSpots(j);
        
        % only run if you want non zero number of foci
        if numSpots
            
            channel_number = j;
            
            
            %% tmp debug stuff here
            for ii = 1:data_c.regs.num_regs
                fieldname = ['locus',num2str(j)];
                if isfield( data_c.CellA{ii}, fieldname )
                    data_c.CellA{ii} = rmfield( data_c.CellA{ii}, fieldname );
                end
            end
            
            
            % make a cytofluor model for cells.
            %data_c = intCytoFluorFit( data_c, CONST, channel_number );
            
            % Fit the foci here:
            data_c = intFindFociPAWCurve( data_c, CONST, channel_number );
            
        end
    end
end


dataname = [dirname,contents(i  ).name];
save(dataname,'-STRUCT','data_c');

end

function locus = intTrackSpots2(fluor, ff, backer, back_int, Istd, ...
    numLoci, celld, CONST);

opt =  optimset('MaxIter',25,'Display','off', 'TolX', 1/10);


% Does the dirty work of fitting loci
disp_flag = false;

locus = compSpotPosDevFmin4(double(fluor), double(ff), double(backer), ...
    double(back_int), double(Istd), celld.mask, numLoci,CONST,1,disp_flag,2,opt);

r=1;

%%

% correct the position of the loci with the offset of the lower corner of
% the image.
num_spot = length(locus);
for j = 1:num_spot;
    
    locus(j).r = locus(j).r + celld.r_offset-[1,1];
    
    locus(j).shortaxis = ...
        (locus(j).r-celld.coord.rcm)*celld.coord.e2;
    locus(j).longaxis = ...
        (locus(j).r-celld.coord.rcm)*celld.coord.e1;
    
end
end




