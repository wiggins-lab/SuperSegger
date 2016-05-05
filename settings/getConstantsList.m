function [possibleConstants] = getConstantsList()
%GETCONSTANTSLIST gets all constants files from the settings directory

FulllocationOfFile = mfilename('fullpath');
fileSepPosition = find(FulllocationOfFile==filesep,1,'last');
filepath = FulllocationOfFile ( 1 :fileSepPosition-1);
possibleConstants = dir([filepath,filesep,'*.mat']);

for i = 1 : numel (possibleConstants)
    cName = possibleConstants (i).name;
    possibleConstants(i).resFlag =cName (1:end-4);
end

end

