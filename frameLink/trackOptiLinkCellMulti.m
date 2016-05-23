function trackOptiLinkCellMulti (dirname,clean_flag,CONST,header,debug_flag,startFrom)
% trackOptiCellLink : links the cells frame-to-frame and resolves errors.
%
% INPUT :
%       dirname    : seg folder eg. maindirectory/xy1/seg
%       clean_flag : remove all *err.mat files and start linking again
%       CONST      : SuperSeggerOpti set parameters
%       header     : displayed string
%       debug_flag  : a flag set for displaying the results
%
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou.
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


if ~exist('startFrom','var') || isempty(startFrom)
    startFrom = 0;
end



verbose = CONST.parallel.verbose;
assignmentFun = CONST.trackOpti.linkFun;

filt = '*seg.mat'; % files loaded
filt2 = 'err.mat'; % name of final files
contents=dir([dirname,filt]);
contents2=dir([dirname,'*',filt2]);

if numel(contents) == 0
    numIm = length(contents2);
    contents = contents2;
else
    numIm = length(contents);
end

cell_count = 0;
time = 1;

if clean_flag
    if numel(contents) ~=0
        delete([dirname,'*err.mat'])
    end
elseif startFrom~=0 && numel(contents2)>startFrom
    time = startFrom;
    dataLast = load([dirname,contents2(time).name]);
    cell_count = max(dataLast.regs.ID);
    for xx = startFrom+1:numel(contents2)
        delete([dirname,contents2(xx).name])
    end
    disp (['starting from time : ', num2str(time)]);
elseif ~isempty(contents2)
    time = numel(contents2);
    if time > 1
        disp (['continuing from where I stopped - time : ', num2str(time)]);
        %delete([dirname,contents2(end).name])
        dataLast = load([dirname,contents2(end-1).name]);
        cell_count = max(dataLast.regs.ID);
    end
end


%resetRegions  = 1;
ignoreError = 0;
previousMasks ={};
maxIterPerFrame = 3;
curIter = 1;
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
    
    if verbose
        disp (['Calculating maping for frame ', num2str(time)])
    end
    if ~isempty(data_r) % && ((resetRegions) || (~isfield(data_r.regs,'map') && ~isfield(data_r.regs.map,'f')))
        [data_r.regs.map.f,data_r.regs.error.f,data_r.regs.cost.f,data_r.regs.idsC.f,data_r.regs.idsF.f,data_r.regs.dA.f,data_r.regs.revmap.f] = assignmentFun (data_r, data_c,CONST,1,0);
    end
    [data_c.regs.map.r,data_c.regs.error.r,data_c.regs.cost.r,data_c.regs.idsC.r,data_c.regs.idsR.r,data_c.regs.dA.r,data_c.regs.revmap.r]  = assignmentFun (data_c, data_r,CONST,0,0);
    [data_c.regs.map.f,data_c.regs.error.f,data_c.regs.cost.f,data_c.regs.idsC.f,data_c.regs.idsF.f,data_c.regs.dA.f,data_c.regs.revmap.f] = assignmentFun (data_c, data_f,CONST,1,0);
    
    for x = 1 : numel(previousMasks)
        maskDif = xor(data_c.mask_cell,previousMasks{x});
        if all(maskDif==0)
            ignoreError = 1;
        end
    end
    
    if curIter >= maxIterPerFrame
        ignoreError = 1;
    end
    
    previousMasks  {end+1} = data_c.mask_cell;
    
    % error resolution and id assignment
    [data_c,data_r,cell_count,resetRegions] = errorRez (time, data_c, data_r, data_f, CONST, cell_count,header, ignoreError, debug_flag);
    
    
    if resetRegions
        if verbose
            disp (['Frame ', num2str(time), ' : segments were reset to resolve error, repeating frame.']);
        end
        cell_count = lastCellCount;
        data_c.regs.ID = zeros(1,data_c.regs.num_regs); % reset cell ids
        curIter = curIter + 1;
    else
        time = time + 1;
        previousMasks = {};
        ignoreError = 0;
        curIter = 1;
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
