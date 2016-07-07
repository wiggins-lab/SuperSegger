% fix constants

name = '100Xec';
CONST = loadConstants(name);
CONST.seg.segScoreInfo = @segInfoL2;
save(name,'-struct','CONST');