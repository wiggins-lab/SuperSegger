
resFlag = '100XEc'

if strcmp (resFlag,'60XEc')
    ConstLoaded = load('60XEcnn_FULLCONST.mat');
elseif strcmp (resFlag,'100XEc')
    ConstLoaded = load('100XEcnn_FULLCONST.mat');
elseif strcmp (resFlag,'60XEcLB')
    ConstLoaded = load('60XEcLBnn_FULLCONST.mat');
elseif strcmp (resFlag,'60XBay')
    ConstLoaded = load('60XBaynn_FULLCONST.mat');
elseif strcmp (resFlag,'100XPa')
    ConstLoaded = load('100xPann_FULLCONST.mat');
elseif strcmp (resFlag,'60XPa')
    ConstLoaded = load('60XPann_FULLCONST.mat');
else
    error('loadConstants: Constants not loaded : no match found. Aborting.');
end

name = '60XBaynn_FULLCONST.mat';


name = '60XEcnn_FULLCONST.mat'
name = '100XEcnn_FULLCONST.mat'


name = '60XEcLBnn_FULLCONST.mat'


name = '60xPann_FULLCONST.mat'

ConstLoaded = load(name);
 ConstLoaded.regionScoreFun.names = @getRegNames3;
 save(name,'-struct','ConstLoaded' );


name = '100xPann_FULLCONST.mat'

ConstLoaded = load(name);
 ConstLoaded.regionScoreFun.names = @getRegNamesPseud;
 save(name,'-struct','ConstLoaded' );
 
 
% [~,CONST.regionScoreFun.NUM_INFO] = getRegNames3;
% CONST.regionScoreFun.names = getRegNames3;
% CONST.regionScoreFun.fun = @scoreNeuralNet;
% CONST.regionScoreFun.props = @cellprops3;