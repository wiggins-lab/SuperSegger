function makeBadRegions(dirname,CONST)
% makeBadRegions : creates bad regions to train the software on region shape
% Creates *_mod.mat files in the seg directory with bad regions (turns on
% and off random segments) and assigns them a bad score (0).
%
% INPUT :
%       dirname : directory that contains seg.mat files
%       CONST : segmentation constants
%
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins, Stella Stylianidou.
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

dirname = fixDir(dirname);
contents=dir([dirname,'*_seg.mat']);
num_im = length(contents);
num_files = 3;
h = waitbar( 0, 'Creating bad region examples for training.' );
cleanup = onCleanup( @()( delete( h ) ) );
for i = 1 : num_im % go through all the images
    try
    waitbar(i/num_im,h);
    catch
    end
    dataname = [dirname,contents(i).name];
    data = load(dataname);
    
    % if there are no regions it makes regions from the segments
    %if ~isfield( data, 'regs' ); - i will just remake them for now!
    %data = intMakeRegs( data, CONST, [],1);
    save(dataname,'-STRUCT','data');
    for j = 1 : num_files
        data_ = intModRegions( data, CONST );
        datamodname=[dirname,contents(i).name(1:end-4),'_',sprintf('%02d',j),'_mod.mat'];
        save(datamodname,'-STRUCT','data_');
    end
    
end
try
    close(h);
catch
end
end


function [data] = intModRegions ( data,CONST )
% intModRegions ; modifies regions to create bad regions

% fraction of segments to be modified to create bad regions
FRACTION_SEG_MOD = 0.3;
num_segs = numel(data.segs.score);
num_mod  = ceil( num_segs*FRACTION_SEG_MOD );
mod_list = unique(ceil(rand(1,num_mod)*num_segs));
mod_map = logical(data.mask_cell)*0;

scoreMask = false(size(data.phase));
for ii = 1:data.regs.num_regs
    [xx,yy] = getBB( data.regs.props(ii).BoundingBox );
    scoreMask(yy,xx) = scoreMask(yy,xx) | logical( data.regs.score(ii) & (data.regs.regs_label(yy,xx)==ii) );
end


% find the indices of regions that have bad score
try
    ind_bad_regs = find(data.regs.score == 0 ); % find bad scores
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
        % xx and yy location of segment in image
        [xx,yy] = getBB( data.segs.props(ii).BoundingBox );
        
        if ~isnan(data.segs.score(ii))
             if data.segs.score(ii) %  % score of the segment is 1
                data.segs.score(ii) = 0; % set to 0
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
            mod_map (yy,xx) = (data.segs.segs_label(yy,xx)==ii);
            %imshow(ag(mod_map));
            
        end
    end
    
end

% new cell mask with switched segments
data.mask_cell = double((data.mask_bg - data.segs.segs_good - data.segs.segs_3n)>0);
sqr3 = strel( 'square', 3 );
mod_map = imdilate( mod_map, sqr3 );

% make new regions using the new cell mask from modified segments

% sets all scores to 1
ss = size( data.mask_cell );
NUM_INFO = CONST.regionScoreFun.NUM_INFO;
data.regs.regs_label = bwlabel( data.mask_cell );
data.regs.num_regs = max( data.regs.regs_label(:) );
data.regs.props = regionprops( data.regs.regs_label, ...
    'BoundingBox','Orientation','Centroid','Area');
data.regs.score  = ones( data.regs.num_regs, 1 );
data.regs.scoreRaw = ones( data.regs.num_regs, 1 );
data.regs.info = zeros( data.regs.num_regs, NUM_INFO );

for ii = 1:data.regs.num_regs
    
    [xx,yy] = getBBpad( data.regs.props(ii).BoundingBox, ss, 1);
    mask = data.regs.regs_label(yy,xx)==ii;
    data.regs.info(ii,:) = CONST.regionScoreFun.props( mask, data.regs.props(ii));
    
end

E = CONST.regionScoreFun.E;
data.regs.scoreRaw = CONST.regionScoreFun.fun(data.regs.info, E)';

bad_regs_before = unique( data.regs.regs_label( logical(mask_bad_regs) ) );
bad_regs_before = bad_regs_before(logical(bad_regs_before));
data.regs.score(bad_regs_before) = 0;
mod_regs = unique( data.regs.regs_label( logical(mod_map) ) );
mod_regs = mod_regs(logical(mod_regs));
% sets scores of all regions which had modified segments to 0
data.regs.score(mod_regs) = 0;

end

