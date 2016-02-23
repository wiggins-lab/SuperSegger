% setFlagsErRes : sets the error resolution flags

% If there is an area mapping regions to the previous frame
% -> Need to resolve a tracking error
DA_MIN            = CONST.trackOpti.DA_MIN;
DA_MAX            = CONST.trackOpti.DA_MAX;

% project list_r back onto current frame to see what other
% regions are involved in the current frame in resolving the
% error
list_rc    = [];

for mm = list_r;
    try
        ind__ = find(data_r.regs.ol.f{mm}(1,:) > OVERLAP_LIMIT_MIN);
        list_rc = [list_rc, data_r.regs.ol.f{mm}(2,ind__)];
    catch ME
        printError( ME )
    end
end

list_rc = unique(list_rc );
list_rc_other = list_rc(list_rc~=ii);
list_rcf = [];
list_rcf = unique([data_c.regs.map.f{list_rc}]);

try
    list_rcr = unique([data_c.regs.map.r{list_rc}]);
catch
    list_rcr = list_r;
end

% These are the number of regions in the two projections
num_list_r  = numel(list_r);
num_list_rc = numel(list_rc);

try
    AreaChangeFlag = all( data_c.regs.dA.r(list_rc)> dA_LIMIT_ErRes );
catch
    AreaChangeFlag = 0;
end

localMapGoodFlag = and(data_c.regs.DA.r(ii) > DA_MIN,...
    data_c.regs.DA.r(ii) < DA_MAX);


merged_flag = or(data_c.regs.DA.r(ii) < DA_MIN,...
    data_c.regs.DA.r(ii) > DA_MAX ) ...
    && (num_list_r>1) && CONST.trackOpti.MERGED_FLAG && ...
    (num_list_rc == 1);

if num_im == 1
    stray_flag = false;
else
    stray_flag = (~isempty(data_c.regs.ol.r{ii}) && ...
        ~sum( data_c.regs.ol.r{ii}(1,:) )) ...
        || ...
        (~isempty(data_c.regs.ol.f{ii}) && ...
        ~ sum( data_c.regs.ol.f{ii}(1,:) )) ...
        || stray_flag;
end

% check to make sure there are no errors in the map from the
% overlapping regions in the previous frame (list_r) to the
% next frame. Also make sure that the current regions map
% both forward and backwards--ie aren't strays.
try
    fskip_flag = ~isempty(data_f) && ~isempty(data_c.regs.error.rf) && ...
        ~isempty(list_rcr)                   && ...
        ~any(data_c.regs.error.rf(list_rcr)) && ...
        any(data_f.regs.error.r([data_c.regs.map.rf{list_rcr}])) && ...
        any( data_c.regs.ol.f{ii}(1,:) )  && ...
        any( data_c.regs.ol.r{ii}(1,:) )  && ...
        CONST.trackOpti.FSKIP_FLAG;
catch ME
    printError( ME )  
    fskip_flag = false;
end




s21_flag = any(data_c.regs.error.rf(list_r)) && ...
    (num_list_r == 2 ) && ...
    ( num_list_rc == 1);

% to set the 1->2 flag insist that the mapping in 1->2
% and that there is no mapping error in the next frame for the
% prospective daughter cells
% s12_flag =  ~any( data_c.regs.error.f(list_rc) & ...
%     ((data_c.regs.DA.f(list_rc)<CONST.trackOpti.DA_MIN) | ...
%      (data_c.regs.DA.f(list_rc)>CONST.trackOpti.DA_MAX))) && ...
%     (num_list_r ==1 ) && ...
%     ( num_list_rc == 2);


s12_flag =  (numel(list_rcf)>1) && ...
    (num_list_r ==1 ) && ...
    ( num_list_rc > 1);


% cell shift is an error that occurs because cells are pushing each
% other.
cshift_flag = (num_list_r ==1 ) && ( num_list_rc == 1) && ...
    ~isempty( data_c.regs.dA.r(ii) ) && (data_c.regs.dA.r(ii) > dA_LIMIT_ErRes);
try
    split_flag = ((~isempty(data_r) && ...
        (numel(list_r) > 0) && ...
        all(data_r.regs.L2(list_r) < MAX_WIDTH)) ...
        ...
        || (~isempty(data_f) && ...
        (numel(list_f) > 0) && ...
        all(data_f.regs.L2(list_f) < MAX_WIDTH))) ...
        ...
        && (data_c.regs.L2(ii) > MAX_WIDTH);
catch
    keyboard
end



localMapGoodFlagEnd = and(data_c.regs.DA.r(ii) > 2*DA_MIN,...
    data_c.regs.DA.r(ii) < 2*DA_MAX);


rrrrr = 0;


% set to 1 if you want to display the flags
if 0
    disp(['Frame: ', num2str(i), ' seg: ', num2str(ii)] );
    if stray_flag
        disp('Stray');
    elseif cshift_flag
        disp('Shift');
    elseif localMapGoodFlag
        disp('localMapGood');
    elseif merged_flag
        disp('Merge Flag');
    elseif fskip_flag
        disp('Skip 1');
    elseif split_flag
        disp('Split');
    elseif s21_flag
        disp('Stable 2->1');
    elseif s12_flag
        disp('Stable 1->2');
    else
        disp('Unresolved.');
    end
   
    if ~(s12_flag || localMapGoodFlag)
        
        %showDA4( data_c, data_r, data_f);
        rl_c = data_c.regs.regs_label;
        if isempty( data_r )
            rl_r = 0*rl_c;
        else
            rl_r = data_r.regs.regs_label;
        end
        if isempty( data_f )
            rl_f = 0*rl_c;
        else
            rl_f = data_f.regs.regs_label;
        end
        
        
        figure(1);
        clf;
        imshow( uint8(cat( 3, ...
            0.3*ag(rl_r>0)+...
            0.7*ag(ismember(rl_r,list_r)),...
            0.7*double(ag(rl_c==ii))+...
            0.3*double(ag(rl_c>0)),...
            0.0*ag(rl_f>0) )));
        title( 'Red r, Green c');
        drawnow;
        
        figure(2);
        clf;
        imshow( double(rl_r) ...
            - 10*double(rl_r==0), [] );
        colormap jet;
        title( 'Red r');
        
        figure(3);
        clf;
        imshow( double(rl_c) ...
            - 10*double(rl_c==0), [] );
        colormap jet;
        title( 'Green c');
        
        figure(4);
        clf;
        imshow( double(rl_f) ...
            - 10*double(rl_f==0), [] );
        colormap jet;
        title( 'blue f');
        
        disp( ['Frame: ', num2str(i), ' region: ', num2str(ii),'.'] );
        
        '';
    end
end