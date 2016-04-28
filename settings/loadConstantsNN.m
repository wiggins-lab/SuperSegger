function CONST = loadConstantsNN( res, PARALLEL_FLAG )
% loadConstants loads the parameters for the superSegger/trackOpti package.
% If you want to customize the constants DO NOT CHANGE
% THIS FILE! Rename this file loadConstantsMine.m and
% put in somehwere in the path.
% That file will load automatically rather than this one.
% When you make loadConstantsMine.m, change
% disp( 'loadConstants: Initializing.')
% to loadConstantsMine to avoid confusion.
%
% INPUT :
%   res : number for resolution of microscope used (60 or 100) for E. coli
%         or use a string as shown below
%   PARALLEL_FLAG : 1 if you want to use parallel computation
%                   0 for single core computation
%
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Stella Stylianidou
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

if nargin < 1 || isempty( res )
    res = 60;
end

if ~exist('PARALLEL_FLAG','var') || isempty( PARALLEL_FLAG )
    PARALLEL_FLAG = false;
end


disp('loadConstants: Initializing.');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                         %
% Specify scope resolution                                                %                                                                       %                                %
%                                                                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Values for setting res
% '60XEc' : loadConstants 60X Ecoli
% '100XEc': loadConstants 100X Ecoli
% '60XEcLB': loadConstants 60X Ec LB Ecoli
% '60XBay'
% '60XPa'
% '100XPa' 
% {'60XEc','100XEc','60XEcLB','60XBay','60XPa','100XPa'}



cl = class(res);
resFlag = [];
if strcmp(cl,'double' )  && res == 60
    disp('loadConstants: 60X');
    resFlag = '60XEc';
elseif strcmp(cl,'double' )  && res == 100
    disp('loadConstants:  100X');
    resFlag = '100XEc';
elseif strcmp(cl, 'char' );
    if strcmpi(res,'60XEc') % 1
        resFlag = '60XEc';
    elseif strcmpi(res,'100XEc') % 2
        disp('loadConstants:  100X Ecoli');
        resFlag = '100XEc';
    elseif strcmpi(res,'60XEcLB') % 2
        disp('loadConstants:  60X LB Ecoli');
        resFlag = '60XEcLB';
    elseif strcmpi(res,'60XBay') % 2
        disp('loadConstants:  60X Baylyi');
        resFlag = '60XBay';
     elseif strcmpi(res,'60XPa') % 2
        disp('loadConstants:  60X Pseudemonas');
        resFlag = '60XPa';
    elseif strcmpi(res,'100XPa') % 2
        disp('loadConstants:  100X Pseudemonas');
        resFlag = '100XPa';
    end
end

if strcmp (resFlag,'60XEc')
    CONST = load('60XEcnn_FULLCONST.mat');
elseif strcmp (resFlag,'100XEc')
    CONST = load('100XEcnn_FULLCONST.mat');
elseif strcmp (resFlag,'60XEcLB')
    CONST = load('60XEcLBnn_FULLCONST.mat');
elseif strcmp (resFlag,'60XBay')
    CONST = load('60XBaynn_FULLCONST.mat');
    elseif strcmp (resFlag,'100XPa')
    CONST = load('100xPann_FULLCONST.mat');
    elseif strcmp (resFlag,'60XPa')
    CONST = load('60XPann_FULLCONST.mat');
else
    error('Constants not loaded : no match found. Aborting.');
end

% temp until they are put in the constants
CONST.trackOpti.linkFun = @multiAssignmentFastOnlyOverlap;
CONST.trackOpti.DA_MIN = -0.1;
CONST.trackOpti.DA_MAX = 0.3;
CONST.regionScoreFun.names = getRegNames3;

% Settings for alignment in differnt channels - modify for your microscope
CONST.imAlign.DAPI    = [-0.0354   -0.0000    1.5500   -0.3900];
CONST.imAlign.mCherry = [-0.0512   -0.0000   -1.1500    1.0000];
CONST.imAlign.GFP     = [ 0.0000    0.0000    0.0000    0.0000];

CONST.imAlign.out = {CONST.imAlign.GFP, ...   % c1 channel name
    CONST.imAlign.GFP,...  % c2 channel name
    CONST.imAlign.GFP};        % c3 channel name

                                       

% Parallel processing on multiple cores settings :
if PARALLEL_FLAG
    poolobj = gcp('nocreate'); % If no pool, do not create new one.
    if isempty(poolobj)
        poolobj = parpool('local');
    end
    poolobj.IdleTimeout = 360; % close after idle for 3 hours
    CONST.parallel.parallel_pool_num = poolobj.NumWorkers;
else
    CONST.parallel.parallel_pool_num = 0;
end

CONST.parallel.xy_parallel = 0;
CONST.parallel.PARALLEL_FLAG = PARALLEL_FLAG;
CONST.parallel.show_status   = ~(CONST.parallel.parallel_pool_num);



end
