function trackOptiCellFiles( dirname, dirname_cell, CONST, header, clist )
% trackOptiCellFiles : organizes the data into the final cell files that
% contain all the time lapse data for a single cell.
% It allows for cell gating. If a clist is passed with an already made gate
% the code generates cell files for only cells that pass the gate.
%
% INPUT :
%       dirname : xy directory
%       dirname_cell : where cell files are placed, usually dirname/cell file
%       CONST : segmentation constants
%       header : string with information
%       clist : array of cell files, can be used to generate gated cell files
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

if ~exist( 'clist', 'var') || isempty( clist) || isempty(clist.data)
    ID_LIST = [];
else % gating clist
    clist = gate(clist);
    ID_LIST = clist.data(:,1);
end

if ~exist('header','var')
    header = [];
end

max_cell_num = 0;

% Set up directory etc.
if(nargin<1 || isempty(dirname))
    dirname='.';
end

dirname = fixDir(dirname);

if(nargin<2 || isempty(dirname_cell))
    dirname_cell = dirname;
end


dirname_cell = fixDir (dirname_cell);
contents=dir([dirname '/*_err.mat']);
verbose = CONST.parallel.verbose;

% check to make sure that there are err.mat files to work from. If not,
% return.
if isempty( contents )
    disp( [header, 'trackOptiCellFiles: No error files have been found. Possibly too many segments.'] );
else
    
    % create a DA cell array for the number of cells in last frame
    num_im = length(contents);
    data_c = loaderInternal([dirname,contents(end).name]);
    MAX_NUM_CELLS = max(data_c.regs.ID)+100;
    DA  = cell(1,MAX_NUM_CELLS);
    
    if CONST.parallel.show_status
        h = waitbar( 0, 'Make Cell Files.');
        cleanup = onCleanup( @()( delete( h ) ) );
    else
        h = [];
    end
    
    for i = 1:num_im
        
        if CONST.parallel.show_status
            waitbar(i/num_im,h,['Make Cell Files--Frame: ',num2str(i),'/',num2str(num_im)]);
        elseif verbose
            disp( [header, 'Cell Files--Frame: ',num2str(i),'/',num2str(num_im)] );
        end
        
        % load data
        data_c    = loaderInternal([dirname,contents(i).name]);
        num_regs = data_c.regs.num_regs;
        if verbose
            disp( [header, 'CellFiles: ','Frame: ', num2str(i), '. max cell num: ', num2str( max_cell_num ) ] );
        end
        
        for ii = 1:num_regs
            cellNum = data_c.regs.ID(ii);
            max_cell_num = max([max_cell_num, cellNum]);
            
            if cellNum && ( isempty( ID_LIST ) || ismember( cellNum, ID_LIST ))
                if data_c.regs.birthF(ii) == 1 && data_c.regs.deathF(ii) == 1
                    % for snapshot images (birth and death are 1)
                    % initialize cell
                    DA{cellNum} = intInitCell( data_c, ii, cellNum );
                    % update cell
                    DA{cellNum} = intUpCell( DA{cellNum}, data_c, ii );
                    % delete and save cell
                    DA{cellNum} = intDelCell( DA{cellNum},...
                        dirname_cell, cellNum );
                    
                elseif data_c.regs.birthF(ii)
                    % if a cell is born, initialize the structure
                    DA{cellNum} = intInitCell( data_c, ii, cellNum );
                    
                elseif data_c.regs.deathF(ii)
                    % if a cell divides in the current frame, update
                    % the structure then delete the cell after saving
                    DA{cellNum} = intUpCell( DA{cellNum}, data_c, ii );
                    
                    % saves and deletes cell from datastructure
                    DA{cellNum} = intDelCell( DA{cellNum},...
                        dirname_cell, cellNum );
                    
                else
                    % update the cell
                    DA{cellNum} = intUpCell( DA{cellNum}, data_c, ii );
                end
            end
            
        end
    end
    
    % deletes and saves cells that were not saved yet
    for ii=1:MAX_NUM_CELLS
        if ~isempty(DA{ii})
            if verbose
                disp( ['Missing cell ', num2str(DA{ii}.ID)] );
            end
            DA{ii} = intDelCell( DA{ii},dirname_cell, ii );
        end
    end
    
    if CONST.parallel.show_status
        close(h);
    end
end
end


function data = intInitCell( data_c, ii, cellNum )
% intInitCell : creates an array of structures for a cell.
% It's called the first frame that a cell appears.
%
% INPUT :
%       data_c : cell data
%       ii : frame number
%       cellNum : cell id
% OUTPUT :
%       data : cell array/structure

celld  = data_c.CellA{ii};
celld.r  = data_c.regs.props(ii).Centroid;
celld.error.label  = data_c.regs.error.label{ii};
celld.ehist = data_c.regs.ehist(ii);
celld.contactHist  = data_c.regs.contactHist(ii);
celld.stat0 = data_c.regs.stat0(ii);
data.CellA      = {celld};
data.death      = data_c.regs.death(ii);
data.birth      = data_c.regs.birth(ii);
data.divide     = data_c.regs.divide(ii);
data.sisterID   = data_c.regs.sisterID(ii);
data.motherID   = data_c.regs.motherID(ii);
data.daughterID = data_c.regs.daughterID{ii};
data.ID         = cellNum;
data.neighbors  = data_c.regs.neighbors{ii};

end


function data = intUpCell( data, data_c, ii )
% inUpCell : is called to update a cell in a frame. The cell must already
% exist and this must be called before destroying a cell in the frame that
% the cell divides.

celld = data_c.CellA{ii};
celld.r = data_c.regs.props(ii).Centroid;
celld.error.label = data_c.regs.error.label{ii};
celld.ehist = data_c.regs.ehist(ii);
celld.contactHist = data_c.regs.contactHist(ii);
celld.stat0  = data_c.regs.stat0(ii);

try
    data.CellA = {data.CellA{:},celld};
catch ME
    printError(ME);
end

data.death      = data_c.regs.death(ii);
data.birth      = data_c.regs.birth(ii);
data.divide     = data_c.regs.divide(ii);
data.sisterID   = data_c.regs.sisterID(ii);
data.motherID   = data_c.regs.motherID(ii);
data.daughterID = data_c.regs.daughterID{ii};
data.neighbors  = data_c.regs.neighbors{ii};

end


function data = intDelCell( data, dirToSave, cellNum )
% inDelCell : destroys a cell when it divides and saves the cell file.
%
% INPUT :
%       data : cell data
%       dirToSave : directory that the cell file will be save in
%       cellNum : cell id used to save the cell file
% OUTPUT :
%       data : cell file


data.stat0 = data.CellA{end}.stat0;
data.ehist = data.CellA{end}.ehist;
data.contactHist = data.CellA{end}.contactHist;
dirToSave = fixDir(dirToSave);

if data.stat0 == 2 % full cell cycle cell.
    dataname=[dirToSave,'Cell',sprintf( '%07d', cellNum ),'.mat'];
else
    dataname=[dirToSave,'cell',sprintf( '%07d', cellNum ),'.mat'];
end

save(dataname,'-STRUCT','data');
data = [];

end


function data = loaderInternal( filename )
% loaderInternal : standard internal loader function. It just loads the file
data = load( filename );
end
