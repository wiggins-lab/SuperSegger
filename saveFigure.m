function [ ] = saveFigure ( handle, name, path )
% saves figure in eps, png and fig format

if ~exist('path','var')
    path = '.'
end

figure(handle)
savename = sprintf('%s/%s',path,name);
doPageFormat;
saveas(handle,(savename),'fig');
print(handle,'-depsc',[(savename),'.eps'])
saveas(handle,(savename),'png');


end

