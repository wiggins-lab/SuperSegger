function trackOptiZMerge( dirname, targetname, CONST, dz )


data.mag   = 5;

if ~isfield( CONST, 'maxMerge' ) || isempty(CONST.maxMerge)
    CONST.maxMerge = false;
end

if ~exist( 'dz', 'var' ) || isempty(dz)
    dz = 0;
end

data.CONST = CONST;
data.dz = dz;


%% get the dir contents first and set up the file names
dirname     = fixDir( dirname );
targetname = fixDir( targetname );

data.dirname    = dirname;
data.targetname = targetname;


file_filter = '*.tif';
contents=dir([data.dirname file_filter]);
num_im = numel( contents );

if num_im < 1
    disp( 'No images have been found.' );
    return
end


nt  = [];
nc  = [];
nxy = [];
nz  = [];

% extract name information for each image
for i = 1:num_im
    nameInfo0 = ReadFileName(contents(i).name);
    nt  = [nt, nameInfo0.npos(1,1)];
    nc  = [nc, nameInfo0.npos(2,1)];
    nxy = [nxy,nameInfo0.npos(3,1)];
    nz  = [nz, nameInfo0.npos(4,1)];
end


data.nameInfo0 = nameInfo0;

nt  = sort(unique(nt))';
nc  = sort(unique(nc));
nxy = sort(unique(nxy));
nz  = sort(unique(nz));

data.nt  = nt';
data.nc  = nc;
data.nxy = nxy;
data.nz  = nz;

numz = numel(nz);

data.numz = numz;

if numel(nz) < 2
    disp( 'There are not at least two z positions' );
    return
end

%% make target d

if ~exist( 'targetname', 'dir' )
    mkdir( data.targetname );
end

%% Load up first images and get the size

im = intImRead( [dirname,contents(1).name] );

if numel(size(im)) > 2
    im = im(:,:,2);
end
        
% figure out the full image size
ss0 = size( im )
data.ss0 = ss0;

% fix up full image size mesh grids
[X2f,Y2f]     = meshgrid( (1:ss0(2)), (1:ss0(1)) );
[X3f,Y3f,Z3f] = meshgrid( (1:ss0(2)), (1:ss0(1)), 1:numz );

data.X2f = X2f;
data.Y2f = Y2f;

data.X3f = X3f;
data.Y3f = Y3f;
data.Z3f = Z3f;

% mask smaller gides
imr = imresize( im, 1/data.mag );

ss = size( imr );
data.ss = ss;

[X3,Y3,Z3] = meshgrid(  data.mag*(1:ss(2)), data.mag*(1:ss(1)), 1:numz );
[X2,Y2] = meshgrid( data.mag*(1:ss(2)), data.mag*(1:ss(1)) );
[X2i,Y2i] = meshgrid( data.mag*(0:ss(2)), data.mag*(0:ss(1)) );

data.X2  = X2;
data.Y2  = Y2;

data.X2i  = X2i;
data.Y2i  = Y2i;

data.X3 = X3;
data.Y3 = Y3;
data.Z3 = Z3;


% Make the filters
data.disk_fs = fspecial('disk',1);
data.g_fs    = fspecial('gaussian',14,2);

%% Do the main loop

numt = numel(nt);
data.numt = numt;

% Loop through xy's
for nnxy = nxy
    
    disp( ['XY: ',num2str( nnxy ),' / ',num2str(numel(nxy))] );
    %loop through times
    
    % parfor jj = 1:numt

    for jj = 1:numt
        
        intDoTimeStep(  nt(jj), data, nnxy )
        
    end
end
end

function intDoTimeStep( it, data, nnxy )


nameInfo_in  = data.nameInfo0;
nameInfo_out = data.nameInfo0;


ims = zeros( [data.ss0, data.numz] );

disp( ['t: ',num2str( it ),' / ',num2str(data.numt)] );


for ic = data.nc
    %% Load the z stack
    for iz = 1:data.numz
        nameInfo_in.npos(:,1) = [it; ic; nnxy; iz];
        in_name =  [data.dirname, MakeFileName(nameInfo_in)];
        
        tmp = intImRead( in_name );
        
        if numel(size(tmp)) > 2
            tmp = tmp(:,:,2);
        end
        ims(:,:,iz) = tmp;
    end
    
    if (ic == 1)||(ic == -1 )
        Z2f = makeMergeMap( ims, data );
    end
    
    if data.CONST.maxMerge && (ic ~= 1)
        im_merge = intMaxMerge( ims, datad );
    else
        im_merge = intDoMerge( ims, Z2f, data );
    end
    
    nameInfo_out.npos(4,:) = 0;
    nameInfo_out.npos(:,1) = [it; ic; nnxy; -1];
    out_name =  [data.targetname, MakeFileName(nameInfo_out)];
    
    imwrite( uint16(im_merge), out_name );
    
end

end



function Z2f = makeMergeMap( ims, data )

tmp_max = 0;

curver = zeros( [data.ss,data.numz] );

% this removes bright glass chunks from the field
mask   = false( data.ss0 );

for ii = 1:data.numz
    rad = 1;
    
    tmp = medfilt2( ims(:,:,ii), [3,3], 'symmetric' );
    
    tmp_mean = mean(tmp(:));
    
    
    tmp = ims(:,:,ii);
    
    flagger = tmp<.3*tmp_mean;
    %mask         = or( flagger,mask);
    tmp(flagger) = 0.3*tmp_mean;
    
    flagger = tmp>2.5*tmp_mean;
    mask         = or( flagger,mask);
    tmp( flagger) = 2.5*tmp_mean;
    
    tmp_max = tmp_max+tmp_mean;
    
    
    [~,~,~,~,~,~,~,tmp ] = curveFilter( tmp, rad );
    
    tmp = imresize( tmp, 1/data.mag );
    
    tmp = imfilter( tmp, data.disk_fs, 'replicate' );
    curver(:,:,ii)  = tmp;
end

mask_r = logical(imresize( double(mask), 1/data.mag ));
mask_rbw = bwmorph( bwmorph( mask_r, 'erode',2),'dilate',4);

int_min = imresize(min( ims, [], 3), 1/data.mag );

tmp_max = tmp_max/data.numz;

curver = curver/tmp_max;

%% Do max merge

[tmp,ord] = max( curver,[],3 );

ord3 = data.Z3;
for ii = 1:data.numz
    ord3(:,:,ii) = ord;
end

curver_mod = curver;

curver_mod(abs(ord3(:)-data.Z3(:))>2) = nan;


minner = min(curver_mod,[],3);
for ii = 1:data.numz
    curver_mod(:,:,ii) = curver_mod(:,:,ii) - minner;
end

Z_ = nansum(curver_mod.*data.Z3,3)./nansum(curver_mod,3);


%% Model background Z position based on length gradient

mask_min =  int_min<0.9*mean(int_min(:));

mask   = and( (tmp>0.02), mask_min );

mask   = bwmorph( mask, 'dilate', 1 );
mask   = bwmorph( mask, 'erode', 1 );

mask_e = bwmorph( mask, 'erode', 2 );
mask_o = (mask-mask_e)>0;
mask_o(mask_rbw) = false;

N = sum(mask_o(:));

Z0 = mean( Z_(mask_o));

X0  = mean( data.X2(mask_o) );
Y0  = mean( data.Y2(mask_o) );
XZ0 = mean( data.X2(mask_o).*Z_(mask_o) );
YZ0 = mean( data.Y2(mask_o).*Z_(mask_o) );
X20 = mean( data.X2(mask_o).*data.X2(mask_o) );
Y20 = mean( data.Y2(mask_o).*data.Y2(mask_o) );

mX = (XZ0-X0*Z0)/(X20-X0^2);
mY = (YZ0-Y0*Z0)/(Y20-Y0^2);
b  = Z0 - mX*X0-mY*Y0;

ZZ = b + mX*data.X2 + mY*data.Y2;




Z__ = Z_;

Z__(~mask) = ZZ(~mask);

Z__ = medfilt2( Z__, [3,3] );
Z2 = imfilter( Z__, data.g_fs, 'replicate' );

Z2 = Z2 + data.dz;

Z2(Z2>data.numz) = data.numz;
Z2(Z2<1) = 1;


% Show the position for debugging
%figure(3);
%imshow( Z2, [] );
%drawnow;


%%
Z2 = Z2([1,1:end],[1,1:end]);

Z2f = interp2( data.X2i,data.Y2i,Z2,data.X2f,data.Y2f);

end


function im_merge = intDoMerge( ims, Z2f, data )



figure(4);

im_merge = interp3( data.X3f,data.Y3f,data.Z3f,ims,data.X2f,data.Y2f,Z2f );

imshow( im_merge, [] );
drawnow;

end

function im_merge = intMaxMerge( ims )

im_merge = max( ims,[], 3);

figure(4);

imshow( im_merge, [] );
drawnow;

end
