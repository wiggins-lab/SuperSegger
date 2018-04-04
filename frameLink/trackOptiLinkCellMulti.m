function trackOptiLinkCellMulti (dirname,clean_flag,CONST,header,...
    debug_flag,startFrom)
% trackOptiLinkCellMulti : links the cells frame-to-frame and resolves errors.
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

if ~exist('debug_flag','var') || isempty( debug_flag )
    debug_flag = 0;
end

if ~exist('clean_flag','var') || isempty( clean_flag )
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

if startFrom == -1
    % this is the re-link flag - don't delete any err files!
elseif clean_flag || startFrom == 0
    % deletes all err files and starts from 0
    if numel(contents) ~=0
        delete([dirname,'*err.mat'])
    end
elseif startFrom~=0 && numel(contents2)>startFrom
    % starts from startFrom frame, and deletes extra err frame files
    time = startFrom;
    dataLast = load([dirname,contents2(time).name]);
    cell_count = max(dataLast.regs.ID);
    for xx = startFrom:numel(contents2)
        delete([dirname,contents2(xx).name])
    end
    disp (['starting from time : ', num2str(time)]);
elseif ~isempty(contents2)
    % continues from wherever it stopped if startFrom is 0
    time = numel(contents2);
    if time > 1
        disp (['continuing from where I stopped - time : ', num2str(time)]);
        dataLast = load([dirname,contents2(end-1).name]);
        cell_count = max(dataLast.regs.ID);
    end
end

resetRegions = 0;
finalIteration = 0;
maxIterPerFrame = 3;
curIter = 1;

if CONST.parallel.show_status
    h = waitbar( 0, 'Linking.');
    cleanup = onCleanup( @()( delete( h ) ) );
else
    h = [];
end

while time <= numIm
    
    if CONST.parallel.show_status
        waitbar((numIm-time)/numIm,h,['Linking -- Frame: ',num2str(time),'/',num2str(numIm)]);
    end
    if verbose
        disp (['Linking for frame ', num2str(time)])
    end
    
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
        data_f = updateRegionFields (data_f,CONST);
    end
    
    datacName = [dirname,contents(time).name];
    data_c = intDataLoader (datacName);
    [data_r,data_f,c_map,c_manual_link] = transferManualLinks (...
        data_c,data_r,data_f,resetRegions);

    data_c = updateRegionFields (data_c,CONST);
    data_c.regs.map = c_map;
    data_c.regs.manual_link = c_manual_link;
    % Last cellID of previous frame to reset numbering if a frame is repeated.
    lastCellCount = cell_count;  
    
    if ~isempty(data_r)
        [data_r.regs.map.f,data_r.regs.error.f,data_r.regs.cost.f,...
            data_r.regs.idsC.f,data_r.regs.idsF.f,data_r.regs.dA.f,...
            data_r.regs.revmap.f] = assignmentFun (data_r, data_c,CONST,1,0);
    end
    [data_c.regs.map.r,data_c.regs.error.r,data_c.regs.cost.r,...
        data_c.regs.idsC.r,data_c.regs.idsR.r,data_c.regs.dA.r,...
        data_c.regs.revmap.r]  = assignmentFun (data_c, data_r,CONST,0,0);
    [data_c.regs.map.f,data_c.regs.error.f,data_c.regs.cost.f,...
        data_c.regs.idsC.f,data_c.regs.idsF.f,data_c.regs.dA.f,...
        data_c.regs.revmap.f] = assignmentFun (data_c, data_f,CONST,1,0);
    
    % Only allow to repeat each frame error up to maxIterPerFrame.
    if curIter >= maxIterPerFrame
        finalIteration = 1;
    end
    
    % Error resolution and ID assignment.
    [data_c,data_r,cell_count,resetRegions] = errorRez (time, data_c, ...
        data_r, data_f, CONST, cell_count,header, finalIteration, debug_flag);
    curIter = curIter + 1;
        
    if resetRegions
        if verbose
            disp (['Frame ', num2str(time), ' : segments were reset to resolve error, repeating frame.']);
        end
        cell_count = lastCellCount; % Reset back to lastCellCount.
        data_c.regs.ID = zeros(1,data_c.regs.num_regs); % Reset cell ids.
    else
        time = time + 1;
        finalIteration = 0;
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
        % It first tries to load the file with extension filt2, if not
        % found it loads the given dataName. Returns empty if neither is found
        
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
