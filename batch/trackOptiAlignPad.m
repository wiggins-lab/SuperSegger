function crop_box = trackOptiAlignPad(dirname_, CROP_FLAG, M, CONST)
% trackOptiAlignPad : aligns images to correct for microscope drift
% using the phase images. To keep as much data as possible, instead of
% cropping the resulting images it builds a larger image
% that encompases all drift positions.  It saves the alignment information
% in a file called crop_box.mat
% The aligned images are placed in a directory dirname/align.
%
% INPUT :
%       dirname_ : folder were .tif image files in NIS format are contained
%       CROP_FLAG : if 1  then cropper is : [ceil(1+maxs(1)),ceil(1+maxs(2)),...
%                   floor(ss(1)+mins(1)),floor(ss(2)+mins(2))]
%                   else it is  cropper = [1,1,ss(1),ss(2)];
%                   default is 1
%       CONST : segmentation constantsS
% OUTPUT :
%       crop_box : information about alignement
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

if ~exist('CROP_FLAG', 'var') || isempty( CROP_FLAG )
    CROP_FLAG = 1;
end

if ~exist('M', 'var') || isempty( M )
    M = 0;
end

precision = 100;

if dirname_ == '.'
    dirname_ = pwd;
end
dirname_ = fixDir(dirname_);

if ~isempty(dirname_)
    file_filter = '*.tif';
    contents=dir([dirname_ file_filter]);
    num_im = numel( contents );
    
    nt  = [];
    nc  = [];
    nxy = [];
    nz  = [];
    
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
    
    targetd = [dirname_,'align',filesep];
    mkdir(targetd);
    
    num_xy = numel(nxy);
    
    if (M>0) && (num_xy>1)
        SHOW_FLAG = false;
    else
        SHOW_FLAG = true;
        M = 0;
    end
    
    
    crop_box = cell(1, num_xy);
    
    
    parfor(jj=1:num_xy, M)
    %for jj=1:num_xy
        nnxy = nxy(jj);
        crop_box{jj} = intFrameAlignXY( CROP_FLAG, SHOW_FLAG, nt, nz, nc, nnxy, ...
            dirname_, targetd, nameInfo, precision, CONST );
    end
end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Parallelize frame alignment.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function crop_box = intFrameAlignXY( CROP_FLAG, SHOW_FLAG, nt, nz, nc, ...
    nnxy, dirname, targetd, nameInfo, precision, CONST )



%%%%%%%%%%%%%%%%%%%%%%
% FOCUS_NUM_LIM = 5;
% ERR_LIM = 0.7;
%%%%%%%%%%%%%%%
FOCUS_NUM_LIM = 0;
ERR_LIM = 1000000;

if SHOW_FLAG
    h = waitbar(0,'aligning frames: ');
end

tt = 1;

nnt = numel( nt );
outlast = [];

OutArray   = zeros( nnt, 2);
FocusArray = zeros( nnt, 1);

countt   = 0;

nz = sort(nz);


%%%
iz = 1;

nnz = numel(nz);
nnz2 = ceil(nnz/2);
nz = [nz(nnz2), nz([1:(nnz2-1),(nnz2+1):nnz])];

initFlag = false;

for it = nt;
    if SHOW_FLAG
        waitbar(countt/nnt,h);
    end
    
    countt = countt+1;
    
    for iz = nz
        for ic = nc
            
            nameInfo.npos(:,1) = [it; ic; nnxy; iz];
            in_name =  [dirname, MakeFileName(nameInfo)];
            disp(['Image name: ',in_name]);
            im = imread( in_name );
            
            
            if numel(size(im)) > 2
                disp('These images are color.');
                im = squeeze(im(:,:,1));
                
            end
            
            if (ic == nc(1)) && (iz == nnz2 | iz == -1)
                if ~initFlag
                    phaseB = im;
                end
                [out,errNum,focusNum] = intAlignIm( im, phaseB, precision );
                disp(['focusNum: ',num2str(focusNum),' errNum: ',num2str(errNum)]);
                
                FOCUS_FLAG = (focusNum > FOCUS_NUM_LIM) & (errNum < ERR_LIM);
                if FOCUS_FLAG
                    initFlag = true;
                    OutArray(countt,:) = out(3:4);
                    FocusArray(countt) = true;
                end
            end
            
            im = intShiftIm(im, out);
            
            if SHOW_FLAG
                if ic == nc(1)
                    if ic>0
                        figure(ic)
                        clf;
                        imshow( cat( 3, ag(im), ...
                            double(FOCUS_FLAG)*(0.5*ag(im)+0.5*ag(phaseB)), ...
                            double(FOCUS_FLAG)*ag(phaseB) ));
                    end
                else
                    backer = .8*ag(phaseB);
                    backer0 = backer;
                    fluor  = ag(uint16(im-median(im(:))));
                    
                    figure(ic)
                    clf;
                    if mod(ic,2) == 0
                        imshow( cat( 3, backer, backer0+fluor, backer0));
                    else
                        imshow( cat( 3, backer+fluor, backer0, backer0));
                    end
                end
                drawnow;
            end
            
            
            if FOCUS_FLAG
                if ic == nc(1)
                    phaseB = im;
                end
                
                out_name = [targetd, MakeFileName(nameInfo)];
                %imwrite(uint16(im), out_name ,'tif','Compression', 'none');
                
            else
                disp( ['Skipping frame: ', in_name] );
            end
        end
    end
    
    size( phaseB )
end

%% in the pad version we add a pad region to the outside of the image.
ss = size(phaseB);

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
    
    for iz = nz
        for ic = nc
            
            nameInfo.npos(:,1) = [it; ic; nnxy; iz];
            in_name =  [dirname, MakeFileName(nameInfo)];
            disp(['Image name: ',in_name]);
            im_ = imread( in_name );
            
            
            im = zeros( sspad, class(im_) ) + mean( im_(:) );
            im( (1-miny):(ss(1)-miny), (1-minx):(ss(2)-minx) ) = im_;
            
            
            out = [0,0,OutArray(countt,:)];
            im = intShiftIm(im, out + CONST.imAlign.out{ic} - ...
                CONST.imAlign.out{1});
            
            if ~initFlag
                phaseB = im;
            end
            
            if SHOW_FLAG
                if ic == nc(1)
                    figure(ic)
                    clf;
                    imshow( cat( 3, ag(im), ...
                        double(FOCUS_FLAG)*(0.5*ag(im)+0.5*ag(phaseB)), ...
                        double(FOCUS_FLAG)*ag(phaseB) ));
                else
                    backer = .8*ag(phaseB);
                    backer0 = backer;
                    fluor  = ag(uint16(im-median(im(:))));
                    
                    figure(ic)
                    clf;
                    if mod(ic,2) == 0
                        imshow( cat( 3, backer, backer0+fluor, backer0));
                    else
                        imshow( cat( 3, backer+fluor, backer0, backer0));
                    end
                end
                drawnow;               
                hold on;
                xxxx = [crop_box(countt,2),...
                    crop_box(countt,2),...
                    crop_box(countt,4),...
                    crop_box(countt,4),...
                    crop_box(countt,2)];
                yyyy = [crop_box(countt,1),...
                    crop_box(countt,3),...
                    crop_box(countt,3),...
                    crop_box(countt,1),...
                    crop_box(countt,1)];
                
                plot( xxxx,yyyy,'y');
            end
            
            
            if FocusArray(countt)
                out_name = [targetd, MakeFileName(nameInfo)];
                imwrite(uint16(im), out_name ,'tif','Compression', 'none');
                initFlag = true;
                
                if ic == nc(1)
                    phaseB = im;
                end
            else
                disp( ['Skipping frame: ', in_name] );
            end
        end
    end
    
end

% done shifting the frames.




if SHOW_FLAG
    close(h);
end



mins = min(-OutArray);
maxs = max(-OutArray);

ss = size(im);

if CROP_FLAG
    cropper = [ceil(1+maxs(1)),ceil(1+maxs(2)),...
        floor(ss(1)+mins(1)),floor(ss(2)+mins(2))]
else
    cropper = [1,1,ss(1),ss(2)];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if SHOW_FLAG
    h = waitbar(0,'cropping frames: ');
end

tt = 1;

countt   = 0;

for it = nt;
    if SHOW_FLAG
        waitbar(countt/nnt,h);
    end
    
    countt = countt+1;
    
    for iz = nz;
        for ic = nc;
            
            %if ic == 1
            %    nz_ = nz;
            %else
            %    nz_ = 1;
            %end
            
            %for iz = nz_;
            nameInfo.npos(:,1) = [it; ic; nnxy; iz];
            out_name = [targetd, MakeFileName(nameInfo)];
            
            if exist( out_name, 'file' );
                im = imread( out_name );
                
                %out_name = [targetd, MakeFileName(nameInfo)]
                imwrite(im(cropper(1):cropper(3),cropper(2):cropper(4)),...
                    [out_name] ,'tif','Compression', 'none');
            end
        end
        
    end
end

if SHOW_FLAG
    close(h);
end

end
