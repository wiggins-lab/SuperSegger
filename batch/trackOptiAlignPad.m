function [crop_box] = trackOptiAlignPad(dirname_, workers, CONST, targetd)
% trackOptiAlignPad : aligns phase images to correct for microscope drift.
% To keep as much data as possible, instead of cropping the resulting
% images it builds a larger image that encompases all drift positions.
% It saves the alignment information in an array called crop_box and saves
% the aligned images in a directory called dirname/align.
% If the images are out of focused or have a high error they are skipped
% in alignment. Images can be aligned to any channel (fluorescence or phase)
% by setting CONST.imAlign.AlignChannel (default is 1).
%
% INPUT :
%       dirname_ : folder were .tif image files in NIS format are contained
%       workers : number of workers for parallel computation
%       CONST : segmentation constants
% OUTPUT :
%       crop_box : information about alignement
%
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


if exist( dirname_, 'dir' )

if ~exist('workers', 'var') || isempty( workers )
    workers = 0;
end

% Upsampling factor used for image alignment.
% Images will be registered to within 1/precision of a pixel
precision = 100;

if dirname_ == '.'
    dirname_ = pwd;
end
dirname_ = fixDir(dirname_);

verbose = CONST.parallel.verbose;
file_filter = '*.tif*';
contents=dir([dirname_ file_filter]);
num_im = numel( contents );

nt  = [];
nc  = [];
nxy = [];
nz  = [];

% extract name information for each image
for i = 1:num_im
    nameInfo = ReadFileName(contents(i).name);
    nt  = [nt, nameInfo.npos(1,1)];
    nc  = [nc, nameInfo.npos(2,1)];
    nxy = [nxy,nameInfo.npos(3,1)];
    nz  = [nz, nameInfo.npos(4,1)];
end

nt  = sort(unique(nt));
nc  = sort(unique(nc));
nxy = sort(unique(nxy));
nz  = sort(unique(nz));



% set the align channel. Default is 1 (bright field)
if isfield(CONST, 'imAlign') && isfield(CONST.imAlign, 'AlignChannel') && ...
        any(CONST.imAlign.AlignChannel == nc)
    nc = [CONST.imAlign.AlignChannel, ...
        nc(nc~=CONST.imAlign.AlignChannel)];
else
    CONST.imAlign.AlignChannel = 1;
    CONST.imAlign.medFilt      = false;
    CONST.imAlign.AlignToFirst = false;
end


if ~exist( 'targetd', 'var' ) || isempty( targetd )
    targetd = [dirname_,'align',filesep];
else
     targetd = fixDir(targetd);
    
end


mkdir(targetd);
num_xy = numel(nxy);

if (workers>0) && (num_xy>1)
    SHOW_FLAG = false;
else
    SHOW_FLAG = true;
    workers = 0;
end


crop_box = cell(1, num_xy);

% parallelized alignment for each xy
%for jj=1:num_xy
parfor(jj=1:num_xy, workers)
    crop_box{jj} = intFrameAlignXY( SHOW_FLAG, nt, nz, nc, nxy(jj), ...
        dirname_, targetd, nameInfo, precision, CONST);
end

end

end



function crop_box = intFrameAlignXY( SHOW_FLAG, nt, nz, nc, ...
    nnxy, dirname, targetd, nameInfo, precision, CONST)
% intFrameAlignXY : Frame alignment for one xy directory
%
% INPUT :
%       SHOW_FLAG : to display the waitbar
%       nt : array with numbers of time frames
%       nz : array with numbers of z frames
%       nc : array with numbers of channels
%       nnxy : xy directory number
%       dirname : dirname where images are at
%       targetd : align directory where aligned images are temporarily placed
%       nameInfo : name information
%       precision : images registered to within 1/precision of a pixel
%       CONST : segmentation constants
%
% OUTPUT :
%       crop_box : information about alignement
%

FOCUS_NUM_LIM = 0;
ERR_LIM = 1000000;

if SHOW_FLAG
    h = waitbar(0,'aligning frames: ');
    cleanup = onCleanup( @()( delete( h ) ) );
end

verbose = CONST.parallel.verbose;

nnt = numel( nt );
OutArray   = zeros( nnt, 2);
FocusArray = zeros( nnt, 1);

countt   = 0;
nz = sort(nz);

nnz = numel(nz);
nnz2 = ceil(nnz/2); % half of z axis
nz = [nz(nnz2), nz([1:(nnz2-1),(nnz2+1):nnz])];
initFlag = false; % sets the second image the first time through
% or if the focus or error are not within the limits

% computing the alignment values
for it = nt;
    if SHOW_FLAG
        waitbar(countt/nnt,h);
    end
    
    countt = countt+1;
    
    for iz = nz
        for ic = nc
            nameInfo.npos(:,1) = [it; ic; nnxy; iz];
            in_name =  [dirname, MakeFileName(nameInfo)];
            if verbose
                disp(['trackOptiAlignPad : Image name: ',in_name]);
            end
            im = intImRead(in_name);
            
            if (ic == nc(1)) && (iz == nnz2 | iz == -1)
                % align phase image at half the z axis
                if ~initFlag % first time through, or high error
                    phaseBef = im;
                end
                
                % applies a median filter to the phase image
                if isfield(CONST.imAlign,'medFilt') && CONST.imAlign.medFilt
                    im_     = medfilt2( im, [3,3], 'symmetric' );
                    phaseBef_ = medfilt2( phaseBef, [3,3], 'symmetric' );
                else
                    im_     = im;
                    phaseBef_ = phaseBef;
                end
                
                [out,errNum,focusNum] = intAlignIm(im_, phaseBef_, precision );
                if verbose
                    disp(['focusNum: ',num2str(focusNum),' errNum: ',num2str(errNum)]);
                end
                FOCUS_FLAG = (focusNum > FOCUS_NUM_LIM) & (errNum < ERR_LIM);
                
                if FOCUS_FLAG % focused, with low alignment error
                    initFlag = true;
                    OutArray(countt,:) = out(3:4);
                    FocusArray(countt) = true;
                end
            end
            
            %im = intShiftIm(im, out);
            im = intShiftImMod(im, out );
           
            if SHOW_FLAG
                if ic == nc(1) % phase image
                    if ic>0
                        try
                        figure(ic)
                        clf;
                        imshow( cat( 3, ag(im), ...
                            double(FOCUS_FLAG)*(0.5*ag(im)+0.5*ag(phaseBef)), ...
                            double(FOCUS_FLAG)*ag(phaseBef) ));
                        end
                    end
                else % fluorescence channel
                    backer = .8*ag(phaseBef);
                    backer0 = backer;
                    fluor  = ag(uint16(im-median(im(:))));
                    
                    figure(ic)
                    clf;
                    
                    if ~isfield (CONST.view,'fluorColor')
                        CONST.view.fluorColor = {'g','r','b'};
                    end
                    comp( {backer}, {fluor,CONST.view.fluorColor{ic-1}} );
                end
                drawnow;
            end
            
            if FOCUS_FLAG
                if ic == nc(1) && ~CONST.imAlign.AlignToFirst
                    phaseBef = im; % set the previous image to current
                end
                out_name = [targetd, MakeFileName(nameInfo)];
            else % non focused or high alignment error
                disp( ['Skipping frame: ', in_name] );
            end
        end
    end
end

% instead of cropping the image, we add a pad region outside the image.

ss = size(phaseBef);

maxy = ceil( max(-OutArray(:,1)));
maxx = ceil( max(-OutArray(:,2)));
miny = floor(min(-OutArray(:,1)));
minx = floor(min(-OutArray(:,2)));

sspad = [ss(1)+maxy-miny,ss(2)+maxx-minx];
countt   = 0;
initFlag = false;

crop_box = [OutArray,OutArray];
crop_box(:,1) = -crop_box(:,1) + 1-miny;
crop_box(:,2) = -crop_box(:,2) + 1-minx;
crop_box(:,3) = crop_box(:,1) + ss(1);
crop_box(:,4) = crop_box(:,2) + ss(2);

for it = nt;
    if SHOW_FLAG
        waitbar(countt/nnt,h);
    end
    
    countt = countt+1;
    
    for iz = nz % go through z axis
        for ic = nc % go through each channel
            nameInfo.npos(:,1) = [it; ic; nnxy; iz];
            in_name =  [dirname, MakeFileName(nameInfo)];
            if verbose
                disp(['Image name: ',in_name]);
            end
            im_ = intImRead( in_name );

            if numel(size(im_)) > 2
                disp('Images are in color - attempting to convert to monochromatic.');
                im_ = convertToMonochromatic(im_);
            end
            
            im = zeros(sspad, class(im_) ) + mean( im_(:));
            im((1-miny):(ss(1)-miny),(1-minx):(ss(2)-minx)) = im_;
            out = [0,0,OutArray(countt,:)];
            
            im = intShiftImMod(im, out + CONST.imAlign.out{ic} - ...
                CONST.imAlign.out{1});
            
            if ~initFlag % first time through, set previous image
                phaseBef = im;
            end
            
            if SHOW_FLAG
                if ic == nc(1)
                    figure(ic)
                    clf;
                    imshow(cat( 3, ag(im), ...
                        double(FOCUS_FLAG)*(0.5*ag(im)+0.5*ag(phaseBef)), ...
                        double(FOCUS_FLAG)*ag(phaseBef) ));
                else
                    backer = .8*ag(phaseBef);
                    backer0 = backer;
                    fluor  = ag(uint16(im-median(im(:))));
                    
                    figure(ic)
                    clf;
                    
                    if ~isfield (CONST.view,'fluorColor')
                        CONST.view.fluorColor = {'g','r','b'};
                    end
                    comp( {backer}, {fluor,CONST.view.fluorColor{ic-1}} );
                end
                drawnow;
                hold on;
                xxxx = [crop_box(countt,2),crop_box(countt,2),...
                    crop_box(countt,4),crop_box(countt,4),...
                    crop_box(countt,2)];
                yyyy = [crop_box(countt,1),crop_box(countt,3),...
                    crop_box(countt,3), crop_box(countt,1),...
                    crop_box(countt,1)];
                plot( xxxx,yyyy,'y');
            end
            
            if FocusArray(countt) % image focused, with low error
                % save shifted image to target directory
                out_name = [targetd, MakeFileName(nameInfo)];
                intImWrite(im, out_name );
                initFlag = true;
                
                if ic == nc(1)
                    phaseBef = im;
                end
            else
                disp(['Skipping frame: ', in_name]);
            end
        end
    end
    
end

% done shifting the frames.
if SHOW_FLAG
    close(h);
end

end
