function trackOptiFindFociCyto(dirname,CONST,header)
% trackOptiFindFociCyto : Finds foci in cells. Note that this only
% runs if the number of foci to be fit is set in CONST.trackLoci.numSpots.
% It runs on the err.mat files and saves the new err.mat files with the
% found foci and cytoplasmic background.
%
% This is done by :
% (1) Fits autofluor/cytoplasmic fluor background in cells, cell-by-cell
% (2) Makes a mega region of all cells and fits foci in all cell
%     simultaneously as opposed fitting foci cell-by-cell.
%
% INPUT :
%   dirname: is the seg directory in the xy directory
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

% Get the error data file names with the region information
contents=dir([dirname,'*_err.mat']);
num_im = numel(contents);

data_c = loaderInternal([dirname,contents(1).name]);
nc = 0;
tmp_fn = fieldnames(data_c);
nf = numel(tmp_fn);

% goes through the fields in data_c and calculates the number of fluorescence channels
for j = 1:nf; 
    if numel(strfind(tmp_fn{j},'fluor')==1) && ~numel((strfind(tmp_fn{j},'fluor0')))
        nc = nc+1;
    end
end

if ~isfield( data_c, 'fluor1' ) || ~isfield( CONST.trackLoci, 'numSpots' ) ||...
        ~any(CONST.trackLoci.numSpots)
    disp ('No foci were fit. Set the constants if you want foci.');
    return;
end


if CONST.parallel.show_status
    h = waitbar( 0, 'Find Loci.');
else
    h = [];
end

for i = 1:num_im; % finding loci through every image
    intDoFoci( i, dirname, contents, nc, CONST);
    if CONST.parallel.show_status
        waitbar(i/num_im,h,['Find Loci--Frame: ',num2str(i),'/',num2str(num_im)]);
    else
        disp( [header, 'FindLoci: No status bar. Frame ',num2str(i), ...
            ' of ', num2str(num_im),'.']);
   end
end

if CONST.parallel.show_status
    close(h);
end


end

function data = loaderInternal( filename )
data = load(filename);
end

function intDoFoci( i, dirname, contents, nc, CONST)
% intDoLoci : finds the foci in image i
%
% INPUT :
%       i : time frame number
%       dirname : seg directory path in xy folder
%       contents : seg/err data files
%       nc : number of channels
%       CONST : segmentation parameters

data_c = loaderInternal([dirname,contents(i).name]);
gf  = fspecial( 'gaussian', 21, 3 );

% make filtered images to fit - looks useless
im_filt = cell([1,nc]);
Istd = zeros(1,nc);
for j = 1:nc
    fl_im = data_c.(['fluor',num2str(j)]);
    fl_im = medfilt2( double(fl_im), [3,3], 'symmetric' );
    Istd(j)  = std(fl_im(data_c.mask_bg));
    tmp = (fl_im-imfilter( fl_im, gf, 'replicate' ))/Istd(j);
    tmp(tmp<0) = 0;
    im_filt{j} = tmp;
end


% Loop through the different fluorescence channels
for channel_number = 1:nc
    if isfield( CONST.trackLoci, 'numSpots' ) && numel(CONST.trackLoci.numSpots)>=channel_number
        if CONST.trackLoci.numSpots(channel_number) 
            % only runs if non zero number of foci are set in constants
            % Fits the foci
            data_c = intFindFociPAWCurve( data_c, CONST, channel_number );
        end
    end
end

dataname = [dirname,contents(i).name];
save(dataname,'-STRUCT','data_c');

end

