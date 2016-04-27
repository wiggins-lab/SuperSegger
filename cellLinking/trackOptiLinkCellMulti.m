function trackOptiLinkCellMulti (dirname,clean_flag,CONST,header,debug_flag)
% trackOptiCellLink : links the cells frame-to-frame and resolves errors.
%
% INPUT :
%       dirname    : seg folder eg. maindirectory/xy1/seg
%       clean_flag : remove all *err.mat files and start linking again
%       CONST      : SuperSeggerOpti set parameters
%       header     : displayed string
%       debug_flag  : a flag set for displaying the results
%
% Copyright (C) 2016 Wiggins Lab
% University of Washington, 2016
% This file is part of SuperSeggerOpti.


if(nargin<1 || isempty(dirname))
    dirname=uigetdir();
end

dirname = fixDir(dirname);

if ~exist('debug_flag','var') || isempty( debug_flag );
    debug_flag = 0;
end

if ~exist('clean_flag','var') || isempty( clean_flag );
    clean_flag = 0;
end


if ~exist('header','var')
    header = [];
end



filt = '*seg.mat'; % files loaded
filt2 = 'err.mat'; % name of final files


%multiAssignmentPairs
   
assignmentFun = CONST.trackOpti.linkFun;
contents=dir([dirname,filt]);
numIm = length(contents);
cell_count = 0;
time = 1;
contents2=dir([dirname,'*',filt2]);

if clean_flag
    delete([dirname,'*err.mat'])
elseif ~isempty(contents2)
    time = numel(contents2);
    if time > 1
        disp (['continuing from where I stopped - time : ', num2str(time)]);
        delete([dirname,contents2(end).name])
        dataLast = load([dirname,contents2(end-1).name]);
        cell_count = max(dataLast.regs.ID);
    end
end

resetRegions  = 0;

while time <= numIm
    
    if (time == 1)
        data_r = [];
    else
        datarName = [dirname,contents(time-1).name];
        data_r = intDataLoader (datarName);
    end
    
    if (time == numIm)
        data_f = [];
    else
        datafName = [dirname,contents(time+1).name];
        data_f = intDataLoader (datafName);
        data_f = updateRegionFields (data_f,CONST);  % make regions
    end
    
    datacName = [dirname,contents(time).name];
    data_c = intDataLoader (datacName);
    data_c = updateRegionFields (data_c,CONST);  % make regions      
    lastCellCount = cell_count; % to reset cellID numbering when frame is repeated
    
    % go through regions in current data
    
    
    disp (['Calculating maping for frame ', num2str(time)])
    if ~isempty(data_r) && ((resetRegions) || (~isfield(data_r.regs,'map') && ~isfield(data_r.regs.map,'f')))
        [data_r.regs.map.f,data_r.regs.error.f,data_r.regs.cost.f,data_r.regs.idsC.f,data_r.regs.idsF.f,data_r.regs.dA.f] = assignmentFun (data_r, data_c,CONST,1,0);
    end
    [data_c.regs.map.r,data_c.regs.error.r,data_c.regs.cost.r,data_c.regs.idsC.r,data_c.regs.idsR.r,data_c.regs.dA.r]  = assignmentFun (data_c, data_r,CONST,0,0);
    [data_c.regs.map.f,data_c.regs.error.f,data_c.regs.cost.f,data_c.regs.idsC.f,data_c.regs.idsF.f,data_c.regs.dA.f] = assignmentFun (data_c, data_f,CONST,1,0);
   
    % error resolution and id assignment
    [data_c,data_r,cell_count,resetRegions] = errorRez (time, data_c, data_r, data_f, CONST, cell_count,header, debug_flag);
    
    
    if resetRegions
        disp (['Frame ', num2str(time), ' : segments were reset to resolve error, repeating frame.']);
        cell_count = lastCellCount;
        data_c.regs.ID = zeros(1,data_c.regs.num_regs); % reset cell ids
    else
        time = time + 1;
    end
    
    if ~isempty(data_r)
        dataname=[datarName(1:end-7),filt2];
        save(dataname,'-STRUCT','data_r');
    end
    
    dataname=[datacName(1:end-7),filt2];
    save(dataname,'-STRUCT','data_c');
    
end


    function data = intDataLoader (dataName)
        % intDataLoader : loads the data files.
        % if first tries to load the fiele ending with filt2, if it doesn't find it
        % it loads the dataName given, and if that is not found either it
        % return empty.
        
        dataNameMod = [dataName(1:end-7),filt2];
        fidMod = fopen(dataNameMod);
        fid = fopen(dataName);
        
        if  fidMod ~= -1
            data = load(dataNameMod);
        elseif  fid ~= -1
            data = load(dataName);
        else
            data = [];
        end
        fclose('all');
    end

end
