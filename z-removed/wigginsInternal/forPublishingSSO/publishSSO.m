
% super segger documentation

m2html('mfiles','SuperSeggerRelease','save','on','htmldir','doc','recursive','on', 'global','on','ignoredDir',{'z-removed','tryMe'});

% load from file
%m2html('load','doc','mfiles','SuperSeggerRelease','htmldir','doc','recursive','on', 'global','on','ignoredDir',{'deprecated'});



filename = 'doc/SuperSeggerRelease'; %// name of generated zip file
list = {'SuperSeggerRelease/Internal','SuperSeggerRelease/batch',...
    'SuperSeggerRelease/cell','SuperSeggerRelease/fluorescence','SuperSeggerRelease/fastRotate',...
    'SuperSeggerRelease/frameLink','SuperSeggerRelease/gate',...
    'SuperSeggerRelease/segmentation','SuperSeggerRelease/settings',...
    'SuperSeggerRelease/trainingConstants','SuperSeggerRelease/viz'}; %// files and folders to be included
%basefolder = 'C:/Simulations'; %// base folder
zip(filename, list)

zip('doc/SuperSeggerReleaseTryMe', 'SuperSeggerRelease/tryMe')

%zip('doc/SuperSeggerRelease','SuperSeggerRelease')



