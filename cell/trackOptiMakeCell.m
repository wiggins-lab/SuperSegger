function trackOptiMakeCell(dirname,CONST,header)
% trackOptiMakeCell : generates the CellA field indexed by the region number
% which contains information about each cell in each region in each frame.
%
% It goes through the dirname/*err.mat files and computes the characteristics of the
% cells in each frame and puts them in the CellA structure that is indexed
% by the region number, not the cell ID. This code figures out the pole
% age and also computes statistics on the fluorescence channels as
% well as fitting the locus positions. These last two features are
% controlled by parameters set in the loadConstants.m or
% loadConstantsMine.m files.
%
% data.CellA{1}.
%           mask		: logical (1 and 0) cell mask, unoriented
% 			r_offset	: location of cell in full image from top left corner
% 			BB          : coordinates of cell bounding box, containing the
% 			cell and the pad
% 			edgeFlag	: if the cell is on the edge of the image (bad)
% 			phase		: the cropped phase image of the cell
% 			coord		: coordinates, area, and orientation, see below
% 			length		: (1) length and (2) width of the cell
% 			pole		: orientation of the cell pole, see below
% 			fluor1		: the 1st fluor channel image
% 			fuor1mm     : min and max of fluor1
% 			fl1         : statistics of fluor1, e.g. background level
% 			fluor2		: the 2nd fluor channel image
% 			fluor2mm	: min and max of fluor2
% 			fl2         : statistics of fluor2
% 			cell_dist	: distance to the edge of the colony
% 			gray		: average phase gray value in cell region
% 			locus1		: If focus fitting was run, data on the fit
% 			(locations, score..), see below
% 			locus2		: Same as above for channel 2
% 			r           : global coordinates of cell centroid (mid-point of cell)
% 			error		: segmentation error list
% 			ehist		: ehist is the sum of all errors in the region?s history
%           contactHist	: ?
%           stat0		: stat0 flag that is true if the cell is born without error
% 
% The coord field contains a lot of cell specific info:
% data.CellA{1}.coord =
%         A: Area of cell mask
%         r_center: geometrical center of the cell
%         box: coordinates of box surrounding cell
%         xaxis: coordinates of major axis
%         yaxis: coordinates of minor axis
%         I: Moment of inertia of cell mask
%         e1: priniple axis (major) unit vector
%         e2: priniple axis (minor) unit vector
%         rcm: center of mass position of mask
% 
% The pole field contains info pertaining to the cell pole and pole ages:
% data.CellA{1}.pole =
%        e1: major axis direction.
%        op_ori: 1 if old pole is in direction of e1
%             -1 if old pole is in opposite e1
%        op_age: age of old pole in cell cycles
%             NaN if no birth is observed
%        np_age: age of new pole in cell cycles
% 
% The locus field contains info from locus fitting - if it ran.
% data.CellA{1}.locus1(1) =
%       r: Spot position in global coords
%       score: score from spot fit.
%       intensity: raw intensity
%       b: spot width from fit
%       shortaxis: Locus position in local coords (short axis)
%       longaxis: Spot position in local coords (long axis)
%
% INPUT :
%       dirname: seg folder eg. maindirectory/xy1/seg
%       CONST: are the segmentation constants.
%       header : string displayed with information
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

if(nargin<1 || isempty(dirname))
    dirname = '.';
end
dirname = fixDir(dirname);

verbose = CONST.parallel.verbose;

% Get the track/error file names
contents=dir([dirname '*_err.mat']);
num_im = numel(contents);

if CONST.parallel.show_status
    h = waitbar( 0, 'Making Cells.');
    cleanup = onCleanup( @()( delete( h ) ) );
else
    h = [];
end

% loop through all the cells.
for i = 1:num_im;
    
    if (i ==1) && (1 == num_im) % snapshots
        data_r = [];
        data_c = loaderInternal([dirname,contents(i).name]);
        data_f = [];
    elseif i == 1; % first frame
        data_r = [];
        data_c = loaderInternal([dirname,contents(i).name]);
        data_f = loaderInternal([dirname,contents(i+1).name]);        
    elseif i==num_im; % last frame
        data_r = loaderInternal([dirname,contents(i-1).name]);
        data_c = loaderInternal([dirname,contents(i).name]);        
        data_f = [];
    else
        data_r = loaderInternal([dirname,contents(i-1).name]);
        data_c = loaderInternal([dirname,contents(i).name]);
        data_f = loaderInternal([dirname,contents(i+1).name]);
    end
    
    % first frame, find the total number of channels
    if i==1
        nc = 0;
        tmp_fn = fieldnames( data_c );
        nf = numel( tmp_fn );
        for j = 1:nf;
            if numel(strfind(tmp_fn{j},'fluor')==1) && ...
                    ~numel((strfind(tmp_fn{j},'fluor0'))) && ...
                    ~numel((strfind(tmp_fn{j},'filtered')))
                nc = nc+1;
            end
        end
    end
    
    % set min max of fluorescence
    for j = 1:nc
        tmp = getfield( data_c,['fluor',num2str(j)]);
        ff(j,:) = [min(tmp(:)),max(tmp(:))];
    end
    
    % make the cell array holding the cells that has one element for each
    % region.
    data_c.CellA = cell(1,data_c.regs.num_regs);
    dist_mask = makeColonyDist( data_c.mask_bg );
    
    for ii = 1:data_c.regs.num_regs
        % Cut out a region with pixel pad size PAD_SIZE.
        celld = struct();
        PAD_SIZE = 5;
        ss = size(data_c.phase);
        
        celld.cellLength = [data_c.regs.L1(ii),data_c.regs.L2(ii)];
        [xx,yy]  = getBBpad( data_c.regs.props(ii).BoundingBox, ss, PAD_SIZE);
        celld.xx = xx;
        celld.yy = yy;
        celld.mask  = logical(data_c.regs.regs_label(yy,xx)==ii);
        celld.r_offset = [xx(1),yy(1)];
        celld.BB  = [xx(1),yy(1),xx(end)-xx(1),yy(end)-yy(1)];
        tmpEdge = [ ceil(data_c.regs.props(ii).BoundingBox(1)),...
            ceil(data_c.regs.props(ii).BoundingBox(2)),...
            floor(sum(data_c.regs.props(ii).BoundingBox([1,3]))),...
            floor(sum(data_c.regs.props(ii).BoundingBox([2,4])))];
        celld.edgeFlag = any( tmpEdge == [1,1,ss(2),ss(1)]);
        
        % copy information from regions
        if CONST.trackOpti.NEIGHBOR_FLAG
            celld.contactHist = data_c.regs.contactHist(ii);
        end
        
        
        % record the number of cell neighbors
        if CONST.trackOpti.NEIGHBOR_FLAG
            nei_ = numel(trackOptiNeighbors(data_c,ii));
            data_c.regs.numNeighbors{ii} = nei_ ;
            celld.numNeighbors = nei_ ;
        end
        
        celld.phase     = data_c.phase(yy,xx);
        
        % Keep track of pole age and what direction the old pole is in.
        if isempty(data_r) || isempty(data_c.regs.map.r{ii})
            celld             = toMakeCell(celld,[],data_c.regs.props(ii));
            celld.pole.e1     = celld.coord.e1;            
            celld.pole.op_ori =   0;
            celld.pole.op_age = NaN;
            celld.pole.np_age = NaN;
        else
            if data_c.regs.error.r(ii)
                try
                    celld = toMakeCell(celld, data_r.CellA{data_c.regs.map.r{ii}(1)}.pole.e1,data_c.regs.props(ii));
                catch ME
                    printError(ME);
                end
                celld.pole.e1     = celld.coord.e1;
                celld.pole.op_ori =   0;
                celld.pole.op_age = NaN;
                celld.pole.np_age = NaN;
                
            elseif data_c.regs.birthF(ii) && ( data_c.regs.sisterID(ii) ) && ~isempty(find( data_c.regs.sisterID(ii) == data_c.regs.ID ))
                
                cell_old = data_r.CellA{data_c.regs.map.r{ii}(1)};                
                celld  = toMakeCell(celld, cell_old.pole.e1,data_c.regs.props(ii));
                celld.pole.e1 = celld.coord.e1;
                e1 = celld.pole.e1;
                op_ori = cell_old.pole.op_ori;

                jj = find( data_c.regs.sisterID(ii) == data_c.regs.ID );
                jj = jj(1);
                rs = data_c.regs.props(jj).Centroid;
                r0 = data_c.regs.props(ii).Centroid;
                
                dr = (r0-rs)*e1;                
                celld.pole.op_ori = sign(dr);
                
                if celld.pole.op_ori == cell_old.pole.op_ori
                    celld.pole.op_age = cell_old.pole.op_age+1;
                else
                    celld.pole.op_age = cell_old.pole.np_age+1;
                end
                
                celld.pole.np_age = 1;
                
                debug_flag = 0;
                if debug_flag
                    clf;
                    kk = find( data_c.regs.motherID(ii) == data_r.ID );
                    imshow( 0.5*cat(3, ag(data_c.regs.regs_label==jj), ag(data_c.regs.regs_label==ii),ag(data_r.regs_label==kk)));
                    hold on;
                    
                    tmp = celld;
                    r = tmp.coord.r_center;
                    xaxisx = r(1) + [0,tmp.length(1)*tmp.coord.e1(1)]/2;
                    xaxisy = r(2) + [0,tmp.length(1)*tmp.coord.e1(2)]/2;
                    yaxisx = r(1) + [0,tmp.length(2)*tmp.coord.e2(1)]/2;
                    yaxisy = r(2) + [0,tmp.length(2)*tmp.coord.e2(2)]/2;
                    old_pole = r + tmp.length(1)*tmp.coord.e1'*tmp.pole.op_ori/2;
                    new_pole = r - tmp.length(1)*tmp.coord.e1'*tmp.pole.op_ori/2;
                    
                    plot( r(1), r(2), 'g.');
                    plot( xaxisx, xaxisy, 'g-');
                    plot( yaxisx, yaxisy, 'g-');
                    plot( old_pole(1), old_pole(2), 'r.');
                    plot( new_pole(1), new_pole(2), 'w.');
                    
                    tmp = data_r.CellA{kk};
                    r = tmp.coord.r_center;
                    r = tmp.coord.r_center;
                    xaxisx = r(1) + [0,tmp.length(1)*tmp.coord.e1(1)]/2;
                    xaxisy = r(2) + [0,tmp.length(1)*tmp.coord.e1(2)]/2;
                    yaxisx = r(1) + [0,tmp.length(2)*tmp.coord.e2(1)]/2;
                    yaxisy = r(2) + [0,tmp.length(2)*tmp.coord.e2(2)]/2;
                    old_pole = r + tmp.length(1)*tmp.coord.e1'*tmp.pole.op_ori/2;
                    new_pole = r - tmp.length(1)*tmp.coord.e1'*tmp.pole.op_ori/2;
                    
                    plot( r(1), r(2), 'g.');
                    plot( xaxisx, xaxisy, 'g-');
                    plot( yaxisx, yaxisy, 'g-');
                    if ~tmp.pole.op_ori
                        plot( old_pole(1), old_pole(2), 'r.');
                        plot( new_pole(1), new_pole(2), 'w.');
                    end
                end
            else
                if (data_c.regs.map.r{ii}(1) == 0)
                    data_c.regs.map.r{ii}(1) = [];
                end
                celld  = toMakeCell(celld, data_r.CellA{data_c.regs.map.r{ii}(1)}.pole.e1,data_c.regs.props(ii));
                celld.pole = data_r.CellA{data_c.regs.map.r{ii}(1)}.pole;
                celld.pole.e1 = celld.coord.e1;
            end
        end
        
        
        % copy fluorescence fields, compute fluorescence statistics and find loci
        for j = 1:nc
            tmp   = data_c.(['fluor',num2str(j)]);
            celld.(['fluor',num2str(j)]) = tmp(yy,xx);
            celld.(['fluor',num2str(j),'mm']) = ff(j,:) ;
            
            if isfield( CONST.trackLoci, 'fluorFlag' ) && CONST.trackLoci.fluorFlag
                tmp = trackOptiCellFluor( tmp(yy,xx), celld.mask, celld.r_offset);
            else
                tmp = [];
            end       
            tmp.bg = data_c.(['fl',num2str(j),'bg']);
            celld.(['fl',num2str(j)]) = tmp;
            
        end
        
        % compute the distance to the edge of the colony
        if data_c.regs.ID(ii)
            
            [xx,yy]        = getBBpad( data_c.regs.props(ii).BoundingBox, ss, 0);
            mask_cell      = logical(data_c.regs.regs_label(yy,xx)==ii);
            dist_mask_crop = dist_mask(yy,xx);
            cell_dist      = min(dist_mask_crop(mask_cell));
            celld.cell_dist = cell_dist;
            
            % calculate average phase gray value in cell region
            celld.gray = mean(double(celld.phase(celld.mask)));
            
        end
        
        data_c.CellA{ii} = celld;
        
    end
    
    % save the updated err files.
    dataname = [dirname,contents(i).name];
    save(dataname,'-STRUCT','data_c');
    
    if CONST.parallel.show_status
        waitbar(i/num_im,h,['Making Cells--Frame: ',num2str(i),'/',num2str(num_im)]);
    elseif verbose
        disp([header, 'MakeCell frame: ',num2str(i),' of ',num2str(num_im)]);
    end
end

if CONST.parallel.show_status
    close(h);
end

end

function data = loaderInternal(filename)
data = load( filename );
end