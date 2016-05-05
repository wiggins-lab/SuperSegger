function [data, CONST, touch_list] = segsManage( data, CONST, frame_num )

figure(1);
clf;

touch_list = [];
z_flag = false;

% Get A and E from starting constants
A = CONST.superSeggerOpti.A;
E = CONST.regionScoreFun.E;


dir_flag  = 0;
varType   = class(data);

if strcmp( varType, 'char' )
    dir_flag = 1;
    dirname = data;
    dirseperator = filesep;
    
    if dirname(length(dirname))~=dirseperator
        dirname=[dirname,dirseperator];
    end
    
    contents=dir([dirname '*_seg.mat']);
    num_im = length(contents);
    
    if (nargin < 4) || isempty( frame_num );
        i = 1;
    else
        i = frame_num;
    end
    
    if i<1
        i = 1;
    elseif i> num_im
        i = num_im;
    end
    
    data = loaderInternal([dirname,contents(i  ).name]);
end


im_flag = 1;
S_flag  = 0;
runFlag = 1;
t_flag  = 0;
Sj_flag = false;

sv = size(data.segs.info);
data = intUpdateData( data, A, E, CONST );
imshow(data.phase,'Border','tight');

while runFlag
    ss = size( data.segs.phaseMagic );
    
    figure(1);
    
    FLAGS.t_flag  = t_flag;
    FLAGS.S_flag  = S_flag;
    FLAGS.im_flag = im_flag;
    FLAGS.Sj_flag  = Sj_flag;
    
    showSegRule( data, FLAGS);
    hold on;
    
    disp('q to quit              k to keyboard' );
    disp('[] to modify           K to kill regions and segs' );
    disp('A to turn off small A  h to reset regs info');
    disp('j auto score regs      m to go into magic view');
    disp('o opti seg rule        p to go into phase view');
    disp('O opti seg rule dir    Z opti reg rule');
    disp('  R-random remove r-greedy remove a-random add');
    disp('t toggle reg/seg num   R make region opti files');
    disp('S toggle score flag    z toggle region opti files');
    disp('s segment view         e execute regionOpti');
    disp('r region view          c clf');
    disp('I toggle seg include   i info');
    
    if dir_flag
        disp(['Frames: ',num2str(i),' in [1...',num2str(num_im),']']);
    end
    c = input(': ','s')
    
    
    if isempty(c)
        
        goflag = true;
        
        while goflag
            
            figure(1);
            x = floor(ginput(1));
            
            if ~isempty( x )
                tmp = zeros([51,51]);
                
                if isempty(x)
                    continue;
                end
                
                tmp(26,26) = 1;
                
                %tmp(x(2),x(1)) = 1;
                tmp = 8000-double(bwdist(tmp));
                
                
                x
                ss
                rmin = max([1,x(2)-25])
                rmax = min([ss(1),x(2)+25])
                
                cmin = max([1,x(1)-25])
                cmax = min([ss(2),x(1)+25])
                
                rrind = rmin:rmax;
                ccind = cmin:cmax;
                
                ss__ = [numel(rrind),numel(ccind)]
                
                
                if im_flag == 1
                    
                    tmp = tmp(26-x(2)+rrind,26-x(1)+ccind).*(data.segs.segs_good(rrind,ccind) +data.segs.segs_bad(rrind,ccind));
                    [~,ind] = max( tmp(:) );
                    
                    [sub1, sub2] = ind2sub( ss__, ind );
                    
                    ii = data.segs.segs_label(sub1-1+rmin,sub2-1+cmin);
                    
                    plot( sub2-1+cmin, sub1-1+rmin, 'm.' );
                    
                    [xx,yy] = getBB( data.segs.props(ii).BoundingBox );
                    
                    old_good_map = ismember(data.regs.regs_label, find(data.regs.score));
                    
                    
                    if data.segs.score(ii)
                        data.segs.score(ii) = 0;
                        
                        data.segs.segs_good(yy,xx) ...
                            = double(~~(data.segs.segs_good(yy,xx)...
                            - double(data.segs.segs_label(yy,xx)==ii)));
                        
                        data.segs.segs_bad(yy,xx) = ...
                            double(~~(data.segs.segs_bad(yy,xx)...
                            +double(data.segs.segs_label(yy,xx)==ii)));
                    else
                        data.segs.score(ii) = 1;
                        
                        data.segs.segs_good(yy,xx) = ...
                            double(~~(data.segs.segs_good(yy,xx)+...
                            double(data.segs.segs_label(yy,xx)==ii)));
                        
                        data.segs.segs_bad(yy,xx) = ...
                            double(~~(data.segs.segs_bad(yy,xx)-...
                            double(data.segs.segs_label(yy,xx)==ii)));
                    end
                    
                    data.mask_cell   = double((data.mask_bg - data.segs.segs_good - data.segs.segs_3n)>0);
                    data = intMakeRegs( data, [], CONST );
                    data = intUpdateData( data, A, E ,CONST);
                    
                    for hh = 1: data.regs.num_regs
                        [xx,yy] = getBBpad( data.regs.props(hh).BoundingBox, ss, 1);
                        tmp_old_good  = old_good_map(yy,xx);
                        tmp_cell_mask = (hh==data.regs.regs_label(yy,xx));
                        data.regs.score(hh) = any( tmp_old_good(tmp_cell_mask));
                    end
                    
                    if dir_flag
                        touch_list = [touch_list, i];
                    end
                elseif im_flag == 2
                    tmp = tmp(26-x(2)+rrind,26-x(1)+ccind).*data.mask_cell(rrind,ccind);
                    try
                        [~,ind] = max( tmp(:) );
                    catch ME
                        printError(ME);
                    end
                    
                    [sub1, sub2] = ind2sub( ss__, ind );
                    ii = data.regs.regs_label(sub1-1+rmin,sub2-1+cmin);
                    plot( sub2-1+cmin, sub1-1+rmin, 'g.' );
                    
                    if ii
                        data.regs.score(ii) = ~data.regs.score(ii);
                    end
                end
                
            else
                goflag = false;
            end
        end
        
    elseif c(1) == 'e'
        data = regionOpti(data,0,CONST);
        data = intMakeRegs( data, [], CONST );
        data = intUpdateData( data, A, E ,CONST);
        
    elseif c(1) == 'q'
        runFlag = 0  ;
        
    elseif c(1) == 'I' % toggle seg include
        if im_flag == 1
            goflag = true;
            
            while goflag
                figure(1);
                x = floor(ginput(1));
                
                if ~isempty( x )
                    tmp = zeros(ss);
                    
                    if isempty(x)
                        continue;
                    end
                    
                    tmp(x(2),x(1)) = 1;
                    tmp = 8000-double(bwdist(tmp));
                    
                    %imshow( tmp, [] );
                    tmp = tmp.*(data.segs.segs_good+data.segs.segs_bad);
                    [~,ind] = max( tmp(:) );
                    
                    [sub1, sub2] = ind2sub( ss, ind );
                    
                    ii = data.segs.segs_label(sub1,sub2);
                    
                    plot( sub2, sub1, 'r.' );
                    
                    if ii
                        data.segs.Include(ii) = ~data.segs.Include(ii);
                    end
                else
                    goflag = false;
                end
                
            end
        end
        
    elseif c(1) == 'h'
        if dir_flag
            intResetInfoDir( dirname, CONST );
        end
        
        data = intResetInfo(data, CONST);
        
        
    elseif c(1) == 'o' % opti seg rule : finds new A that minimizes 
        % score function for specific data loaded.
        
        A = segsTrainML(data.segs.score,data.segs.info,A);
        data = intUpdateData( data, A, E );
        
    elseif c(1) == 'i'
        
        figure(1);
        x = floor(ginput(1));
        
        tmp = zeros(ss);
        
        if isempty(x)
            continue;
        end
        
        tmp(x(2),x(1)) = 1;
        tmp = 8000-double(bwdist(tmp));
        
        if im_flag == 1
            tmp = tmp.*(data.segs.segs_good+data.segs.segs_bad);
            [~,ind] = max( tmp(:) );
            
            [sub1, sub2] = ind2sub( ss, ind );
            
            ii = data.segs.segs_label(sub1,sub2);
            
            
        elseif im_flag == 2
            tmp = tmp.*double(data.regs.regs_label>0);
            [~,ind] = max( tmp(:) );
            
            [sub1, sub2] = ind2sub( ss, ind );
            
            ii = data.regs.regs_label(sub1,sub2);
            
            names = CONST.regionScoreFun.names();
            
            for jj = 1:CONST.regionScoreFun.NUM_INFO
                
                disp( [names{jj},num2str(data.regs.info(ii,jj)),...
                    ', ', num2str(mean(data.regs.info(:,jj))), ' +/- ',...
                    num2str(std(data.regs.info(:,jj)))] );
            end
            
            
        end
        plot( sub2, sub1, 'r.' );
        
    elseif c(1) == 'O' % optimizes A for scoring segs for the whole directory
        
        data_tmp = intCollectDataSegs( dirname );
        
        info  = data_tmp.segs.info(...
            and(~isnan(data_tmp.segs.score),data_tmp.segs.Include),:);
        score = data_tmp.segs.score(...
            and(~isnan(data_tmp.segs.score),data_tmp.segs.Include));
        
        num_im_tmp = data_tmp.segs.num_im(...
            and(~isnan(data_tmp.segs.score),data_tmp.segs.Include));
        
        num_seg_tmp = data_tmp.segs.num_seg(...
            and(~isnan(data_tmp.segs.score),data_tmp.segs.Include));
        
        for ii = 1:1000;
            A = segsTrainMLmatrixRnd( score, info, A, ...
                num_im_tmp, num_seg_tmp, c );
            
            figure(2);
            kkey = get(gcf,'CurrentKey');
            
            if strcmp( kkey, 'q')
                break
            end
            figure(1);
        end
        
        data = intUpdateData( data, A, E );
        
    elseif c(1) == 'S'
        
        S_flag = ~S_flag;
        
        if numel(c) > 1 && c(2)=='j'
            Sj_flag = true;
        else
            Sj_flag = false;
        end
        
    elseif c(1) == 's'
        
        im_flag = 1;
        
    elseif c(1) == 'r'
        
        im_flag = 2;
    elseif c(1) == 'A'
        
        AREA_LIM = 15;
        
        if isfield( data, 'regs' );
            num_regs = data.regs.num_regs;
            for ii = 1:num_regs
                if data.regs.props(ii).Area < AREA_LIM
                    data.regs.score(ii) = 0;
                end
                
            end
        end
        
    elseif c(1) == 'j'
        
        if isfield( data, 'regs' );
            data.regs.score = (data.regs.scoreRaw>0);
        end
        
        ind = unique([data.regs.regs_label(1,:),data.regs.regs_label(end,:),...
            data.regs.regs_label(:,1)',data.regs.regs_label(:,end)']);
        ind = ind(logical(ind));
        
        data.regs.score(ind) = 0;
        
        
    elseif c(1) == 't';
        t_flag = ~t_flag;
        
    elseif c(1) == 'm'
        
        im_flag = 3;
    elseif c(1) == 'k';
        keyboard;
        
    elseif c(1) == 'K';
        disp('Select region to kill');
        
        xy = ginput(2);
        
        if numel(xy)==4
            
            xy = floor(xy);
            xmin = min(xy(:,1));
            xmax = max(xy(:,1));
            
            ymin = min(xy(:,2));
            ymax = max(xy(:,2));
            
            xx = xmin:xmax;
            yy = ymin:ymax;
            
            plot( [xmin,xmax],[ymin,ymax] ,'r.');
            
            ind_segs = unique( data.segs.segs_label(yy,xx));
            ind_segs = ind_segs(logical(ind_segs));
            ind_segs = reshape(ind_segs,1,numel(ind_segs));
            
            if isfield( data, 'regs' );
                ind_regs = unique( data.regs.regs_label(yy,xx));
                ind_regs = ind_regs(logical(ind_regs))
                ind_regs = reshape(ind_regs,1,numel(ind_regs));
                data = rmfield(data,'regs');
            end
            mask = false(size(data.phase));
            
            for ii = ind_segs
                data.segs.info(ii,:)   = NaN;
                data.segs.score(ii)    = NaN;
                data.segs.scoreRaw(ii) = NaN;
                
                mask = logical(mask + (data.segs.segs_label==ii));
            end
            
            
            data.segs.segs_good(yy,xx)  = 0;
            data.segs.segs_bad(yy,xx)   = 0;
            data.segs.segs_3n(yy,xx)    = 0;
            data.segs.segs_label(yy,xx) = 0;
            data.mask_cell(yy,xx)       = 0;
            data.mask_bg(yy,xx)         = 0;
            
            data.segs.segs_good(mask)  = 0;
            data.segs.segs_bad(mask)   = 0;
            data.segs.segs_3n(mask)    = 0;
            data.segs.segs_label(mask) = 0;
            data.mask_cell(mask)       = 0;
            data.mask_bg(mask)         = 0;
            
            data = intUpdateData(data, A, E, CONST);
        end
        
    elseif c(1) == 'p'
        
        im_flag = 4;
        
    elseif c(1) == 'R' % make region opti files, makes bad regions
        
        delete( [dirname,'*_mod.mat'] );
        num = str2num( c(2:end) );
        if isempty(num)
            num = 1;
        end
        
        intMakeRegOpti( dirname, E, num, CONST );
        
    elseif c(1) == 'Z' % opti reg rule
        
        data_tmp = intCollectDataRegs( dirname, E );
        num_im_tmp = [];
        num_seg_tmp = [];
        
        for ii = 1:1000;
            E = regsTrainMLmatrixRnd( ...
                data_tmp.regs.score(~data_tmp.regs.boun),...
                data_tmp.regs.info(~data_tmp.regs.boun,:),...
                E, CONST, ...
                num_im_tmp, num_seg_tmp, c );
            
            figure(2);
            kkey = get(gcf,'CurrentKey');
            
            if strcmp( kkey, 'q')
                break
            end
            figure(1);
        end
        
        data = intUpdateData( data, A, E, CONST );
        
    elseif c(1) == 'z' % toggle region opti files
        z_flag = ~z_flag;
        
        if dir_flag
            
            if z_flag
                contents=dir([dirname '*_mod.mat']);
            else
                contents=dir([dirname '*_seg.mat']);
            end
            
            num_im = numel(contents);
            
            if i<1
                i = 1;
            elseif i> num_im
                i = num_im;
            end
            
            data = loaderInternal([dirname,contents(i  ).name]);
            data.mask_cell   = double((data.mask_bg - ...
                data.segs.segs_good - data.segs.segs_3n)>0);
            data = intUpdateData( data, A, E, CONST );
        end
        
    elseif c(1) == 'c'
        clf;
        imshow( data.phase, [] );
    elseif any(c(1)=='0123456789')
        if dir_flag
            i = str2num(c);
            if i<1
                i = 1;
            elseif i> num_im
                i = num_im;
            end
            
            data = loaderInternal([dirname,contents(i  ).name]);
            data.mask_cell   = double((data.mask_bg - ...
                data.segs.segs_good - data.segs.segs_3n)>0);
            data = intUpdateData( data, A, E, CONST );
        end
    end
    
    if dir_flag
        try
            dataname=[dirname,contents(i).name];
            save(dataname,'-STRUCT','data');
        catch ME
            printError(ME);
            'error saving data'
        end
    end
end

data.segs.scoreRaw = segmentScoreFun(data.segs.info,A);
touch_list = unique(touch_list);
CONST.superSeggerOpti.A = A;
CONST.regionScoreFun.E  = E;


end



function data = loaderInternal( filename )
% loads a _seg file and populates Include and num_segs fields if empty.
data = load( filename );
data.segs.segs_good   = double(data.segs.segs_label>0).*double(~data.mask_cell);
data.segs.segs_bad   = double(data.segs.segs_label>0).*data.mask_cell;

if ~isfield( data.segs, 'Include' )    
    data.segs.num_segs = max(data.segs.segs_label(:));
    data.segs.Include = true(data.segs.num_segs, 1);
end

end


function intResetInfoDir( dirname, CONST )

contents = dir([dirname '*_seg.mat']);
num_im   = length(contents);

for i = 1:num_im
    dataname = [dirname,contents(i  ).name];   
    data = loaderInternal( dataname );
    data = intResetInfo( data, CONST );
    save(dataname,'-STRUCT','data');
end
end

function data = intResetInfo( data, CONST )
ss = size( data.phase );

if ~isfield( data, 'regs' );
    data.mask_cell   = double((data.mask_bg - data.segs.segs_good - data.segs.segs_3n)>0);
    data = intMakeRegs( data, [], CONST );
end

if isfield( data.regs, 'info' );
    data.regs = rmfield(data.regs,'info');
end


for ii = 1:data.regs.num_regs
    [xx,yy] = getBBpad( data.regs.props(ii).BoundingBox, ss, 1);
    mask = data.regs.regs_label(yy,xx)==ii;
    
    if ii == 1;
        tmp = CONST.regionScoreFun.props( mask, ...
            data.regs.props(ii) );
        data.regs.info = zeros(data.regs.num_regs , numel(tmp));
        data.regs.boun = zeros(data.regs.num_regs ,1 );
    end
    try
        data.regs.info(ii,:) = CONST.regionScoreFun.props( mask, ...
            data.regs.props(ii) );
        data.regs.boun(ii) = any( [1==xx(1),1==yy(1),ss(1)==yy(end),ss(2)==xx(end)] );
    catch ME
        printError(ME);
    end
end


end


function data_tmp = intCollectDataSegs( dirname )
% go through all the _seg files in the seg folder and import information 
% about the segments in a data_tmp data structure 

contents = dir([dirname '*_seg.mat']);
num_im = length(contents);
data_tmp = [];
data_tmp.segs.info    = [];
data_tmp.segs.num_im  = [];
data_tmp.segs.num_seg = [];
data_tmp.segs.score   = [];
data_tmp.segs.Include = [];

for i = 1:num_im
    data = loaderInternal([ dirname,contents(i).name]);
    data_tmp.segs.info  = [data_tmp.segs.info; data.segs.info];
    if isfield(data.segs,'Include')
        data_tmp.segs.Include = [data_tmp.segs.Include;data.segs.Include];
    end
    data_tmp.segs.num_im = [data_tmp.segs.num_im;  0*data.segs.score+i];
    data_tmp.segs.num_seg = [data_tmp.segs.num_seg; (1:numel(data.segs.score))'];
    data_tmp.segs.score = [data_tmp.segs.score; data.segs.score ];
end
end


function data_tmp = intCollectDataRegs( dirname, E )

contents = dir([dirname '*_mod.mat']);

if numel(contents)==0
    intMakeRegOpti( dirname, E );
    contents = dir([dirname '*_seg_mod.mat']);
end

num_im   = length(contents);

data_tmp = [];
data_tmp.regs.info  = [];
data_tmp.regs.score = [];
data_tmp.regs.boun = [];
data_tmp.regs.record = [];

h = waitbar( 0, 'Load reg files' );
for i = 1:num_im
    waitbar( (i-1)/num_im, h );
    data = loaderInternal([dirname,contents(i  ).name]);
    data_tmp.regs.info    = [ data_tmp.regs.info;  data.regs.info  ];
    data_tmp.regs.score   = [ data_tmp.regs.score; data.regs.score ];
    data_tmp.regs.boun   = [ data_tmp.regs.boun; data.regs.boun ];
    data_tmp.regs.record  = [data_tmp.regs.record; [i*ones(numel(data.regs.score),1), ...
        (1:numel(data.regs.score))']];
    
end
close(h);

end


function intMakeRegOpti( dirname, E, num, CONST );

contents=dir([dirname '*_seg.mat']);
num_im = length(contents);

h = waitbar( 0, 'Make region opti files' );
for i = 1:num_im
    waitbar(i/num_im,h);
    data = loaderInternal([dirname,contents(i  ).name]);
    
    for j = 1:num
        data_ = intModRegions( data, E, CONST );        
        dataname=[dirname,contents(i).name(1:end-4),'_',...
            sprintf('%02d',j),'_mod.mat'];
        save(dataname,'-STRUCT','data_');
    end
end
close(h);
end


function data = intModRegions( data, E, CONST )

% fraction of segments toggled for training reg rule
FRACTION_SEG_MOD = 0.2;

ss = size( data.mask_cell );

num_segs = numel(data.segs.score);
num_mod  = ceil( num_segs*FRACTION_SEG_MOD );

mod_list = unique(ceil(rand(1,num_mod)*num_segs));

mod_map = logical(data.mask_cell)*0;

% make bad regs
try
    ind_bad_regs = find( ~data.regs.score );
    ind_bad_regs = reshape(ind_bad_regs, 1, numel(ind_bad_regs));
    mask_bad_regs = false(size(data.phase));
catch
    keyboard;
end
for ii = ind_bad_regs
    [xx,yy] = getBB( data.regs.props(ii).BoundingBox );
    mask_bad_regs(yy,xx) = logical( mask_bad_regs(yy,xx) + (data.regs.regs_label(yy,xx)==ii) );
end

if ~ isempty( mod_list )
    for ii = mod_list
        [xx,yy] = getBB( data.segs.props(ii).BoundingBox );
        if ~isnan(data.segs.score(ii))
            if data.segs.score(ii)
                data.segs.score(ii) = 0;
                
                data.segs.segs_good(yy,xx) ...
                    = double(~~(data.segs.segs_good(yy,xx)...
                    - double(data.segs.segs_label(yy,xx)==ii)));
                
                data.segs.segs_bad(yy,xx) = ...
                    double(~~(data.segs.segs_bad(yy,xx)...
                    +double(data.segs.segs_label(yy,xx)==ii)));
            else
                data.segs.score(ii) = 1;
                
                data.segs.segs_good(yy,xx) = ...
                    double(~~(data.segs.segs_good(yy,xx)+...
                    double(data.segs.segs_label(yy,xx)==ii)));
                
                data.segs.segs_bad(yy,xx) = ...
                    double(~~(data.segs.segs_bad(yy,xx)-...
                    double(data.segs.segs_label(yy,xx)==ii)));
            end
            mod_map(yy,xx) = (data.segs.segs_label(yy,xx)==ii);
        end
    end
    
end
data.mask_cell = double((data.mask_bg - data.segs.segs_good - data.segs.segs_3n)>0);
sqr3           = strel( 'square', 3 );
mod_map        = imdilate( mod_map, sqr3 );
data           = intMakeRegs( data, mask_bad_regs, CONST );

mod_segs       = unique( data.regs.regs_label( logical(mod_map) ) );
mod_segs       = mod_segs(logical(mod_segs));

data.regs.score(mod_segs) = 0;

end


function intShowRegs( data )

backer = 0.8*ag(data.phase);

num_regs = data.regs.num_regs;
regs_good = 0*data.mask_cell;
regs_bad  = 0*data.mask_cell;

for ii = 1:num_regs
    [xx,yy] = getBB( data.regs.props(ii).BoundingBox );
    
    if data.regs.score(ii)
        regs_good(yy,xx) = regs_good(yy,xx) + (ii==data.regs.regs_label(yy,xx));
    else
        regs_bad(yy,xx)  = regs_bad(yy,xx)  + (ii==data.regs.regs_label(yy,xx));
    end
end

imshow( cat(3,...
    backer+0.3*ag(regs_bad), ...
    backer, ...
    backer+0.3*ag(regs_good)), 'InitialMagnification', 'fit');

end

function data = intMakeRegs( data, mask_bad_regs, CONST )


ss = size( data.mask_cell );

NUM_INFO = CONST.regionScoreFun.NUM_INFO;

data.regs.regs_label = bwlabel( data.mask_cell );
data.regs.num_regs   = max( data.regs.regs_label(:) );
data.regs.props      = regionprops( data.regs.regs_label, 'BoundingBox','Orientation','Centroid','Area');
data.regs.score      = ones( data.regs.num_regs, 1 );
data.regs.info       = zeros( data.regs.num_regs, NUM_INFO );
data.regs.boun      = zeros( data.regs.num_regs, 1 );

for ii = 1:data.regs.num_regs
    
    [xx,yy] = getBBpad( data.regs.props(ii).BoundingBox, ss, 1);
    
    mask = data.regs.regs_label(yy,xx)==ii;
    
    if ii == 1;
        tmp = CONST.regionScoreFun.props( mask, data.regs.props(ii) );
        data.regs.info = zeros(data.regs.num_regs , numel(tmp));
    end
    
    data.regs.info(ii,:) = CONST.regionScoreFun.props( mask, data.regs.props(ii) );
    data.regs.boun(ii) = any( [1==xx(1),1==yy(1),ss(1)==yy(end),ss(2)==xx(end)] );
    
    
    if exist( 'mask_bad_regs', 'var' ) && ~isempty( mask_bad_regs )
        mask_ = mask_bad_regs(yy,xx);
        
        if any( mask(mask_) )
            data.regs.score(ii) = 0;
        end
    end
    
end


end


function data = intUpdateData( data, A, E, CONST )
% recalculates region score and segment score with given A and E
% coefficients

data.segs.scoreRaw = segmentScoreFun( data.segs.info, A );

if ~isfield( data, 'regs' );
    data = intMakeRegs( data, [], CONST );
end

try
    data.regs.scoreRaw = CONST.regionScoreFun.fun( data.regs.info, E );
end

end