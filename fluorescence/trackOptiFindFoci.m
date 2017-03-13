function trackOptiFindFoci(dirname,CONST,header)
% trackOptiFindFoci : Finds foci in cells. Note that this only
% runs if the number of foci to be fit is set in CONST.trackLoci.numSpots.
% It runs on the err.mat files and saves the new err.mat files with the
% found foci. This is done using the curve filter to find the foci in the
% image and then by fitting gaussians and and assigning the foci
% in all cells simultaneously.
%
% INPUT :
%   dirname: is the seg directory in the xy directory
%   CONST: are the segmentation constants.
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
    h = waitbar( 0, 'Find Foci.');
    cleanup = onCleanup( @()( delete( h ) ) );
else
    h = [];
end

for i = 1:num_im; % finding loci through every image
    intDoFoci( i, dirname, contents, nc, CONST);
    if CONST.parallel.show_status
        waitbar(i/num_im,h,['Find Foci--Frame: ',num2str(i),'/',num2str(num_im)]);
    else
        disp( [header, 'FindFoci: No status bar. Frame ',num2str(i), ...
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

% Loop through the different fluorescence channels
for channel_number = 1:nc
    if isfield( CONST.trackLoci, 'numSpots' ) && numel(CONST.trackLoci.numSpots)>=channel_number
        if CONST.trackLoci.numSpots(channel_number)
            % only runs if non zero number of foci are set in constants
            % Fits the foci
            data_c = intFindFociCurve( data_c, CONST, channel_number );
        end
    end
end

dataname = [dirname,contents(i).name];
save(dataname,'-STRUCT','data_c');

end

