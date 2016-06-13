
% super segger documentation

m2html('mfiles','SuperSeggerRelease','save','on','htmldir','doc','recursive','on', 'global','on','ignoredDir',{'z-removed','tryMe'});



filename = 'doc/SuperSeggerRelease'; %// name of generated zip file
list = {'SuperSeggerRelease/license.txt','SuperSeggerRelease/readme.txt','SuperSeggerRelease/Internal','SuperSeggerRelease/batch',...
    'SuperSeggerRelease/cell','SuperSeggerRelease/fluorescence','SuperSeggerRelease/fastRotate',...
    'SuperSeggerRelease/frameLink','SuperSeggerRelease/gate',...
    'SuperSeggerRelease/segmentation','SuperSeggerRelease/settings',...
    'SuperSeggerRelease/trainingConstants','SuperSeggerRelease/viz'}; %// files and folders to be included
zip(filename, list)

zip('doc/SuperSeggerReleaseTryMe', 'SuperSeggerRelease/tryMe')


