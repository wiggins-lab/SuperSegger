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
    
    % loop through all .err fileså
    for i = 1:num_im
        data_c = loaderInternal([dirname,contents(i).name]);
        % record the number of cell neighbors
        if CONST.trackOpti.NEIGHBOR_FLAG && ...
                ~isfield( data_c.CellA{1}, 'numNeighbors' )
            for ii = 1:data_c.regs.num_regs
                nei_ = numel(trackOptiNeighbors(data_c,ii));
                data_c.CellA{ii}.numNeighbors = nei_ ;
            end
        end
        
        
        % align locus positions to old (positive) and new (negative) pole
        if isfield(CONST.trackOpti,'pole_flag') && CONST.trackOpti.pole_flag == 1
            data_c = getNeighborPole(data_c) ;
            share_pole = drill( data_c.CellA, '.neighbor_pole');
            data_c = poleDirection(data_c);
        end
        
        % figure out which cells are new born.
        maxID = max( clist_tmp(:,1) );
        ID = data_c.regs.ID;
        bci = (ID>maxID);
        ci = and( ~bci, logical(ID) );
        
        IDnz = ID(ID>0);
        IDlog = ID>0;
        
        lold     = nan(1,numel(ID));
        lbirth   = nan(1,numel(ID));
        dlmaxOld = nan(1,numel(ID));
        dlminOld = nan(1,numel(ID));
        
        
        lold(IDlog) = clist_tmp(IDnz,8);
        lbirth(IDlog) = clist_tmp(IDnz,7);
        
        regnum = (1:data_c.regs.num_regs)';
        zz = zeros( data_c.regs.num_regs, 1);
        
        cell_dist = drill( data_c.CellA, '.cell_dist');
        pole_age  = drill( data_c.CellA, '.pole.op_age');
        fl1       = drill( data_c.CellA, '.fl1.sum' );
        fl2       = drill( data_c.CellA, '.fl2.sum' );
        Area      = drill( data_c.CellA, '.coord.A' );
        xpos      = drill( data_c.CellA, '.coord.rcm(1)' );
        ypos      = drill( data_c.CellA, '.coord.rcm(2)' );
        nei       = drill( data_c.CellA, '.numNeighbors');
        gray      = drill( data_c.CellA, '.gray');
        
        locus1_L1 = drill( data_c.CellA, '.locus1(1).longaxis' );
        locus1_L2 = drill( data_c.CellA, '.locus1(1).shortaxis' );
        locus1_score = drill( data_c.CellA, '.locus1(1).score' );
        locus1_int = drill( data_c.CellA, '.locus1(1).intensity' );
        
        locus2_L1 = drill( data_c.CellA, '.locus1(2).longaxis' );
        locus2_L2 = drill( data_c.CellA, '.locus1(2).shortaxis' );
        locus2_score = drill( data_c.CellA, '.locus1(2).score' );
        l12_int = drill( data_c.CellA, '.locus1(2).intensity' );
        
        locus3_L1    = drill( data_c.CellA, '.locus1(3).longaxis' );
        locus3_L2    = drill( data_c.CellA, '.locus1(3).shortaxis' );
        locus3_score     = drill( data_c.CellA, '.locus1(3).score' );
        locus3_int     = drill( data_c.CellA, '.locus1(3).intensity' );
        
        locus4_L1 = drill( data_c.CellA, '.locus1(4).longaxis' );
        locus4_L2 = drill( data_c.CellA, '.locus1(4).shortaxis' );
        locus4_score = drill( data_c.CellA, '.locus1(4).score' );
        locus4_int = drill( data_c.CellA, '.locus1(4).intensity' );
        
        locus5_L1 = drill( data_c.CellA, '.locus1(5).longaxis' );
        locus5_L2 = drill( data_c.CellA, '.locus1(5).shortaxis' );
        locus5_s = drill( data_c.CellA, '.locus1(5).score' );
        locus5_i = drill( data_c.CellA, '.locus1(5).intensity' );
        
        da1_i = drill(data_c.regs.daughterID,'(1)');
        da2_i = drill(data_c.regs.daughterID,'(2)');
        
        locus1_relL1 = (.5*locus1_L1)./drill( data_c.CellA, '.length(1)' );
        locus2_relL1 = (.5*locus2_L1)./drill( data_c.CellA, '.length(1)' );
        locus3_relL1 = (.5*locus3_L1)./drill( data_c.CellA, '.length(1)' );
        locus4_relL1 = (.5*locus4_L1)./drill( data_c.CellA, '.length(1)' );
        locus5_relL1 = (.5*locus5_L1)./drill( data_c.CellA, '.length(1)' );
        
        locus1_relL2 = (.5*locus1_L2)./drill( data_c.CellA, '.length(2)' );
        locus2_relL2 = (.5*locus2_L2)./drill( data_c.CellA, '.length(2)' );
        locus3_relL2 = (.5*locus3_L2)./drill( data_c.CellA, '.length(2)' );
        locus4_relL2 = (.5*locus4_L2)./drill( data_c.CellA, '.length(2)' );
        locus5_relL2 = (.5*locus5_L2)./drill( data_c.CellA, '.length(2)' );
        
        locus1_fitSimga = drill( data_c.CellA,'.locus1(1).fitSigma');
        locus2_fitSigma = drill( data_c.CellA,'.locus1(2).fitSigma');
        locus3_fitSigma = drill( data_c.CellA,'.locus1(3).fitSigma');
        
        if CONST.trackOpti.LYSE_FLAG
            
            errorColor1Cum = data_c.regs.lyse.errorColor1Cum;
            errorColor2Cum = data_c.regs.lyse.errorColor2Cum;
            errorShapeCum  = data_c.regs.lyse.errorShapeCum;
            
            errorColor1bCum = data_c.regs.lyse.errorColor1bCum;
            errorColor2bCum = data_c.regs.lyse.errorColor2bCum;
        else
            errorColor1Cum  = nan(size(ID));
            errorColor2Cum  = nan(size(ID));
            errorShapeCum   = nan(size(ID));
            
            errorColor1bCum = nan(size(ID));
            errorColor2bCum = nan(size(ID));
        end
        
        
        tmp = [ ID', ...
            i + zz, ...
            i + zz, ...
            i - data_c.regs.birth', ...
            cell_dist', ...
            pole_age', ...
            data_c.regs.L1', ...
            data_c.regs.L1', ...
            data_c.regs.stat0', ...
            data_c.regs.L2', ...
            data_c.regs.L2', ...
            Area',...
            Area',...
            fl1',...
            fl1'./Area',...
            fl2',...
            fl2'./Area',...
            nei',...
            locus1_L1',...
            locus1_L2',...
            locus1_score',...
            locus1_int',...
            data_c.regs.motherID',...
            da1_i',...
            da2_i'...
            ];
        
        % these are the guys that are set at birth
        try
            clist_tmp( ID(bci), : ) = tmp( bci, :);
        catch ME
            printError(ME);
        end
        % update the fields that are set to be updated every frame
        clist_tmp( ID(ci), death_ind ) = tmp( ci, death_ind );
        
        if CONST.parallel.show_status
            waitbar(i/num_im,h,['Clist--Frame: ',num2str(i),'/',num2str(num_im)]);
        else
            disp([header, 'Clist frame: ',num2str(i),' of ',num2str(num_im)]);
        end
        
        
    end
    
    if CONST.parallel.show_status
        close(h);
    end
        
    clist.data = clist_tmp(logical(clist_tmp(:,1)),:);
    clist.gate = CONST.trackLoci.gate;
    clist.neighbor = [];
    
    if CONST.trackOpti.NEIGHBOR_FLAG
        clist.neighbor = trackOptiListNeighbor(dirname,CONST,[]);
    end
end

end

function data = loaderInternal( filename )
data = load( filename );
end