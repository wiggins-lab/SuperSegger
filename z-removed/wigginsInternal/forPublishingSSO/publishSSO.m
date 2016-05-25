
% super segger documentation

m2html('mfiles','SuperSeggerRelease','save','on','htmldir','doc','recursive','on', 'global','on','ignoredDir',{'deprecated'});

% load from file
%m2html('load','doc','mfiles','SuperSeggerRelease','htmldir','doc','recursive','on', 'global','on','ignoredDir',{'deprecated'});



filename = 'doc/SuperSeggerRelease'; %// name of generated zip file
list = {'SuperSeggerRelease/Internal','SuperSeggerRelease/batch',...
    'SuperSeggerRelease/cell','SuperSeggerRelease/fluorescence',...
    'SuperSeggerRelease/frameLink','SuperSeggerRelease/gate',...
    'SuperSeggerRelease/segmentation','SuperSeggerRelease/settings',...
    'SuperSeggerRelease/trainingConstants','SuperSeggerRelease/tryMe','SuperSeggerRelease/viz'}; %// files and folders to be included
%basefolder = 'C:/Simulations'; %// base folder
zip(filename, list)


zip('doc/SuperSeggerRelease','SuperSeggerRelease')
