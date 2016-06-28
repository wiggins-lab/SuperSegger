function [X,Y] =  getInfoScores (dirname, xChoice, CONST)
% getInfoScores : gathers properties and predicted values to be used for
% model training.
%
% INPUT:
%       dirname : directory with seg files
%       xChoice : 'segs' or 'regs' for segments or regions
%       CONST : segmentation constants
% OUPUT :
%       X : properties (info) for segments or regions
%       Y : boolean array with two fields for bad or good segment/region
%
% Copyright (C) 2016 Wiggins Lab
% Written by Stella Stylianidou.
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


dirname = fixDir(dirname);
if ~strcmp (xChoice,'segs') && ~strcmp (xChoice,'regs')
    disp('no x chosen, optimizing segments');
    xChoice = 'segs';
end
if strcmp (xChoice,'segs')
    contents = dir([dirname,'*_seg.mat']);
else
    contents = dir([dirname,'*_seg*.mat']);
end


Y = [];
X = [];

for i = 1 : numel(contents)
    data = load([dirname,contents(i).name]);
    contents(i).name
    if exist('CONST','var')
        data = calculateInfo (data,CONST,xChoice);
        save ([dirname,contents(i).name],'-struct','data');
    end
    
    if strcmp (xChoice,'segs')
        X = [X;data.segs.info];
        Y = [Y;data.segs.score];
       
    else       
        X = [X;data.regs.info];
        Y = [Y;data.regs.score];               
    end
    

    
end

[indices] = find(~isnan(Y));
X = X(indices,:);
Y = Y(indices);

[indices] = find(isfinite(sum(X,2)));
X = X(indices,:);
Y = Y(indices);


    function [data] = calculateInfo (data,CONST,xChoice)
        if strcmp (xChoice,'regs')
            oldInfo = data.regs.info;
            ss = size(data.mask_cell);
            data.regs.regs_label = bwlabel(data.mask_cell);
            data.regs.props = regionprops( data.regs.regs_label,'BoundingBox','Orientation','Centroid','Area');
            data.regs.num_regs = max(data.regs.regs_label(:));
            data.regs.info = [];
            
            for ii = 1:data.regs.num_regs
                [xx,yy] = getBBpad( data.regs.props(ii).BoundingBox, ss, 1);
                mask = data.regs.regs_label(yy,xx)==ii;
                data.regs.info(ii,:) = CONST.regionScoreFun.props( mask, data.regs.props(ii) );
            end
            
            
            
            newInfo = data.regs.info;
            if isempty(newInfo) || all(size (oldInfo)~=size(newInfo))
                error('size')
            elseif all (oldInfo~=newInfo)
                error('hi')
            end
            
        elseif strcmp (xChoice,'segs')
            %ws = ~data.mask_bg+data.segs.segs_3n++data.segs.segs_bad+data.segs.segs_good;
            %phaseNorm = data.segs.phaseNorm;
            %C2phaseThresh = data.segs.phaseC2;
            %A = CONST.superSeggerOpti.A;
            %mask_bg = data.mask_bg;
            %calcScores = 0;
            %[data_tmp] = defineGoodSegs(data, ws, phaseNorm, C2phaseThresh, ...
            %    mask_bg, A, CONST,calcScores);
            
            data = superSeggerOpti( data, [], 0, CONST );
            
%             = data_tmp.segs.info;
%             newScore = data_tmp.segs.score;
            
        end
    end

end


