function [map, XX] = intDoHardLinkDel( map, XX, DA, CONST )
% intDoHardLinkDel : hard links the regions that uniquely overlap.
% if one of the regions maps uniquely to a region, and none of the
% others do, it hard maps the region.
%
% INPUT :
%       map: contains region numbers for mapping in the order of amount of overlap 
%       XX : is a map of overlap scores and indices of overlap 
%           XX{ii}(1,:) overlap score calculated as area of overlap / the max
%           of the areas of the two regions
%           XX{ii}(2,:) incides of regions overlaping with ii 
%       DA : difference in the areas / max of the two areas
%       CONST :  Segmentation Constants
% OUTPUT :
%       map : new region mappings
%       XX : map of scores and regions
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

DA_MIN = CONST.trackOpti.DA_MIN;
DA_MAX = CONST.trackOpti.DA_MAX;
area_logic = and(DA > DA_MIN, DA < DA_MAX );
ind_c      = find( area_logic );
ind_r      = drill( map(ind_c), '(1)' );

% keep only ind_c/ind_r that map to regions in r
map_ind_r_log = (ind_r>0);
ind_c0      = ind_c(map_ind_r_log);
ind_r0      = ind_r(map_ind_r_log);

% make a protected list of regions that cannot be hard linked.
nMap = numel(map);
ind_r_pro = zeros(1,nMap);
ind_c_pro = zeros(1,nMap);
npro = 0;

for ii = 1:nMap
    % don't subtract if it is already in the list
    if (numel(map{ii}) == 1) && ~area_logic(ii)
       npro = npro + 1;
       ind_r_pro(npro) = map{ii};
       ind_c_pro(npro) = ii;
    end
end

ind_r_pro = ind_r_pro(1:npro);
ind_c_pro = ind_c_pro(1:npro);

% remove protected indices
include_ind = ~ismember( ind_r0, ind_r_pro );
ind_c = ind_c0(include_ind);
ind_r = ind_r0(include_ind);

% make a list of unique r regions
[ind_r_unique,ind_ind_r_first,c1] = unique( ind_r,'first' );
[ind_r_unique,ind_ind_r_last, c2] = unique( ind_r,'last'  );

% ind_c_hard corresponds to the list for mapped c regions. Initially just
% set it equal to the first occurance of the region r in the map.
ind_c_hard    = ind_c(ind_ind_r_first);

% make a list of r regions that are repeated. If they are repeated, the
% first and last instance will not be equal.
repeated_ind_r   = ind_r_unique(ind_ind_r_first~=ind_ind_r_last);

% if two regions in the current frame map with no area change to the
% reverse frame, (i) first check to see if one of those cells 
% only map to a single cell.
nrr = numel( repeated_ind_r );

% make a new version of repeated_ind_r to remove elements from.
list_remove = [];
for ii = 1:nrr
   % get all the c region numbers that map to repeated_ind_r(ii) 
   ind_c_m = ind_c(find( repeated_ind_r(ii) == ind_r ));
   
   % find the index of this r region in the list of unique r regions
   ind_ind_r_unique = find( repeated_ind_r(ii) == ind_r_unique);
   
   % make a list of the number of r regions that each c region maps to. 
   nn = [];
   for jj = ind_c_m
       nn = [nn, numel(map{jj})];
   end
   
   % sort this list so that the smallest number of mapped regions occur and
   % the beginning of the list
   [nn,ord] = sort( nn, 'ascend' );
   
   % if one of the c regions maps uniquely to this region, but none of the
   % others do, hard map the c and r regions. if not, do nothing.
   if (nn(1) == 1) && (nn(2) ~= 1)       
        ind_c_hard(ind_ind_r_unique) = ind_c_m(ord(1));        
        % remove this r region from the list of repeated r regions
        list_remove = [list_remove, repeated_ind_r(ii)];
   end
end

% reset repeated_ind_r to the shortened version
repeated_ind_r = repeated_ind_r( ~ismember(repeated_ind_r, list_remove));

% (ii) choose the one that has the best overlap.
nrr = numel( repeated_ind_r );
for ii = 1:nrr
    
   % get all the c region numbers that map to repeated_ind_r(ii)  
   ind_c_m = ind_c(find( repeated_ind_r(ii) == ind_r ));
   
   % find the index of this r region in the list of unique r regions
   ind_ind_r_unique = find( repeated_ind_r(ii) == ind_r_unique );
   
    % find the ind of ind_ind_c_m with the highest overlap
   [max_overlap, ind_ind_c_m] = max( drill(XX(1,ind_c_m),'(1)') );
   
   ind_c_hard(ind_ind_r_unique) = ind_c_m(ind_ind_c_m);
end


% first remove all the links to r regions that have been given a hard link 
% to another c region
nMap = numel( map );
for ii = 1:nMap

    ind = ~ismember( map{ii}, ind_r_unique(ii~=ind_c_hard));
    map{ii} = map{ii}(ind);
    XX{ii}  = XX{ii}(:,ind);
end


% Then set the hard links to only link to one cell.
nindchard = numel( ind_c_hard );
for jj = 1:nindchard    
    ii = ind_c_hard(jj);
    ind_map = find(map{ii}==ind_r_unique(jj));    
    map{ii} = ind_r_unique(jj);
    XX{ii}  = XX{ii}(:,ind_map);
end


end

