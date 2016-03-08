function makeBadRegions( dirname,E, CONST)
%MAKEBADREGIONS makes bad regions to train the software on region shape 

contents=dir([dirname '*_seg.mat']);
num_im = length(contents);

h = waitbar( 0, 'Creating bad region examples' );
for i = 1 : num_im % go through all the images
    waitbar(i/num_im,h);
    dataname = [dirname,contents(i).name]
    data = load(dataname);

    % if there are no regions it makes regions from the segments
    if ~isfield( data, 'regs' );
        data = intMakeRegs( data, [], CONST ,E);
    end
    save(dataname,'-STRUCT','data');
    
    data_ = intModRegions( data, E, CONST );        
    datamodname=[dirname,contents(i).name(1:end-4),'_',...
            sprintf('%02d',j),'_mod.mat'];
    save(datamodname,'-STRUCT','data_');

end
close(h);
end


function [data] = intModRegions ( data, E, CONST )
% intModRegions ; modifies regions to create bad regions

% fraction of segments to be modified to create bad regions 
FRACTION_SEG_MOD = 0.2;
num_segs = numel(data.segs.score);
num_mod  = ceil( num_segs*FRACTION_SEG_MOD );
mod_list = unique(ceil(rand(1,num_mod)*num_segs));
mod_map = logical(data.mask_cell)*0;

% find the indices of bad regs
try
    ind_bad_regs = find( data.regs.score == 0 ); % find bad scores
    ind_bad_regs = reshape(ind_bad_regs, 1, numel(ind_bad_regs));
    mask_bad_regs = false(size(data.phase));
catch ME
    printError(ME);
end

for ii = ind_bad_regs % go through the bad regions and create a mask
    [xx,yy] = getBB( data.regs.props(ii).BoundingBox );
    mask_bad_regs(yy,xx) = logical( mask_bad_regs(yy,xx) + (data.regs.regs_label(yy,xx)==ii) );
end

if ~ isempty( mod_list )
    for ii = mod_list % segments to be modified
        [xx,yy] = getBB( data.segs.props(ii).BoundingBox );
        if ~isnan(data.segs.score(ii))
            if data.segs.score(ii) % score of the segment is 1
                data.segs.score(ii) = 0;                
                data.segs.segs_good(yy,xx) ...
                    = double(~~(data.segs.segs_good(yy,xx)...
                    - double(data.segs.segs_label(yy,xx)==ii)));               
                data.segs.segs_bad(yy,xx) = ...
                    double(~~(data.segs.segs_bad(yy,xx)...
                    +double(data.segs.segs_label(yy,xx)==ii)));
            else % score of the segment is 0
                data.segs.score(ii) = 1;              
                data.segs.segs_good(yy,xx) = ...
                    double(~~(data.segs.segs_good(yy,xx)+...
                    double(data.segs.segs_label(yy,xx)==ii)));                
                data.segs.segs_bad(yy,xx) = ...
                    double(~~(data.segs.segs_bad(yy,xx)-...
                    double(data.segs.segs_label(yy,xx)==ii)));
            end
            % image of modified segments
            mod_map(yy,xx) = (data.segs.segs_label(yy,xx)==ii);
        end
    end
    
end

% new cell mask with switched segments
data.mask_cell = double((data.mask_bg - data.segs.segs_good - data.segs.segs_3n)>0);
sqr3 = strel( 'square', 3 );
mod_map = imdilate( mod_map, sqr3 );

% make new regions using the new cell mask from modified segments
% and set their score to 0
data  = intMakeRegs( data, mask_bad_regs, CONST, E );
mod_segs = unique( data.regs.regs_label( logical(mod_map) ) );
mod_segs = mod_segs(logical(mod_segs));
data.regs.score(mod_segs) = 0;

end

function data = intMakeRegs( data, mask_bad_regs, CONST, E )
% intMakeRegs : creates info for bad regions or makes new regions

ss = size( data.mask_cell );
NUM_INFO = CONST.regionScoreFun.NUM_INFO;
data.regs.regs_label = bwlabel( data.mask_cell );
data.regs.num_regs   = max( data.regs.regs_label(:) );
data.regs.props      = regionprops( data.regs.regs_label, ...
    'BoundingBox','Orientation','Centroid','Area');
data.regs.score      = ones( data.regs.num_regs, 1 );
data.regs.scoreRaw      = ones( data.regs.num_regs, 1 );
data.regs.info       = zeros( data.regs.num_regs, NUM_INFO );
data.regs.boun      = zeros( data.regs.num_regs, 1 );

for ii = 1:data.regs.num_regs
    
    [xx,yy] = getBBpad( data.regs.props(ii).BoundingBox, ss, 1);
    mask = data.regs.regs_label(yy,xx)==ii;
    
    if ii == 1; % first region, create info table
        tmp = CONST.regionScoreFun.props( mask, data.regs.props(ii) );
        data.regs.info = zeros(data.regs.num_regs, numel(tmp));
    end
    
    data.regs.info(ii,:) = CONST.regionScoreFun.props( mask, data.regs.props(ii) );
    data.regs.boun(ii) = any( [1==xx(1),1==yy(1),ss(1)==yy(end),ss(2)==xx(end)] );
    data.regs.info(ii,:) = CONST.regionScoreFun.props( mask, data.regs.props(ii) );
    data.regs.scoreRaw(ii) = CONST.regionScoreFun.fun(data.regs.info(ii,:), E);
    data.regs.score(ii) = data.regs.scoreRaw(ii) > 0
  
    if exist( 'mask_bad_regs', 'var' ) && ~isempty( mask_bad_regs )
        mask_ = mask_bad_regs(yy,xx);        
        if any( mask(mask_) )
            data.regs.score(ii) = 0;
        end
    end
    
end


end

