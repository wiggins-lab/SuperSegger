function BatchSuperSeggerOpti(dirname_,skip,clean_flag,res,SEGMENT_FLAG)
% BatchSuperSeggerOpti runs everything from start to finish,
% including alignment, building the directory structure,
%single image segmentation, error resolution, cell linking,
% fluorescence analysis, and cell files.
%
% Processes a raw data set by
% (1) Aligning and cropping time series
% (2) Organizing files into directories
%        xy points are put in their own dir's
%        phase, fluor files put in their own dir's
%        makes seg and cell directories
% (3) Segmenting the frames into cell regions
% (4) Linking the regions between time steps
% (5) finding loci and calculating fluor statistics
% (6) Putting complete cells into the cell dir.
%
% INPUT :
% dirname_ : dir containing raw tif files
% skip     : The segmentation is performed every skip files
%          : this skip is very useful for high frequency timelapse where
%          : cells would switch back and forth between one and two
%          : segments leading to errors that are difficult to resolve.
%          : This segments every skip files, then copies the segments into
%          : the intermediate frames.
% clean_flag : Set this to be true to start from scratch and reseg all the
%            : files regardless of whether any seg files exist. If this
%            : flag is false, use existing segments, if they exist and
%            : new segs if they don't yet exist.
% res      : is a string that is passed to loadConstants(Mine).m to load
%          : the right constants for processing.
%
%
% Copyright (C) 2016 Wiggins Lab
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.

% Init
if nargin < 2 || isempty( skip )
    skip = 1; % default : don't skip frames
end

if nargin < 3 || isempty( clean_flag )
    clean_flag = 0; % default : don't resegment frames if segmented.
end

if nargin < 4 || isempty( res )
    res = []; 
end

if ~exist( 'SEGMENT_FLAG', 'var' ) || isempty( SEGMENT_FLAG )
    SEGMENT_FLAG = 1;
end

if dirname_ == '.'
    dirname_ = pwd;
end

dirname_ = fixDir(dirname_);

%if you pass a res value, write over CONST values. If it isn't passed,
% use existing values, if they exist. If not, load the default values.
if isstruct(res)
    CONST = res;
else
    disp (['BSSO : Loading constants file ', res]);
    if exist('loadConstantsMine','file');
        CONST = loadConstantsMine(res);
    else
        CONST = loadConstants(res,0);
    end
end


if clean_flag && SEGMENT_FLAG
    disp ('Clean flag is set to true.')
    answer=input('Do you want to continue, Y/N [Y]:','s');
    if lower(answer) ~='y'
        disp ('Exiting BatchSuperSegger. Reset clean flag and rerun');
        return
    end
end

%% align frames
if exist( dirname_, 'dir' )    
    if exist( [dirname_,filesep,'raw_im'] ,'dir') && numel(dir ([dirname_,filesep,'raw_im',filesep,'*.tif']))
        disp('BSSO: aligned images exist');
        if exist([dirname_,filesep,'raw_im',filesep,'cropbox.mat'],'file')
            tmp = load( [dirname_,filesep,'raw_im',filesep,'cropbox.mat'] );
            crop_box_array = tmp.crop_box_array;
        else
            crop_box_array = cell(1,10000);
        end
    else 
        mkdir( [dirname_,filesep,'raw_im'] );
        if CONST.align.ALIGN_FLAG           
            Neo_Crop(dirname_);
            crop_box_array = trackOptiAlignPad( dirname_, ...
                CONST.align.CROP_FLAG, CONST.parallel_pool_num, CONST );
            movefile( [dirname_,filesep,'*.tif'], [dirname_,filesep,'raw_im'] ) % moves images to raw_im
            movefile( [dirname_,'align',filesep,'*.tif'], [dirname_,filesep]); % moves aligned back to main folder
            rmdir( [dirname_,'align'] ); % removes _align directory
        else
            crop_box_array = cell(1,10000);
        end
    end
else
    disp( ['BSSO: Can''t find directory ''',dirname_,'''. Exiting.'] );
    return
end


%% setup the dir structure for analysis.
trackOptiPD(dirname_, CONST);

save( [dirname_,'CONST.mat'],'-STRUCT', 'CONST' ); % Save the Const set you were using in your analysis
save( [dirname_,'raw_im',filesep,'cropbox.mat'], 'crop_box_array' );

%% Loop through xy directories
% Reset n values incase directories have already been made.
% setup nxy values
contents = dir([dirname_,'xy*']);

if isempty(contents)
    disp('BSSO: Did not find any data.');
else
    num_dir_tmp = numel(contents);
    nxy = [];
    num_xy = 0;
    
    for i = 1:num_dir_tmp
        if (contents(i).isdir) && (numel(contents(i).name) > 2)
            num_xy = num_xy+1;
            nxy = [nxy, str2num(contents(i).name(3:end))];
            dirname_list{i} = [dirname_,contents(i).name,filesep];
        end
    end
    %nxy
    
    % reset values for nc
    contents = dir([dirname_list{1},'fluor*']);
    num_dir_tmp = numel(contents);
    nc = 1;
    num_c = 1;
    
    for i = 1:num_dir_tmp
        if (contents(i).isdir) && (numel(contents(i).name) > numel('fluor'))
            num_c = num_c+1;
            nc = [nc, str2num(contents(i).name(numel('fluor')+1:end))+1];
        end
    end
    %nc
    
    
    %% Set up parallel loop for each xy point if more than one xy position
    % exists. If not more than one xy, we will parallelize inner loops
    if (num_xy>1) && (CONST.parallel_pool_num>0)
        MM = CONST.parallel_pool_num;
        CONST.parallel_pool_num = 0;
        SWITCH_FLAG = true;
    else
        MM=0;
        SWITCH_FLAG = false;
    end
    
    if MM
        h = [];
    else
        h = waitbar( 0, ['Data segmentation xy: 0/',num2str(num_xy)] );
    end
    
    parfor(j = 1:num_xy,MM)
        %    for j = 1:num_xy
        
        dirname_xy = dirname_list{j};
        intProcessXY( dirname_xy, skip, nc, num_c, clean_flag, CONST, SEGMENT_FLAG, crop_box_array{j} )
        
        if MM
            disp( ['BSSO: No status bar. xy ',num2str(j), ...
                ' of ', num2str(num_xy),'.']);
        else
            waitbar( j/num_xy,h,...
                ['Data segmentation xy: ',num2str(j),...
                '/',num2str(num_xy)]);
        end
        
        
    end
    if ~MM
        close(h);
    end
    
    %% Compute Consensus Images
    
    if CONST.consensus
        
        h =  waitbar(0,['Computing Consensus Images']);        
        dircons = [dirname_,'consensus',filesep];
        mkdir( dircons );       
        setHeader = 'xy' ;
        
        for ii = 1:num_xy
            
            waitbar(ii/num_xy,h) ;          
            ixy = ii ;
            
            dirname_xy = dirname_list{ii};
            dirname_cell = [dirname_xy,filesep,'cell',filesep];
            
            [imTot, imColor, imBW, imInv, kymo, kymoMask, I, jjunk, jjunk, imTot10 ] = ...
                makeConsIm( [dirname_cell], CONST, [], [], false );
            
            if ~isempty( imTot )
                imwrite( imBW,    [dircons, 'consBW_',    setHeader, '_', num2str(ixy,'%02d'), '.tif'], 'tif' );
                imwrite( imColor, [dircons, 'consColor_', setHeader, '_', num2str(ixy,'%02d'), '.tif'], 'tif' );
                imwrite( imInv,   [dircons, 'consInv_',   setHeader, '_', num2str(ixy,'%02d'), '.tif'], 'tif' );
                imwrite( imTot10,   [dircons, 'typical_',   setHeader, '_', num2str(ixy,'%02d'), '.tif'], 'tif' );
                save( [dircons, 'fits', num2str(ixy,'%02d'), '.mat'], 'I' );
            else              
                disp( ['Found no cells in ', dirname_cell, '.'] );
            end
            
        end
        close(h)
    end
end

% done!
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% intProcessXY
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function intProcessXY( dirname_xy, skip, nc, num_c, clean_flag, CONST, SEGMENT_FLAG, crop_box )
% intProcessXY : the details of running the code in parallel.
% Essentially for parallel processing to work, you have to hand each
% processor all the information it needs to process the images..

% Initialization
file_filter = '*.tif';

% get header to show xy position
tmp1 = strfind( dirname_xy, 'xy');
tmp2 = strfind( dirname_xy,[filesep]);
if ~isempty(tmp1) && ~isempty(tmp2)
    header = [dirname_xy(tmp1(end):(tmp2(end)-1)),': '];
else
    header = [dirname_xy];
end

% reset nz values
contents=dir([dirname_xy,'phase',filesep,file_filter]);
num_im = numel(contents);

nz = [];
nt = [];

for i = 1:num_im;
    nameInfo = ReadFileName( contents(i).name );   
    nt = [nt, nameInfo.npos(1,1)];
    nz = [nz, nameInfo.npos(4,1)];
end

nt = sort(unique(nt));
nz = sort(unique(nz));

num_t = numel(nt);
num_z = numel(nz);

if  isempty(nz) || nz(1)==-1
    nz = 1;
end



%% Do segmentation
disp([header 'BSSO: Segmentation starts...']);

if (CONST.parallel_pool_num>0)
    MM = CONST.parallel_pool_num; % number of workers
    SWITCH_FLAG = true;
else
    MM=0;
    SWITCH_FLAG = false;
end

if ~CONST.show_status
    h = [];
else
    h = waitbar( 0, ['BSSO: Frame 0/',num2str(num_t)] );
end

stamp_name = [dirname_xy,'seg',filesep,'.doSeg.mat'];
if clean_flag
    delete(stamp_name)
end


if SEGMENT_FLAG && ~exist( stamp_name, 'file' ) 
    parfor(i=1:num_t,MM) % through all frames
        if isempty( crop_box )
            crop_box_tmp = [];
        else
            crop_box_tmp = crop_box(i,:);
        end
        
        doSeg(i, nameInfo, nc, nz, nt, num_z, num_c, dirname_xy, ...
            clean_flag, skip, CONST, [header,'t',num2str(i),': '], crop_box_tmp );
        
        if ~CONST.show_status
            disp( [header, 'BSSO: Segment. Frame ',num2str(i), ...
                ' of ', num2str(num_t),'.']);
        else
            waitbar( i/num_t, h,...
                ['Data segmentation t: ',num2str(i),'/',num2str(num_t)]);
        end
    end
    if CONST.show_status
        close(h);
    end
    time_stamp = clock;
    save( stamp_name, 'time_stamp'); % saves that xydir was full segmented
end


%% Link the cells
trackOpti(dirname_xy, skip, CONST, clean_flag, header );

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% doSeg
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function  [err_flag] = doSeg(i, nameInfo, nc, nz, nt, num_z, num_c, ...
    dirname_xy, clean_flag, skip, CONST, header, crop_box)
% doSeg : Segments and saves data in the seg.mat files in the seg/ directory.
% If the seg files are already found it does not repeat the segmentation.
% It calls the segmentation function found in CONST.seg.segFun to achieve
% this. 
% Note that these images are not ideally segmented because they do not use
% any temporal information, i.e. what came before or after, to optimize the 
% segment choices; this comes next

% It uses a local minimum filter (similar to a median filter) to enhance 
% contrast and then uses Matlab's WATERSHED command to generate cell
% boundaries. The spurious boundaries (e.g. those that lie in the cell 
% interiors) are removed by an intensity thresholding routine on each 
% boundary. Any real boundaries incorrectly removed by this thresholding 
% are added back by an iterative algorithm that uses knowledge of 
% cell shape (set by the RES value passed in the Constants file) to 
% determine which regions are missing boundaries. There is a lot of stuff
% going on under the hood here, but you?ll rarely have to adjust anything 
% in this code. 

% After it segments the data it copies the fluor fields into the data 
% structure and save this structure in the seg directory.




% Init
data = [];

% make the segment file name and check if it already exists
nameInfo_tmp = nameInfo;
nameInfo_tmp.npos([2,4],:) = 0;
nameInfo_tmp.npos(1,1) = nt(i);
name = MakeFileName( nameInfo_tmp );
nameInfo_tmp = ReadFileName(name);
name = name( 1:max(nameInfo_tmp.npos(:,3))); % has format imagename-tXX

data.basename = name;
dataname=[dirname_xy,'seg',filesep,name,'_seg.mat'];

if ~exist(dataname,'file') || clean_flag 
    nameInfo_tmp = nameInfo;
    nameInfo_tmp.npos(1,1) = nt(i);
    nameInfo_tmp.npos(4,1) = 1;
    name = MakeFileName(nameInfo_tmp);
    namePhase = [dirname_xy,'phase',filesep,name];    
    phase = imread( namePhase );
    
    if num_z > 1
        phaseCat = zeros( [size(phase), num_z], 'uint16' );
        phaseCat(:,:,1) = phase;
        
        for iz = 2:num_z
            nameInfo_tmp.npos(4,1) = iz;
            name  = MakeFileName(nameInfo_tmp);
            phaseCat(:,:,iz) =  imread( [dirname_xy,'phase',filesep,name] );
        end
        
        phase = mean( phaseCat, 3);
        
    end
    
    if ~mod(i-1,skip)
        
        % do the segmentation here
        [data, err_flag] = CONST.seg.segFun( phase, CONST, header, dataname, crop_box );
        if ~isempty( crop_box )
            data.crop_box = crop_box;
        end
        
        % Copy fluor data into data structure 
        nameInfo_tmp = nameInfo;
        for k = 2:num_c
            nameInfo_tmp.npos(1,1) = nt(i);
            nameInfo_tmp.npos(2,1) = nc(k);
            nameInfo_tmp.npos(4,1) = 1;
            name = MakeFileName( nameInfo_tmp );
            fluor_tmp = imread( [dirname_xy,'fluor',num2str(nc(k)-1),filesep,name] );         
            data = setfield( data, ['fluor',num2str(nc(k)-1)],fluor_tmp );            
        end
                
        save(dataname,'-STRUCT','data'); % Save data structure into the seg file.
    end
else
    disp([dataname, ' already exists.']);
end

err_flag = false;
end
