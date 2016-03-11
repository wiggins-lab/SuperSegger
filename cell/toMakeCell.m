function celld = toMakeCell(celld, e1_old, props)
% toMakeCell : calls toMakeCellFast to calculate the properties of a cell.
%
% INPUT : 
%       celld : Cell file
%       e1_old : is the last axis of the cell
%       props : contains information about the cell such as bounding box, area,
%       and centroid 
% OUTPUT :
%       celld : new cell file with calculated properties
%
% Copyright (C) 2016 Wiggins Lab 
% Unviersity of Washington, 2016
% This file is part of SuperSeggerOpti.



celld = toMakeCellFast( celld, e1_old, props);

end