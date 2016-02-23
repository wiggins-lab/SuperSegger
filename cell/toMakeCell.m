function celld = toMakeCell(celld, e1_old, props)
% toMakeCell calls toMakeCellFast to calculates the properties of the cell.
%
% INPUT : 
%       celld : Cell file
%       props : contains information about the cell such as bounding box, area,
%       and centroid 
%       e1_old : is the last axis of the cell
% OUTPUT :
%        celld : new cell file with calculated properties
% Copyright (C) 2016 Wiggins Lab 
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.



celld = toMakeCellFast( celld, e1_old, props);

end