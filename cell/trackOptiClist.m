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

dirseperator = filesep;
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
    
    if CONST.show_status
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
    
    % loop through all the cells.
    for i = 1:num_im
        data_c = loaderInternal([dirname,contents(i  ).name]);
        % record the number of cell neighbors
        if CONST.trackOpti.NEIGHBOR_FLAG && ...
                ~isfield( data_c.CellA{1}, 'numNeighbors' )
            for ii = 1:data_c.regs.num_regs
                nei_ = numel(trackOptiNeighbors(data_c,ii));
                data_c.CellA{ii}.numNeighbors = nei_ ;
            end
        end
        
        
        % align locus positionsto old (positive) and new (negative) pole
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
        
        
        lold(    IDlog) = clist_tmp(IDnz,8);
        lbirth(  IDlog) = clist_tmp(IDnz,7);
        
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
        
        l11_L1    = drill( data_c.CellA, '.locus1(1).longaxis' );
        l11_L2    = drill( data_c.CellA, '.locus1(1).shortaxis' );
        l11_s     = drill( data_c.CellA, '.locus1(1).score' );
        l11_i     = drill( data_c.CellA, '.locus1(1).intensity' );
        
        l12_L1    = drill( data_c.CellA, '.locus1(2).longaxis' );
        l12_L2    = drill( data_c.CellA, '.locus1(2).shortaxis' );
        l12_s     = drill( data_c.CellA, '.locus1(2).score' );
        l12_i     = drill( data_c.CellA, '.locus1(2).intensity' );
        
        l13_L1    = drill( data_c.CellA, '.locus1(3).longaxis' );
        l13_L2    = drill( data_c.CellA, '.locus1(3).shortaxis' );
        l13_s     = drill( data_c.CellA, '.locus1(3).score' );
        l13_i     = drill( data_c.CellA, '.locus1(3).intensity' );
        
        l14_L1    = drill( data_c.CellA, '.locus1(4).longaxis' );
        l14_L2    = drill( data_c.CellA, '.locus1(4).shortaxis' );
        l14_s     = drill( data_c.CellA, '.locus1(4).score' );
        l14_i     = drill( data_c.CellA, '.locus1(4).intensity' );
        
        l15_L1    = drill( data_c.CellA, '.locus1(5).longaxis' );
        l15_L2    = drill( data_c.CellA, '.locus1(5).shortaxis' );
        l15_s     = drill( data_c.CellA, '.locus1(5).score' );
        l15_i     = drill( data_c.CellA, '.locus1(5).intensity' );
        
        da1_i     = drill(data_c.regs.daughterID,'(1)');
        da2_i     = drill(data_c.regs.daughterID,'(2)');
        
        l1_Lsc    = (2*l11_L1)./drill( data_c.CellA, '.length(1)' );
        l2_Lsc    = (2*l12_L1)./drill( data_c.CellA, '.length(1)' );
        l3_Lsc    = (2*l13_L1)./drill( data_c.CellA, '.length(1)' );
        l4_Lsc    = (2*l14_L1)./drill( data_c.CellA, '.length(1)' );
        l5_Lsc    = (2*l15_L1)./drill( data_c.CellA, '.length(1)' );
        
        l1_lsc    = (2*l11_L2)./drill( data_c.CellA, '.length(2)' );
        l2_lsc    = (2*l12_L2)./drill( data_c.CellA, '.length(2)' );
        l3_lsc    = (2*l13_L2)./drill( data_c.CellA, '.length(2)' );
        l4_lsc    = (2*l14_L2)./drill( data_c.CellA, '.length(2)' );
        l5_lsc    = (2*l15_L2)./drill( data_c.CellA, '.length(2)' );
        
        l1_w      = drill( data_c.CellA,'.locus1(1).b');
        l2_w      = drill( data_c.CellA,'.locus1(2).b');
        l3_w      = drill( data_c.CellA,'.locus1(3).b');
        
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
            l11_L1',...
            l11_L2',...
            l11_s',...
            l11_i',...
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
        
        if CONST.show_status
            waitbar(i/num_im,h,['Clist--Frame: ',num2str(i),'/',num2str(num_im)]);
        else
            disp([header, 'Clist frame: ',num2str(i),' of ',num2str(num_im)]);
        end
        
        
    end
    
    if CONST.show_status
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