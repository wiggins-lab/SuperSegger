function [clist] = trackOptiClist(dirname,CONST,header)
% trackOptiClist : generates an array called the clist
% which contains non time dependent information for each cell.
% It contains the following : 
%         '1: Cell ID'
%         '2: Cell Birth Time'
%         '3: Cell Division Time'
%         '4: Cell Age'
%         '5: Cell Dist to edge'
%         '6: Old Pole Age'
%         '7: Long Axis Birth'
%         '8: Long Axis Divide'
%         '9: Complete Cell Cycles'
%         '10: Short Axis Birth'
%         '11: Short Axis Divide'
%         '12: Area Birth'
%         '13: Area Divide'
%         '14: fluor1 sum'
%         '15: fluor1 mean'
%         '16: fluor2 sum'
%         '17: fluor2 mean'
%         '18: number of neighbors'
%         '19: locus1_1 longaxis'
%         '20: locus1_1 shortaxis'
%         '21: locus1_1 score'
%         '22: locus1_1 Intensity'
%         '23: mother ID'
%         '24: daughter1 ID'
%         '25: daughter2 ID'
% INPUT :
%       dirname : seg folder eg. maindirectory/xy1/seg
%       CONST : segmentation constants
%       header : string displayed with information
% OUTPUT :
%       clist : array with the above info for each cell in the frame
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

% Get the track file names.
contents=dir([dirname '*_err.mat']);

if isempty( contents )
    clist.data = [];
    clist.def={};
    clist.gate=[];
else
    data_c = loaderInternal([dirname,contents(end).name]);
    MAX_CELL = max(10000, max(data_c.regs.ID) + 100);
    num_im = numel(contents);
    
    if CONST.parallel.show_status
        h = waitbar( 0, 'Making Cells.');
    else
        h = [];
    end
    
    clist = [];
    clist.def = { '1: Cell ID', ...
        '2: Cell Birth Time', ...
        '3: Cell Division Time', ...
        '4: Cell Age', ...
        '5: Cell Dist to edge', ...
        '6: Old Pole Age', ...
        '7: Long Axis Birth', ...
        '8: Long Axis Divide',...
        '9: Complete Cell Cycles',...
        '10: Short Axis Birth', ...
        '11: Short Axis Divide', ...
        '12: Area Birth', ...
        '13: Area Divide', ...
        '14: fluor1 sum', ...
        '15: fluor1 mean', ...
        '16: fluor2 sum', ...
        '17: fluor2 mean', ...
        '18: number of neighbors',...
        '19: locus1_1 longaxis', ...
        '20: locus1_1 shortaxis',...
        '21: locus1_1 score', ...
        '22: locus1_1 Intensity',...
        '23: mother ID',...
        '24: daughter1 ID',...
        '25: daughter2 ID'...
        };
    
    % These definitions will be updated in every frame.
    death_ind = [3,4,8,9,11,13,24,25];
    
    clist_tmp = nan( MAX_CELL, numel( clist.def) );
    clist_tmp(:,1) = 0;
    
    % initialize in case neighbor flag is not set
    share_pole = [];
    
