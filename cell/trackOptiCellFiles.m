function trackOptiCellFiles( dirname, dirname_cell, CONST, header, clist )
% trackOptiCellFiles : organizes the data into the final cell files that
% contain all the time lapse data for a single cell.
% It allows for cell gating. If a clist is passed, gate the list and then make an
% ID_LIST containing cells for which we want to generate cell files.
%
% INPUT :
%       dirname : xy directory
%       dirname_cell : where cell files are placed, usually dirname/cell file
%       CONST : segmentation cosntants
%       header : is the last axis of the cell
%       clist : array of cell files, can be used to generate cell files from the gated clist
%
% Copyright (C) 2016 Wiggins Lab
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.

if ~exist( 'clist', 'var') || isempty( clist) || isempty(clist.data)
    ID_LIST = [];
else
    clist = gate(clist);
    ID_LIST = clist.data(:,1);
end

if ~exist('header')
    header = [];
end

max_cell_num = 0;


% Set up directory etc.
dirseperator = filesep;

if(nargin<1 || isempty(dirname))
    dirname='.';
end

dirname = fixDir(dirname);

if(nargin<2 || isempty(dirname))
    dirname_cell = dirname;
end

dirname_cell = fixDir (dirname_cell);
contents=dir([dirname '/*_err.mat']);

% check to make sure that there are err.mat files to work from. If not,
% return.
if isempty( contents )
    disp( [header, 'trackOptiCellFiles: No error files have been found... possibly too many segs.'] );
else
    num_im = length(contents);
    
    % get the right number of cell malloc'd:
    data_c    = loaderInternal([dirname,contents(end).name]);
    MAX_NUM_CELLS = max(data_c.regs.ID)+100;
    DA            = cell(1,MAX_NUM_CELLS);
    
    if CONST.show_status
        h = waitbar( 0, 'Make Cell Files.');
    else
        h = [];
    end
    for i = 1:num_im;
        
        if CONST.show_status
            waitbar(i/num_im,h,['Make Cell Files--Frame: ',num2str(i),'/',num2str(num_im)]);
        else
            disp( [header, 'Cell Files--Frame: ',num2str(i),'/',num2str(num_im)] );
        end
        
        % load data
        data_c    = loaderInternal([dirname,contents(i).name]);
        num_regs = data_c.regs.num_regs;
        disp( [header, 'CellFiles: ','Frame: ', num2str(i), '. max cell num: ', num2str( max_cell_num ) ] );
        
        for ii = 1:num_regs
            
            cellNum = data_c.regs.ID(ii);
            max_cell_num = max([max_cell_num, cellNum]);
            
            
            if cellNum && ( isempty( ID_LIST ) || ismember( cellNum, ID_LIST ))
                if data_c.regs.birthF(ii) == 1 && data_c.regs.deathF(ii) == 1
                    % for snapshot images (birth and death are 1)
                    DA{cellNum} = intInitCell( data_c, ii, cellNum );
                    DA{cellNum} = intUpCell( DA{cellNum}, data_c, ii );
                    DA{cellNum} = intDelCell( DA{cellNum},...
                        dirname_cell, cellNum );
                    
                elseif data_c.regs.birthF(ii)
                    % if a cell is born, initialize the structure
                    DA{cellNum} = intInitCell( data_c, ii, cellNum );
                    
                elseif data_c.regs.deathF(ii)
                    % if a cell divides in the current frame, update
                    % the structure then delete the cell after saving
                    DA{cellNum} = intUpCell( DA{cellNum}, data_c, ii );
                    
                    % add cell dist to cell structure.
                    DA{cellNum} = intDelCell( DA{cellNum},...
                        dirname_cell, cellNum );
                    
                else
                    % else just update the cell
                    DA{cellNum} = intUpCell( DA{cellNum}, data_c, ii );
                end
            end
            
        end
        '';
    end
    
    
    %% debug - added 1/26/2012
    % cells without a death flag were not put into the Cell directory,
    % fix this b/c lysed cells often fall in this category
    
    for ii=1:MAX_NUM_CELLS
        if ~isempty(DA{ii})
            disp( ['Missing cell ', num2str(DA{ii}.ID)] );
            DA{ii} = intDelCell( DA{ii},...
                dirname_cell, ii );
        end
    end
    
    %
    if CONST.show_status
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
    data.CellA      = {data.CellA{:},celld};
catch ME
    printEroor(ME);
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
% inDelCell : destroys a cell on division to liberate memory and save the cell file.
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

if data.stat0 == 2; % full cell cycle cell.
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