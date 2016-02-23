function data  = trackOptiIntDiskNR(data,data_r,data_f,CONST)
% trackOptiIntDiskNR : computes the links (or overlaps) between subsequent frames
%
% INPUT :
%       data    : region (cell) data structure
%       data_r  : linked reverse region (cell) data structure
%       data_f  : linked forward region (cell) data structure
%       CONST      : SuperSeggerOpti set parameters
%
%
% OUTPUT :
%       data : updated region (cell) data structure.
%
%           It contains the following updated fields :
%           regs.ol.{r,f,rf,fr}: these are the numerical values for the
%           area overlap between f (forward) and r (reverse) frames. Also
%           makes from f to r and r to f.
%
%           regs.map.{r,f,rf,fr}: these are connections between regions.
%           For instance map.r{i} = [....] is a list of regions that
%           "overlap" over the threshold (OVERLAP_LIMIT_MIN)
%
%           regs.error.{r,f,rf,fr}: these are the error flags that
%           are set if the area change between the largest overlap region
%           is below a cut off (dA_LIMIT) OR that there is more than one
%           linked region that overlaps above cut off... see map. Note
%           that this happens in a successful cell division.
%
%           regs.dA.{r,f,rf,fr}: these area ratios between the largest
%           overlap regions. This is defined as min(A1,A2)/max(A2,A1).
%           We set an error if this gets too large.
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.

[data.regs.ol.f,  data.regs.map.f,  data.regs.error.f,  data.regs.dA.f, ...
    data.regs.DA.f, dF1_f, dF2_f,dF1b_f,dF2b_f]   ...
    = calcRegsInt( data,   data_f, CONST);
[data.regs.ol.r,  data.regs.map.r,  data.regs.error.r,  data.regs.dA.r, ...
    data.regs.DA.r,dF1_r, dF2_r,dF1b_r,dF2b_r] ...
    = calcRegsInt( data,   data_r, CONST);
[data.regs.ol.rf, data.regs.map.rf, data.regs.error.rf, data.regs.dA.rf,...
    data.regs.DA.rf]  ...
    = calcRegsInt( data_r, data_f, CONST);
[data.regs.ol.fr, data.regs.map.fr, data.regs.error.fr, data.regs.dA.fr,...
    data.regs.DA.fr]  ...
    = calcRegsInt( data_f, data_r, CONST);

% keep the forward mapping....
data.regs.dF1  = dF1_f;
data.regs.dF2  = dF2_f;
data.regs.dF1b = dF1b_f;
data.regs.dF2b = dF2b_f;

data.regs.eccentricity = zeros(1,data.regs.num_regs);

data.regs.L1           = zeros(1,data.regs.num_regs);
data.regs.L2           = zeros(1,data.regs.num_regs);

data.regs.contact     = zeros(1,data.regs.num_regs);
data.regs.neighbors   = cell(1,data.regs.num_regs);
data.regs.contactHist = zeros(1,data.regs.num_regs);

data.regs.info      = zeros(data.regs.num_regs,CONST.regionScoreFun.NUM_INFO);
data.regs.scoreRaw  = zeros(1,data.regs.num_regs);


data.regs.death          = zeros(1,data.regs.num_regs); % Death/divide time
data.regs.deathF         = zeros(1,data.regs.num_regs);    % Divides in this frame

data.regs.birth          = zeros(1,data.regs.num_regs); % Birth Time: either
% Division or appearance
data.regs.birthF         = zeros(1,data.regs.num_regs);    % Divide in this frame

data.regs.age            = zeros(1,data.regs.num_regs);    % cell age. starts at 1.
data.regs.divide         = zeros(1,data.regs.num_regs);    % succesful divide in this
% this frame.

data.regs.ehist          = zeros(1,data.regs.num_regs);    % True if cell has an unresolved
% error before this time.

% add lysis detection if lysis flag is set
if CONST.trackOpti.LYSE_FLAG
    data.regs.lyse.errorColor1         = zeros(1,data.regs.num_regs); % Fluor1 intensity change error in this frame
    data.regs.lyse.errorColor1Cum      = zeros(1,data.regs.num_regs); % Cum fluor1 intensity change error
    data.regs.lyse.errorColor2         = zeros(1,data.regs.num_regs); % Fluor2 intensity change error in this frame
    data.regs.lyse.errorColor2Cum      = zeros(1,data.regs.num_regs); % Cum fluor2 intensity change error
    
    data.regs.lyse.errorColor1b         = zeros(1,data.regs.num_regs); % Fluor1 intensity change error in this frame
    data.regs.lyse.errorColor1bCum      = zeros(1,data.regs.num_regs); % Cum fluor1 intensity change error
    data.regs.lyse.errorColor2b         = zeros(1,data.regs.num_regs); % Fluor2 intensity change error in this frame
    data.regs.lyse.errorColor2bCum      = zeros(1,data.regs.num_regs); % Cum fluor2 intensity change error
    
    data.regs.lyse.errorShape          = zeros(1,data.regs.num_regs); % Fluor intensity change error in this frame
    data.regs.lyse.errorShapeCum       = zeros(1,data.regs.num_regs); % Cum intensity change error
end

data.regs.stat0          = zeros(1,data.regs.num_regs);    % Results from a successful
% division.

data.regs.sisterID       = zeros(1,data.regs.num_regs);   % sister cell ID
data.regs.motherID       = zeros(1,data.regs.num_regs);   % mother cell ID
data.regs.daughterID     = cell(1,data.regs.num_regs);   % daughter cell ID
data.regs.ID             = zeros(1,data.regs.num_regs); % cell ID number


data.regs.error.label    = cell(1,data.regs.num_regs);   % err
data.regs.ignoreError    = zeros(1,data.regs.num_regs); % a flag for ignoring the error in a region.
%data.regs.neighbors       = cell(1,data.regs.num_regs);   % err

loop_ind       = 1:data.regs.num_regs;


for ii = loop_ind
    [xx,yy] = getBB(data.regs.props(ii).BoundingBox);
    data.regs.info(ii,:) = CONST.regionScoreFun.props( (data.regs.regs_label(yy,xx)==ii),data.regs.props(ii) );
    data.regs.L1(ii)       = data.regs.info(ii,1);
    data.regs.L2(ii)       = data.regs.info(ii,2);
    data.regs.scoreRaw(ii) = CONST.regionScoreFun.fun(data.regs.info(ii,:),CONST.regionScoreFun.E);
    
    if CONST.trackOpti.NEIGHBOR_FLAG
        try
            data.regs.neighbors{ii} = trackOptiNeighbors(data,ii);
            data.regs.contact(ii)  = numel(data.regs.neighbors{ii});
        catch
            disp('Error in neighbor calculation in trackOptiIntDiskNR.m');
        end
    end
end


data.regs.eccentricity = drill(data.regs.props,'.MinorAxisLength')'...
    ./drill(data.regs.props,'.MajorAxisLength')';

if CONST.trackOpti.LYSE_FLAG

    % Fluor Ratio error is set if Fluor Ratio is less than
    % CONST.trackOpti.FLUOR1_CHANGE_MIN
    data.regs.lyse.errorColor1 = ...
        ( data.regs.dF1 < CONST.trackOpti.FLUOR1_CHANGE_MIN );
    data.regs.lyse.errorColor2 = ...
        ( data.regs.dF2 < CONST.trackOpti.FLUOR2_CHANGE_MIN );
    data.regs.lyse.errorColor1b = ...
        ( data.regs.dF1b < CONST.trackOpti.FLUOR1_CHANGE_MIN );
    data.regs.lyse.errorColor2b = ...
        ( data.regs.dF2b < CONST.trackOpti.FLUOR2_CHANGE_MIN );
    
    % Shape error is defined by having both a eccentricity lower than the
    % limit CONST.trackOpti.ECCENTRICITY and a minor axis length greater
    % than CONST.trackOpti.LSPHEREMIN and smaller than
    % CONST.trackOpti.LSPHEREMAX
    data.regs.lyse.errorShape = ...
        and( (data.regs.eccentricity > CONST.trackOpti.ECCENTRICITY), and(...
        ( drill(data.regs.props,'.MinorAxisLength')' > CONST.trackOpti.LSPHEREMIN ),...
        ( drill(data.regs.props,'.MajorAxisLength')' < CONST.trackOpti.LSPHEREMAX )));
    
end


%toc
end






