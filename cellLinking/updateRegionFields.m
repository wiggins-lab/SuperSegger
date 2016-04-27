function data  = updateRegionFields (data,CONST)
% updateRegionFields: computes the reg fields in the seg and err data structure.
% using the cell mask. It also initialized the fields to be used by the 
% linking aglorithm.
%
% INPUT :
%       data    : region (cell) data structure (seg file)
%       CONST   : SuperSeggerOpti set parameters
%
% OUTPUT :
%       data : updated region (cell) data structure with regions field.
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


% create regions
data.regs.regs_label = bwlabel( data.mask_cell );
data.regs.num_regs = max( data.regs.regs_label(:) );
data.regs.props = regionprops( data.regs.regs_label, ...
    'BoundingBox','Orientation','Centroid','Area');
NUM_INFO = CONST.regionScoreFun.NUM_INFO;
data.regs.info = zeros( data.regs.num_regs, NUM_INFO );


% initializing region fields
data.regs.eccentricity = zeros(1,data.regs.num_regs);
data.regs.L1 = zeros(1,data.regs.num_regs);
data.regs.L2 = zeros(1,data.regs.num_regs);
data.regs.contact = zeros(1,data.regs.num_regs);
data.regs.neighbors = cell(1,data.regs.num_regs);
data.regs.contactHist = zeros(1,data.regs.num_regs);
data.regs.info= zeros(data.regs.num_regs,CONST.regionScoreFun.NUM_INFO);
data.regs.scoreRaw = zeros(1,data.regs.num_regs);
data.regs.score = zeros(1,data.regs.num_regs);
data.regs.death = zeros(1,data.regs.num_regs); % Death/division time
data.regs.deathF = zeros(1,data.regs.num_regs); % division in this frame
data.regs.birth = zeros(1,data.regs.num_regs);% Birth Time: either division or appearance
data.regs.birthF = zeros(1,data.regs.num_regs);% division in this frame
data.regs.age = zeros(1,data.regs.num_regs);% cell age. starts at 1.
data.regs.divide = zeros(1,data.regs.num_regs);% succesful division in this frame.
data.regs.ehist = zeros(1,data.regs.num_regs);% True if cell has an unresolved error before this time.
data.regs.stat0 = zeros(1,data.regs.num_regs); %  Successful division.
data.regs.sisterID = zeros(1,data.regs.num_regs);% sister cell ID
data.regs.motherID = zeros(1,data.regs.num_regs);% mother cell ID
data.regs.daughterID = cell(1,data.regs.num_regs);% daughter cell ID
data.regs.ID  = zeros(1,data.regs.num_regs); % cell ID number
data.regs.error.label = cell(1,data.regs.num_regs);% err
data.regs.ignoreError = zeros(1,data.regs.num_regs); % a flag for ignoring the error in a region.


% go through the regions and update info,L1,L2 and scoreRaw.
for ii = 1:data.regs.num_regs
    [xx,yy] = getBB(data.regs.props(ii).BoundingBox);
    mask = data.regs.regs_label(yy,xx)==ii;
    data.regs.info(ii,:) = CONST.regionScoreFun.props(mask,data.regs.props(ii) );
    data.regs.L1(ii)= data.regs.info(ii,1);
    data.regs.L2(ii)= data.regs.info(ii,2);
    data.regs.scoreRaw(ii) = CONST.regionScoreFun.fun(data.regs.info(ii,:),CONST.regionScoreFun.E);
    data.regs.score(ii) = data.regs.scoreRaw(ii)>0;
    if CONST.trackOpti.NEIGHBOR_FLAG
        try
            data.regs.neighbors{ii} = trackOptiNeighbors(data,ii);
            data.regs.contact(ii)  = numel(data.regs.neighbors{ii});
        catch
            disp('Error in neighbor calculation in updateRegionFields.m');
        end
    end
end

data.regs.scoreRaw = CONST.regionScoreFun.fun(data.regs.info, CONST.regionScoreFun.E);
data.regs.score = data.regs.scoreRaw > 0;
data.regs.eccentricity = drill(data.regs.props,'.MinorAxisLength')'...
    ./drill(data.regs.props,'.MajorAxisLength')';



% % add lysis detection if lysis flag is set
% if CONST.trackOpti.LYSE_FLAG
%  data.regs.lyse.errorColor1 = zeros(1,data.regs.num_regs); % Fluor1 intensity change error in this frame
%  data.regs.lyse.errorColor1Cum = zeros(1,data.regs.num_regs); % Cum fluor1 intensity change error
%  data.regs.lyse.errorColor2 = zeros(1,data.regs.num_regs); % Fluor2 intensity change error in this frame
%  data.regs.lyse.errorColor2Cum = zeros(1,data.regs.num_regs); % Cum fluor2 intensity change error
%  data.regs.lyse.errorColor1b = zeros(1,data.regs.num_regs); % Fluor1 intensity change error in this frame
%  data.regs.lyse.errorColor1bCum = zeros(1,data.regs.num_regs); % Cum fluor1 intensity change error
%  data.regs.lyse.errorColor2b = zeros(1,data.regs.num_regs); % Fluor2 intensity change error in this frame
%  data.regs.lyse.errorColor2bCum = zeros(1,data.regs.num_regs); % Cum fluor2 intensity change error
%  data.regs.lyse.errorShape = zeros(1,data.regs.num_regs); % Fluor intensity change error in this frame
%  data.regs.lyse.errorShapeCum = zeros(1,data.regs.num_regs); % Cum intensity change error
% end
% if CONST.trackOpti.LYSE_FLAG
%  % Fluor Ratio error is set if Fluor Ratio is less than
%  % CONST.trackOpti.FLUOR1_CHANGE_MIN
%  data.regs.lyse.errorColor1 = ...
%  ( data.regs.dF1 < CONST.trackOpti.FLUOR1_CHANGE_MIN );
%  data.regs.lyse.errorColor2 = ...
%  ( data.regs.dF2 < CONST.trackOpti.FLUOR2_CHANGE_MIN );
%  data.regs.lyse.errorColor1b = ...
%  ( data.regs.dF1b < CONST.trackOpti.FLUOR1_CHANGE_MIN );
%  data.regs.lyse.errorColor2b = ...
%  ( data.regs.dF2b < CONST.trackOpti.FLUOR2_CHANGE_MIN );
%
%  % Shape error is defined by having both a eccentricity lower than the
%  % limit CONST.trackOpti.ECCENTRICITY and a minor axis length greater
%  % than CONST.trackOpti.LSPHEREMIN and smaller than
%  % CONST.trackOpti.LSPHEREMAX
%  data.regs.lyse.errorShape = ...
%  and( (data.regs.eccentricity > CONST.trackOpti.ECCENTRICITY), and(...
%  ( drill(data.regs.props,'.MinorAxisLength')' > CONST.trackOpti.LSPHEREMIN ),...
%  ( drill(data.regs.props,'.MajorAxisLength')' < CONST.trackOpti.LSPHEREMAX )));
% end

end






