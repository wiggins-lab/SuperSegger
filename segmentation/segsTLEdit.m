function [saved_touch_list] = segsTLEdit( dirname, frame_num, CONST )
% segsTLEdit : used to visually modify segments in a frame.
% red are segments that are on, bad are the segments that are off and green
% the permanent segments. 
% Possible choices : q to quit
%                    press the enter button to select a segment to modify
%                    s to save the modified segments
%                    g#: go to frame #
%                    1, 2, 3, & 4 are different image modes
%                    c  clear figure
%
% INPUT :
%       dirname : xy/seg directory
%       frame_num : initial frame number to be loaded
%
% OUTPUT :
%       final_touch_list : frames that were modified
%       
%
% Copyright (C) 2016 Wiggins Lab 
% Written by Paul Wiggins.
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



if ~exist('disp_flag');
    disp_flag = 0;
end

touch_list = [];
saved_touch_list = [];
if(nargin<1 || isempty(dirname))
    dirname=pwd;
end
dirname = fixDir(dirname);

contents=dir([dirname '*_seg.mat']);
num_im = length(contents);
im_flag = 1;
runFlag = 1;

if nargin < 2
    i = 1;
else
    i = frame_num;
end


data = loaderInternal([dirname,contents(i).name]);
ss = size( data.segs.phaseMagic );

while runFlag
    
    data.mask_cell   = double((data.mask_bg - data.segs.segs_good - ...
        data.segs.segs_3n)>0);
    
    showSegData( data,im_flag);
    figure(1);
    hold on;
    disp('--- Segment Editing ---');
    disp('q       : quit');
    disp('[enter] : modify');
    disp('s       : save' );
    disp('g#      : go to frame #');
    disp('1,2,3,4 : different image modes');
    disp('c       : clear the figure');
    disp(['Frame #: ', num2str(i)] );
    
    c = input(':','s')
    
    if isempty(c)
        x = floor(ginput(1));
        tmp = zeros(ss);
        if isempty(x)
            continue;
        end
        
        tmp(x(2),x(1)) = 1;
        tmp = 8000-double(bwdist(tmp));
        
        %imshow( tmp, [] );
        
        tmp = tmp.*(data.segs.segs_good+data.segs.segs_bad);
        [~,ind] = max( tmp(:) );
        [sub1, sub2] = ind2sub( ss, ind );
        ii = data.segs.segs_label(sub1,sub2);
        plot( sub2, sub1, 'r.' );
        
        yymin = floor(data.segs.props(ii).BoundingBox(2));
        yymax = yymin + floor(data.segs.props(ii).BoundingBox(4));
        xxmin = floor(data.segs.props(ii).BoundingBox(1));
        xxmax = xxmin + floor(data.segs.props(ii).BoundingBox(3));
        
        if data.segs.score(ii)
            data.segs.score(ii) = 0;
            data.segs.segs_good(yymin:yymax, xxmin:xxmax) ...
                = double(~~(data.segs.segs_good(yymin:yymax, xxmin:xxmax)...
                - double(data.segs.segs_label(yymin:yymax, xxmin:xxmax)==ii)));
            data.segs.segs_bad(yymin:yymax, xxmin:xxmax) = ...
                double(~~(data.segs.segs_bad(yymin:yymax, xxmin:xxmax)...
                +double(data.segs.segs_label(yymin:yymax, xxmin:xxmax)==ii)));
            
        else
            data.segs.score(ii) = 1;
            data.segs.segs_good(yymin:yymax, xxmin:xxmax) = ...
                double(~~(data.segs.segs_good(yymin:yymax, xxmin:xxmax)+...
                double(data.segs.segs_label(yymin:yymax, xxmin:xxmax)==ii)));
            data.segs.segs_bad(yymin:yymax, xxmin:xxmax) = ...
                double(~~(data.segs.segs_bad(yymin:yymax, xxmin:xxmax)-...
                double(data.segs.segs_label(yymin:yymax, xxmin:xxmax)==ii)));
        end
        
        % recalculate regions and cell mask
        data.mask_cell = double((data.mask_bg - data.segs.segs_good - data.segs.segs_3n)>0);
        data = intMakeRegs(data, CONST, [], [])
        touch_list = [touch_list, i];
        
    elseif c(1) == 'q' % quit
        
        runFlag = 0  ;
        
    elseif c(1) == 'g' % go to frame c(2:end)
        
        i = str2num(c(2:end));
        if i<1
            i = 1;
        elseif i> num_im
            i = num_im;
        end
        
        data = loaderInternal([dirname,contents(i).name]);
        data.mask_cell = double((data.mask_bg - data.segs.segs_good - data.segs.segs_3n)>0);
        
    elseif c == 's' % save
        if any(touch_list==i)
            saved_touch_list = unique([saved_touch_list,i]);
        end
        dataname=[dirname,contents(i).name];
        save(dataname,'-STRUCT','data');
        
    elseif c == '1' % image mode 1
        im_flag = 1;
        
    elseif c == '2'
        im_flag = 2;
        
    elseif c == '3'        
        im_flag = 3;
        
    elseif c == '4'
        im_flag = 4;
        
    elseif c == 'c' % clear figure
        clf;
    end
    
    
end

touch_list = unique(touch_list);

end

function data = loaderInternal( filename )

data = load(filename);
data.segs.segs_good = double(data.segs.segs_label>0).*double(~data.mask_cell);
data.segs.segs_bad = double(data.segs.segs_label>0).*data.mask_cell;

end