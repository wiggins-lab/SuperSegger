function [data] = regionOpti( data, dispp, CONST,header)
% regionOpti : Segmentaion optimization using region characteristics.
% It turns off on and off segments using a systematic method, or simulated
% anneal, according to the number of segments to be considered.
% if the number of segments are more than MAX_NUM_RESOLVE
% it uses the rawScore
% if the number of segments are more than MAX_NUM_SYSTEMATIC
% it runs simulated anneal
% and if it is below that it uses a systematic function.
%
% INPUT :
%       data : data with segs field (.err data or .trk data)
%       dissp : display flag
%       CONST : segmentation constants
%       header : information string
% OUTPUT :
%       data : data structure with modified segments
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

MAX_WIDTH          = CONST.regionOpti.MAX_WIDTH;
MAX_LENGTH         = CONST.regionOpti.MAX_LENGTH;
CutOffScoreHi      = CONST.regionOpti.CutOffScoreHi;
CutOffScoreLo      = CONST.regionOpti.CutOffScoreLo;
MAX_NUM_RESOLVE    = CONST.regionOpti.MAX_NUM_RESOLVE;
MAX_NUM_SYSTEMATIC = CONST.regionOpti.MAX_NUM_SYSTEMATIC;
DE_norm            = CONST.regionOpti.DE_norm;

if ~exist('header')
    header = [];
end

if nargin < 2 || isempty('dispp');
    dispp = 1;
end


% Turn on and off segs outside the cutoff.
segs_label = data.segs.segs_label;
segs_3n    = data.segs.segs_3n;
segs_bad   = 0*data.segs.segs_3n;
segs_good  = segs_bad;
segs_good_off  = segs_bad;
ss = size(segs_3n);
num_segs_ = numel(data.segs.score);
above_Hi_ind = find(data.segs.scoreRaw > CutOffScoreHi);
below_Lo_ind = find(data.segs.scoreRaw < CutOffScoreLo);
segs_3n = segs_3n + double(ismember(segs_label, above_Hi_ind));
segs_bad = double(ismember(segs_label, below_Lo_ind));
segs_label(logical(segs_3n+segs_bad)) = 0;

% Find short regions and add surrounding segments to the stack
mask_regs = double((data.mask_bg-segs_3n)>0);
regs_label =  (bwlabel( mask_regs, 4 ));
regs_props = regionprops( regs_label, 'BoundingBox','Orientation' );
num_regs   = max( regs_label(:));
segs_added = [];
disp([header, 'rO: Got ',num2str(num_regs),' regions.']);

for ii = 1:num_regs
    
    [xx,yy] = getBBpad(regs_props(ii).BoundingBox,ss,2);
    tmp_mask = (regs_label(yy,xx)==ii);
    [L1,L2] = makeRegionSizeProjectionBBint2( tmp_mask, regs_props(ii) );
    debug_flag = 0;
    
    if debug_flag
        clf
        imshow( cat(3,ag(regs_label==ii),ag(regs_label>0),ag(data.phase)), [])
        disp([num2str(L1),', ',num2str(L2)]);
        keyboard;
    end
    
    
    if L1 < MAX_LENGTH;
        tmp_mask = imdilate(tmp_mask, strel('square',3));
        tmp_added = unique( tmp_mask.*data.segs.segs_label(yy,xx).*segs_3n(yy,xx));
        tmp_added = tmp_added(logical(tmp_added));
        tmp_added = reshape(tmp_added,1,numel(tmp_added));
        segs_added = [segs_added,tmp_added];
    end
    
end



% all segments above the high cutoff are added to segs_3n
% (which are the hard segments, ie always on) and the segmentss below the
% low cutoff were added to segs_bad, and removed from the local copy of
% segs_label.
segs_added = unique(segs_added);
segs_added_ = ismember( data.segs.segs_label, segs_added);
segs_3n(segs_added_) = 0;
segs_label(segs_added_) = data.segs.segs_label(segs_added_);


% mask_regs is the super mask of all boundaries + segments that are
% permanently on
mask_regs = double((data.mask_bg-segs_3n)>0);
regs_label = (bwlabel( mask_regs, 4 )); % labels these regions.
regs_props = regionprops( regs_label, 'BoundingBox','Orientation'  );
num_regs   = max( regs_label(:));

rs_list = cell(1,num_regs);

ss = size(data.phase);

for ii = 1:num_regs
    [xx,yy] = getBBpad(regs_props(ii).BoundingBox,ss,2);
    cell_mask = (regs_label(yy,xx) == ii);
    
    % get the names of the remaining segments that are in this region.
    segs_list = unique( cell_mask.*segs_label(yy,xx));
    
    % get rid of zero and make sure the thing is a row vector.
    segs_list = segs_list(logical(segs_list));
    segs_list = reshape(segs_list,1,numel(segs_list));
    
    rs_list{ii} = segs_list;
    
    
    % If there are too many regions to resolve, turn the highest as
    % scores on as predicted by seg scores
    
    
    
    % Turn on segments who would help resolve cells that are too wide
    % First turn everything on in the seg_list and check to make sure that
    % the regions are small enough.
    tmp_segs = cell_mask;
    
    
    tmp_segs = cell_mask-ismember( segs_label(yy,xx),segs_list );
    tmp_segs = double(tmp_segs>0);
    tmp_label = (bwlabel( tmp_segs, 4 ));
    tmp_props = regionprops( tmp_label, 'BoundingBox','Orientation'  );
    num_tmp   = max( tmp_label(:));
    
    segs_added = [];
    
    for ff = 1:num_tmp
        
        tmp_mask = (tmp_label==ff);
        [L1,L2] = makeRegSize( tmp_mask, tmp_props(ff) );
        
        if L2 > MAX_WIDTH;
            tmp_added = unique( tmp_mask.*data.segs.segs_label(yy,xx));
            tmp_added = tmp_added(logical(tmp_added));
            tmp_added = reshape(tmp_added,1,numel(tmp_added));
            segs_added = [segs_added,tmp_added];
        end
    end
    
    segs_list = unique([segs_list,segs_added]);
    
    if isempty(segs_list)
        [vect] = [];
    elseif numel(segs_list) > MAX_NUM_RESOLVE % use raw score
        disp([header, 'rO: Too many regions to analyze (',num2str(numel(segs_list)),').']);
        [vect] = data.segs.scoreRaw(segs_list)>0;
    elseif numel(segs_list) > MAX_NUM_SYSTEMATIC % use simulated anneal
        disp([header, 'rO: Simulated Anneal (',num2str(numel(segs_list)),').']);
        debug_flag = 0;
        
        if debug_flag
            CONST.regionOpti.Emax          = 1e2;
            CONST.regionOpti.fignum        = 2;
            CONST.regionOpti.dt            = 25;
            CONST.regionOpti.Nt            = 256;
            tic;
            [vect] = simAnnealFast( segs_list, data, ...
                cell_mask, xx, yy, CONST, debug_flag);
            toc
            
            CONST.regionOpti.Emax          = 1e2;
            CONST.regionOpti.fignum        = 3;
            CONST.regionOpti.dt            = 25;
            CONST.regionOpti.Nt            = 256;
            tic;
            [vect] = simAnneal( segs_list, data, ...
                cell_mask, xx, yy, CONST, debug_flag);
            toc
            
            pause;
        else
            [vect] = simAnnealFast( segs_list, data, ...
                cell_mask, xx, yy, CONST, debug_flag);
        end
    else % use systematic
        [vect] = systematic( segs_list, data, cell_mask, xx, yy, CONST);
    end
    
    num_segs = numel(segs_list);
    
    try
        segs_good(yy,xx)     = segs_good(yy,xx)     + ismember( data.segs.segs_label(yy,xx), segs_list(logical(vect)));
        segs_good_off(yy,xx) = segs_good_off(yy,xx) + ismember( data.segs.segs_label(yy,xx), segs_list(~vect));
    catch ME
        printError(ME);
    end
    
end

data.mask_cell = double((data.mask_bg-segs_3n-segs_good)>0);


% reset the seg scores incase you want to use this with segsManage
segs_on_ind = unique((~data.mask_cell).*data.segs.segs_label);
segs_on_ind = segs_on_ind(logical(segs_on_ind));
data.segs.score(segs_on_ind) = 1;
segs_off_ind = unique((data.mask_cell).*data.segs.segs_label);
segs_off_ind = segs_off_ind(logical(segs_off_ind));
data.segs.score(segs_off_ind) = 0;
cell_mask = data.mask_cell;
data.segs.segs_good   = double(data.segs.segs_label>0).*double(~data.mask_cell);
data.segs.segs_bad   = double(data.segs.segs_label>0).*data.mask_cell;



if dispp
    back = double(0.7*ag( data.phase ));
    outline = imdilate( cell_mask, strel( 'square',3) );
    outline = ag(outline-cell_mask);
    segs_never = ((segs_bad-segs_good_off-segs_good)>0);
    segs_tried = ((segs_good_off + segs_good)>0);
    
    try
        clf
        imshow(uint8(cat(3,back + 1.00*double(outline),...
            back + 0.3*double(ag(segs_tried)),...
            back + 0.3*double(ag(segs_tried)).*double(segs_good_off) + 0.2*double(ag(~cell_mask)-outline) + 0.5*double(ag(segs_never)))));
    catch ME
        printError(ME);
    end
    drawnow;
    
end
end


function vect = makeVector( nn, n )
vect = zeros(1,n);
for i=n-1:-1:0;
    vect(i+1) = floor(nn/2^i);
    nn = nn - vect(i+1)*2^i;
end

end



function vect = systematic( segs_list, data, cell_mask, xx, yy, CONST)


debug_flag = 0;

num_segs = numel(segs_list);
num_comb = 2^num_segs;

regionScore = zeros( 1, num_comb );
ss = size(data.phase);

for jj = 1:num_comb;
    
    vect = makeVector(jj-1,num_segs);
    
    
    %make mask;
    cell_mask_mod = cell_mask;
    
    for kk = 1:num_segs
        
        cell_mask_mod = cell_mask_mod - vect(kk)*(segs_list(kk)==data.segs.segs_label(yy,xx));
    end
    
    
    regs_label_mod = (bwlabel( cell_mask_mod, 4 ));
    tmp2_props = regionprops( regs_label_mod, 'BoundingBox','Orientation','Centroid','Area');
    num_regs_mod = max(regs_label_mod(:));
    
    info = zeros(num_regs_mod, CONST.regionScoreFun.NUM_INFO);
    
    ss_regs_label_mod = size( regs_label_mod );
    
    for mm = 1:num_regs_mod;
        
        [xx_,yy_] = getBBpad( tmp2_props(mm).BoundingBox, ss_regs_label_mod, 1);
        
        try
            mask = regs_label_mod(yy_,xx_)==mm;
        catch ME
            printError(ME);
        end
        
        try
            info(mm,:) = CONST.regionScoreFun.props( mask, tmp2_props(mm)  );
        catch ME
            disp('Big error!');
            printError(ME);
        end
        
        if debug_flag
            disp(['reg ', num2str(mm), ' sc ', num2str(CONST.regionScoreFun.fun(info(mm,:),CONST.regionScoreFun.E))]);
        end
    end
    
    
    regionScore(jj) = sum(-CONST.regionScoreFun.fun(info,CONST.regionScoreFun.E))+...
        sum((1-2*vect).*FixE(data.segs.scoreRaw(segs_list)'))*CONST.regionOpti.DE_norm;
    
    if debug_flag
        clf;
        imshow( cat(3,autogain(cell_mask)*.25+autogain(cell_mask_mod)*.25,...
            autogain(cell_mask)*.25+autogain(cell_mask_mod)*.25,...
            autogain(cell_mask)*.25+autogain(cell_mask_mod)*.25),'InitialMagnification','fit');
        
        regionScore(jj)
        
    end
    
end

[min_score, jj_min] = min(regionScore);
vect = makeVector(jj_min-1,num_segs);

%         if dispp
%         clf;
%         imshow( cat(3,autogain(mask_regs)*.25+autogain(regs_label==ii)*.25,...
%             autogain(mask_regs)*.25+autogain(mask_regs==ii)*.25,...
%             autogain(mask_regs)*.25+autogain(mask_regs==ii)*.25));
%
%         end
end


function vect = simAnnealFast( segs_list, data, cell_mask, xx, yy, CONST, debug_flag)
% simAnneal: Find the minimum energy configuration by a simulated
% anneal procedure.

if ~exist('debug_flag', 'var') || isempty( debug_flag )
    debug_flag = 0;
end

ss = size(data.phase);
num_segs = numel(segs_list);


if isfield( CONST.regionOpti, 'ADJUST_FLAG' ) && CONST.regionOpti.ADJUST_FLAG
    Nt = floor(CONST.regionOpti.Nt * num_segs/10);
else
    Nt = CONST.regionOpti.Nt;
end


% state vector contains all the info about the current state
state = [];

% turn on the segs that are predicted to be on based on the seg scores
% computed by superSeggerOpti.

vect = data.segs.scoreRaw(segs_list)>0;
E = initState( vect );
recMap = containers.Map( makeKey( vect ), E );

if debug_flag
    EHist = zeros(1,Nt);
    tttt = 1:Nt;
    stateMat = zeros(num_segs,Nt);
end

%debugFig

for t = 1:Nt;
    
    T = tempSchedule(t,CONST,num_segs);
    
    E0 = E;
    
    % perturb configuration
    nn = floor(rand*num_segs)+1;
    vect_tmp = state.seg_vect0;
    vect_tmp(nn) = ~vect_tmp(nn);
    
    key = makeKey(vect_tmp);
    if isKey(recMap, key)
        keyFlag = 1;
        E = recMap(key);
    else
        keyFlag = 0;
        E = perturbState(nn);
        recMap(key) = E;
    end
    
    DE = E0-E;
    
    if rand > exp( DE/T )
        % Throw away perturbed state
        E = E0;
    else
        % Fix pertrubed state
        if keyFlag
            perturbState(nn);
        end
        fixState();
    end
    
    if debug_flag
        EHist(t) = E;
        stateMat(:,t) = state.seg_vect0;
    end
    
    %     %%%%%%%%%%% debug %%%%%%%%%%%%%%
    % clf;
    % plot(accept_vect,'.-');
    %
    %
    %
    %         cell_mask_mod = 0*cell_mask;
    %         for kk = 1:num_segs
    %             cell_mask_mod = cell_mask_mod + vect(kk)*(segs_list(kk)==data.segs.segs_label(yy,xx));
    %         end
    %
    %          clf;
    %          imshow( cat(3,autogain(cell_mask)*.25+autogain(cell_mask_mod)*0.25,...
    %              autogain(cell_mask)*.25+autogain(cell_mask_mod_)*0.25,...
    %              autogain(cell_mask)*.25+autogain(cell_mask_mod)*0),'InitialMagnification','fit');
    %
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
end


%debugFig

vect = double(state.seg_vect0');


if debug_flag
    [minEHist,ppp] = min(EHist(end:-1:1));
    ppp = numel(EHist)-ppp+1;
    minEHist
    
    figure(CONST.regionOpti.fignum);
    clf;
    subplot(2,1,1);
    imagesc( stateMat );
    
    subplot(2,1,2);
    semilogy(tttt,EHist-minEHist+1,'r.-');
    hold on;
    semilogy(tttt(ppp),1,'go');
end



    function E = initState( vect0 )
        
        state.seg_E = FixE(data.segs.scoreRaw(segs_list))*CONST.regionOpti.DE_norm;
        state.seg_vect0 = logical(vect0);
        state.seg_mask= cell (1, num_segs  );
        state.mask_out= cell (1, num_segs  );
        state.seg_vect1= logical(vect0);
        state.reg_E= zeros(1, num_segs+3);
        state.reg_vect0= false(1, num_segs+3);
        state.reg_mask= cell (1, num_segs+3);
        state.reg_label= [];
        state.reg_props= [];
        state.reg_vect1= false(1, num_segs+3);
        state.mask= [];
        state.ss= 0;
        
        % make the new modified mask based on the seg state vector
        state.mask = cell_mask;
        
        for kk = 1:num_segs
            state.seg_mask{kk} = (segs_list(kk)==data.segs.segs_label(yy,xx));
            state.mask_out{kk} = bwmorph( state.seg_mask{kk}, 'dilate' );
            if vect0(kk)
                state.mask(state.seg_mask{kk}) = false;
            end
        end
        
        % label the regs
        state.reg_label = bwlabel( state.mask, 8 );
        state.reg_props  = regionprops( state.reg_label, ...
            'BoundingBox','Orientation','Area');
        
        num_regs_mod   = max(state.reg_label(:));
        
        state.ss = size(state.reg_label);
        
        % loop through the regs
        kk_range = 1:num_regs_mod;
        state.reg_vect0(kk_range) = 1;
        state.reg_vect1 = state.reg_vect0;
        for kk = kk_range;
            [xx_,yy_] = getBBpad( state.reg_props(kk).BoundingBox, state.ss, 0);
            state.reg_mask{kk} = (state.reg_label==kk);
            info = CONST.regionScoreFun.props( state.reg_mask{kk}(yy_,xx_), state.reg_props(kk)  );
            state.reg_E(kk) = CONST.regionScoreFun.fun(info,CONST.regionScoreFun.E);
        end
        for kk = (num_regs_mod+1):(num_segs+3)
            state.reg_mask{kk} = false(state.ss);
        end
        
        E = calcE(state.reg_vect0, state.seg_vect0, state);
        
        
        %debugFig;
    end

    function E = perturbState( nn )
        
        state.seg_vect1 = state.seg_vect0;
        state.reg_vect1 = state.reg_vect0;
        
        % if the boundary chosen is on, figure out which regions
        % are neighboring.
        if state.seg_vect0(nn)
            %disp( ['Turn off seg ',num2str(nn)] );
            state.seg_vect1(nn) = false;
            ind0 = unique(state.reg_label(state.mask_out{nn}))';
            ind0 = ind0(logical(ind0));
            state.reg_vect1(ind0) = false;
            
            ind1 = find( ~state.reg_vect0, 1, 'first' );
            state.reg_vect1(ind1) =  true;
            try
                state.reg_mask{ind1} = state.seg_mask{nn};
            catch ME
                printError(ME);
            end
            for kk = ind0
                state.reg_mask{ind1} = ...
                    or(state.reg_mask{ind1}, state.reg_mask{kk});
            end
            reg_props_tmp = regionprops( double(state.reg_mask{ind1}), ...
                'BoundingBox','Orientation','Area');
            
            [xx_,yy_] = getBBpad( reg_props_tmp.BoundingBox, state.ss, 0);
            
            info = CONST.regionScoreFun.props( state.reg_mask{ind1}(yy_,xx_), reg_props_tmp(1)  );
            state.reg_E(ind1) = ...
                CONST.regionScoreFun.fun(info,CONST.regionScoreFun.E);
            
            %disp( 'Remove reg: ');
            %ind0
            
            %disp( 'Add reg: ');
            %ind1
            
            
            
            
        else
            % if the boundary is off, pick out the region to be split
            
            %disp( ['Turn on seg ',num2str(nn)] );
            state.seg_vect1(nn) = true;
            ind0 = unique(state.reg_label(state.seg_mask{nn}));
            
            %disp( 'Remove region:' );
            %ind0
            
            mask_tmp = xor( state.seg_mask{nn}, state.reg_mask{ind0(1)});
            
            reg_label_tmp = bwlabel( mask_tmp, 8 );
            reg_props_tmp = regionprops( reg_label_tmp, ...
                'BoundingBox','Orientation','Area');
            
            ind_tmp = unique(reg_label_tmp( mask_tmp ))';
            ind_tmp = ind_tmp(logical(ind_tmp));
            ind1 = [];
            for kk = ind_tmp
                ind1 = [ind1, find( ~state.reg_vect1, 1, 'first' )];
                state.reg_mask{ind1(end)} = (reg_label_tmp==kk);
                state.reg_vect1(ind1(end)) = true;
                state.reg_props(ind1(end)) = reg_props_tmp(kk);
                [xx_,yy_] = getBBpad( reg_props_tmp(kk).BoundingBox, state.ss, 0);
                info = CONST.regionScoreFun.props( state.reg_mask{ind1(end)}(yy_,xx_), reg_props_tmp(kk)  );
                state.reg_E(ind1(end)) = ...
                    CONST.regionScoreFun.fun(info,CONST.regionScoreFun.E);
            end
            state.reg_vect1(ind0) = false;
            
            %disp('Add region: ');
            %ind1
        end
        
        E = calcE(state.reg_vect1, state.seg_vect1, state);
        
        %debugFig;
    end

    function debugFig
        
        L = zeros(state.ss);
        SegGood0 = L;
        SegBad0  = L;
        SegGood1 = L;
        SegBad1  = L;
        RegOnOn  = L;
        RegOnOff = L;
        RegOffOn = L;
        
        Lreg = L;
        
        for kk = 1:num_segs
            L(state.seg_mask{kk}) = kk;
            if state.seg_vect0(kk)
                SegGood0(state.seg_mask{kk}) = 1;
            else
                SegBad0(state.seg_mask{kk}) = 1;
            end
            if state.seg_vect1(kk)
                SegGood1(state.seg_mask{kk}) = 1;
            else
                SegBad1(state.seg_mask{kk}) = 1;
            end
        end
        
        for kk = 1:num_segs+3
            if state.reg_vect0(kk);
                Lreg(state.reg_mask{kk}) = kk;
            end
            
            if state.reg_vect0(kk) && ~state.reg_vect1(kk)
                RegOnOff(state.reg_mask{kk}) = ...
                    RegOnOff(state.reg_mask{kk}) + 1;
            end
            
            if ~state.reg_vect0(kk) && state.reg_vect1(kk)
                RegOffOn(state.reg_mask{kk}) = ...
                    RegOffOn(state.reg_mask{kk}) + 1;
            end
            
            if state.reg_vect0(kk) && state.reg_vect1(kk)
                RegOnOn(state.reg_mask{kk}) = ...
                    RegOnOn(state.reg_mask{kk}) + 1;
            end
            
        end
        
        seg_props = regionprops( L, 'Centroid' );
        reg_props = regionprops( Lreg, 'Centroid' );
        
        
        
        figure(1);
        clf;
        
        backer = 0.2*ag(data.phase(yy,xx));
        
        imshow( cat(3,backer+0.3*ag(SegGood0),backer+0.15*ag(logical(Lreg)),...
            backer+0.3*ag(SegBad0)),'InitialMagnification','fit');
        hold on;
        
        
        
        for kk = 1:num_segs
            
            cc = double(and(state.seg_vect0(kk),state.seg_vect1(kk)))*[1 1 1] + ...
                double(and(~state.seg_vect0(kk),state.seg_vect1(kk)))*[0 0 1] + ...
                double(and(state.seg_vect0(kk),~state.seg_vect1(kk)))*[1 0 0];
            
            text( seg_props(kk).Centroid(1), seg_props(kk).Centroid(2), ...
                num2str(kk), 'Color', cc );
        end
        
        
        for kk = 1:num_segs+3
            
            cc = [0 1 0];
            if state.reg_vect0(kk);
                text( reg_props(kk).Centroid(1), reg_props(kk).Centroid(2), ...
                    num2str(kk), 'Color', cc );
            end
            
            
        end
        
        figure(2);
        clf;
        imshow( cat(3,backer+0.3*ag(RegOffOn),backer+0.3*ag(RegOnOn),...
            backer+0.3*ag(RegOnOff)),'InitialMagnification','fit');
        hold on;
        
        for kk = 1:num_segs
            
            cc = double(and(state.seg_vect0(kk),state.seg_vect1(kk)))*[1 1 1] + ...
                double(and(~state.seg_vect0(kk),state.seg_vect1(kk)))*[0 0 1] + ...
                double(and(state.seg_vect0(kk),~state.seg_vect1(kk)))*[1 0 0];
            
            text( seg_props(kk).Centroid(1), seg_props(kk).Centroid(2), ...
                num2str(kk), 'Color', cc );
        end
        
        
        for kk = 1:num_segs+3
            
            cc = [0 1 0];
            if state.reg_vect0(kk);
                text( reg_props(kk).Centroid(1), reg_props(kk).Centroid(2), ...
                    num2str(kk), 'Color', cc );
            end
            
            
        end
        
        figure(3);
        clf;
        
        imshow( state.reg_label, [], 'InitialMagnification','fit');
        colormap hot;
        
    end




    function str = makeKey( vect )
        % HashMap function
        str = char(double(vect)'+'a');
    end

    function fixState ( )
        % fixState function fixes the perturbed state as the current state.
        %disp( 'Fix Region' );
        
        %disp( 'Deleting: ');
        ind_del = find(and(state.reg_vect0,~state.reg_vect1));
        for kk = ind_del
            state.reg_label(state.reg_mask{kk}) = 0;
            state.mask(state.reg_mask{kk})      = false;
        end
        
        %disp( 'Adding: ');
        ind_add = find(and(state.reg_vect1,~state.reg_vect0));
        for kk = ind_add
            state.reg_label(state.reg_mask{kk}) = kk;
            state.mask(state.reg_mask{kk})      = true;
        end
        
        state.reg_vect0 = state.reg_vect1;
        state.seg_vect0 = state.seg_vect1;
        
        %debugFig();
    end
end








function E = calcE(reg_vect,seg_vect,state)
E = sum(-state.reg_E(reg_vect))+sum((1-2*double(seg_vect)).*state.seg_E);
end


function    T = tempSchedule(t, CONST, num_segs)

if isfield( CONST.regionOpti, 'ADJUST_FLAG' ) && CONST.regionOpti.ADJUST_FLAG
    dt   = CONST.regionOpti.dt*10/num_segs;
else
    dt   = CONST.regionOpti.dt;
end

Emax = CONST.regionOpti.Emax;

T = Emax*exp(-t/dt);
end

function ee = FixE( ee )
%global CutOffScoreHi;
%global CutOffScoreLo;


%cutH = 5*CutOffScoreHi;
%cutL = 5*CutOffScoreLo;

%ee = ee.*(ee<=cutH).*(ee>=cutL) + cutH.*(ee>cutH) + cutL.*(ee<cutL);

end

