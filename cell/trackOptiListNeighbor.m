function [clist_tmp] = trackOptiListNeighbor(dirname,CONST,header)
% trackOptiListNeighbor : creates a neighbors list for each cell.
%
% INPUT :
%       dirname : seg folder eg. maindirectory/xy1/seg
%       CONST : segmentation constants.
%       header : string displayed with information
% OUTPUT :
%       clist_temp : contains list of neighbors
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

if ~exist('header','var')
    header = [];
end

if(nargin<1 || isempty(dirname))
    dirname = '.';
end
dirname = fixDir(dirname);

% Get the track file names...
contents=dir([dirname '*_err.mat']);
if isempty(contents)
    disp('trackOptiListNeighbor : No files found');
    clist_tmp.data = [];
    clist_tmp.def={};
    clist_tmp.gate=[];
else
    data_c = loaderInternal([dirname,contents(end).name]);
    MAX_CELL = max(data_c.regs.ID) + 100;
    num_im = numel(contents);
    
    if CONST.show_status
        h = waitbar( 0, 'Make Neighbor List.');
    else
        h = [];
    end
    
    clist_tmp = cell( 1, MAX_CELL );
    
    % loop through all the cells.
    for i = 1:num_im
        data_c = loaderInternal([dirname,contents(i  ).name]);            
        if CONST.show_status
            waitbar(i/num_im,h,['Make Neighbor List--Frame: ',num2str(i),'/',num2str(num_im)]);
        else
            disp([header, 'Make Neighbor List. frame: ',num2str(i),' of ',num2str(num_im)]);
        end

        for j = 1:data_c.regs.num_regs
           ID = data_c.regs.ID(j);      
           if ID
               neigh = data_c.regs.ID( makenat(data_c.regs.neighbors{j}) );
               neigh = neigh(logical(neigh));
               if ID > MAX_CELL
                   clist_tmp{ ID } = [neigh];
               else
                    clist_tmp{ ID } = [clist_tmp{ID}, neigh];
               end
           end
        end
        
        
    end
    
    % save the updated err files.
    if CONST.show_status
        close(h);
    end
    
   
end
end

function data = loaderInternal( filename )
data = load( filename );
end