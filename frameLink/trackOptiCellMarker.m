function [clist, clist_def] = trackOptiCellMarker(dirname, CONST, header)
%  trackOptiCellMarker : puts together a list of complete cell cycles.
%  It goes through the dirname/*err.mat files and determines which
%  cells go through complete cell cycles (i.e. cells in which both birth and 
%  division are observed) Clist contains information about complete cell cycles 
%  (see information in clist_def). Note that the complete clist is made later
%  by trackOptiClist.m this to get the pole information. Since this is set 
%  by the next step in the process. 
%  
%
% INPUT : 
%       dirname: seg folder eg. maindirectory/xy1/seg
%       CONST: the segmentation constants.
%       header : string displayed with information
% OUTPUT :
%       clist : list of all cells found with non time dependent information about them. 
%       clist_def : definitions of the fields in clist set.
%
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins.
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

if ~exist('header', 'var')
    header = [];
end

dirname = fixDir(dirname);

MIN_CELL_AGE = CONST.trackOpti.MIN_CELL_AGE;
verbose = CONST.parallel.verbose;

% this variable contains the label for every set in the clist variable.
clist_def =  { 'Cell ID', ...
    'Region Num Birth', ...
    'Region Num Divide', ...
    'Cell Birth Time', ...
    'Cell Division Time', ...
    'Cell Age', ...
    'Cell Dist to edge', ...
    'Old Pole Age--must be run after Batch to get this right', ...
    'Long Axis Birth', ...
    'Long Axis Divide'};



contents=dir([dirname '*_err.mat']);
num_im = length(contents);
clist = [];

if CONST.parallel.show_status
    h = waitbar( 0, 'Marking complete cell cycles.');
    cleanup = onCleanup( @()( delete( h ) ) );
else
    h = [];
end

% Work barkwards starting at the last frame.
for i = (num_im-1):-1:2;
    
   
    if CONST.parallel.show_status
        waitbar((num_im-i)/num_im,h,['Marking complete cell cycles--Frame: ',num2str(i),'/',num2str(num_im)]);
    end
    % load data
    data_c = loaderInternal([dirname,contents(i).name]);
    
    % calculate distance from the edge of the colony
    data_c.dist_mask = makeColonyDist( data_c.mask_bg );
    
    
    % loop through regions looking for cells that divide successfully in
    % this frame.
    for ii = 1:data_c.regs.num_regs
        
        % get the regions that the current region maps to in the next frame
        list_f = data_c.regs.map.f{ii};
        
        
        % if the cell divides in this frame and the stat0 is true (meaning
        % that it resulted itself from a good division) and the error
        % history hasn't been set, the cell is tracked for a complete cell
        % cycles.
        if data_c.regs.divide(ii) && ...
                data_c.regs.stat0(ii) && ...
                (~data_c.regs.ehist(ii) && ...
                (i-data_c.regs.birth(ii)) >= MIN_CELL_AGE )
            
            if verbose
                disp([header, 'CellMarker: Complete Cell Cycle! Frame:', num2str(i),' reg: ', num2str(ii)]);
            end
            
            % get the distance of the cell from the edge of the colony and
            % put that distance (in pixels) in cell_dist
            mask_cell             = (data_c.regs.regs_label==ii);
            cell_dist             = min(data_c.dist_mask(mask_cell));
            
            % Check to make sure that the cell has been assigned an ID
            % number
            if isfield(data_c.regs,'ID')
                
                % The first time this function is called on a data set, the
                % CellA field doesn't exist yet. So.. if it doesn't exist,
                % record a NaN as the pole age
                if isfield( data_c, 'CellA' )
                    pole_age = data_c.CellA{ii}.pole.op_age;
                else
                    pole_age = NaN;
                end
                
                % store data in clist to set stat0 == 2 (good division)
                clist = [clist; data_c.regs.ID(ii), ii, ii, data_c.regs.birth(ii), i, i-data_c.regs.birth(ii), cell_dist, pole_age, data_c.regs.L1(ii), data_c.regs.L1(ii)];
                
                %                         clist_def =     { 'Cell ID', ...
                %                 'Region Num Birth', ...
                %                 'Region Num Divide', ...
                %                 'Cell Birth Time', ...
                %                 'Cell Division Time', ...
                %                 'Cell Age', ...
                %                 'Cell Dist to edge', ...
                %                 'Old Pole Age--must be run after Batch to get this right', ...
                %                 'Long Axis Birth', ...
                %                 'Long Axis Divide'};
                
                % field 2 will be updated when the code moves to the previous frame.
                
            else
                %clist = [clist; data_c.regs.birth(ii), i, ii, ii];
                disp( [header, 'CellMarker Error']);
            end
        elseif data_c.regs.divide(ii) && ...
                data_c.regs.stat0(ii) && ...
                (~data_c.regs.ehist(ii))
            
            data_c.regs.error.label{ii} = [data_c.regs.error.label{ii},...
                'Frame: ',num2str(i),', reg: ', num2str(ii), ...
                '. Division Failed: Cell age ', ...
                num2str(i-data_c.regs.birth(ii)), ...
                '< min age ' , num2str(MIN_CELL_AGE), '.'];
            
            if verbose
                disp([header, 'CellMarker: ', data_c.regs.error.label{ii}] );
            end
        end
        
    end
    
    % loop through clist to set the stat0 flag to 2 for cells that are
    % observed for complete cell cycles
    ss = size(clist);
    
    for ii = 1:ss(1);
        
        % get the current region number for entry ii of the clist.
        jj = clist(ii,2);
        
        % check the birth date of the cell and skip it if it is born after
        % the current frame number.
        if i >=  clist(ii,4);
            try
                
                % This cell is active, therefore update the region number
                % for the next frame
                clist(ii,2) = data_c.regs.map.r{jj}(1);
                
                % And also update the length of the cell since we want the
                % length @ birth.
                clist(ii,9) = data_c.regs.L1(jj);
                
                % set the stat0 to 2 meaning the the cell is observed for
                % an entire cell cycle.
                data_c.regs.stat0(jj) = 2;
                
            catch
                disp([header, 'Error is trackOptiCellMarker.']);
            end
        end
    end
    
    % resave the updated *err.mat file and move on to the previous frame.
    dataname=[dirname,contents(i).name];
    save(dataname,'-STRUCT','data_c');
    
    
end

if CONST.parallel.show_status
    close(h);
end
% Resort the list of cells so it is listed by cell ID number.
if ~isempty(clist)
    try
        [tmp,ind_order] = sort( clist(:,1) );
        clist = clist(ind_order,:);
    catch
        disp([header, 'Error is trackOptiCellMarker.']);
    end
end

end



function data = loaderInternal( filename )
data = load( filename );
end