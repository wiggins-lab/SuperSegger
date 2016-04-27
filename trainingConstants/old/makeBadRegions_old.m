function makeBadRegions( dirname,E, CONST)
%MAKEBADREGIONS makes bad regions to train the software on region shape 

dirname = fixDir(dirname);
contents=dir([dirname,'*_seg.mat']);
num_im = length(contents);

h = waitbar( 0, 'Creating bad region examples' );
for i = 1 : num_im % go through all the images
    waitbar(i/num_im,h);
    dataname = [dirname,contents(i).name];
    data = load(dataname);

    % if there are no regions it makes regions from the segments
    %if ~isfield( data, 'regs' ); - i will just remake them for now!
        data = intMakeRegs( data, [], CONST ,E);
    %end
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
FRACTION_SEG_MOD = 0.8;
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

