function [data,touch_list] = updateTrainingImage (data, FLAGS, x)
% updateTrainingImage : user can click on segments or regions to change score
% from 0 to 1 or vice versa. It updates scores, cell mask, good and bad
% segs.
%
% INPUT :
%       data : data file with segments to be modified
%       FLAGS : im_flag = 1 for segments, 2 for regions.
% INPUT :
%       data : data file with modified segments
%       touch_list : list with modified segments/regions
%
% Copyright (C) 2016 Wiggins Lab
% Written by Paul Wiggins, Stella Stylianidou.
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

im_flag = FLAGS.im_flag ;
touch_list = [];
ss = size(data.phase);

x = round(x);
%%
x = intFixPos(x,ss);


if ~isempty(x)
    
    if FLAGS.whichButton == FLAGS.EdgeToggleRadioButtonFlag;
        %% in toggle mode
        
        % creates an image of 51 x 51 of gaussian like point
        tmp = zeros([51,51]);
        tmp(26,26) = 1;
        tmp = 8000-double(bwdist(tmp));
        
        rmin = max([1,x(2)-25]);
        rmax = min([ss(1),x(2)+25]);
        
        cmin = max([1,x(1)-25]);
        cmax = min([ss(2),x(1)+25]);
        
        rrind = rmin:rmax;
        ccind = cmin:cmax;
        
        pointSize = [numel(rrind),numel(ccind)];
        
        
        if im_flag == 1
            
            segs = data.segs.segs_good(rrind,ccind) + ...
                data.segs.segs_bad(rrind,ccind);
            segs = segs>0;
            tmp = tmp(26-x(2)+rrind,26-x(1)+ccind).*segs ;
            
            [~,ind] = max( tmp(:) );
            
            % indices in point image for max / closest segment
            [sub1, sub2] = ind2sub( pointSize, ind );
            
            % closest segments id
            ii = data.segs.segs_label(rmin+sub1-1,cmin+sub2-1);
            
            if ii ~=0
                
                % xx and yy are the segments coordinates
                [xx,yy] = getBB( data.segs.props(ii).BoundingBox );
                
                if data.segs.score(ii) % score is 1
                    data.segs.score(ii) = 0; % set to 0
                    data.segs.segs_good(yy,xx) ...
                        = double(~~(data.segs.segs_good(yy,xx)...
                        - double(data.segs.segs_label(yy,xx)==ii)));
                    data.segs.segs_bad(yy,xx) = ...
                        double(~~(data.segs.segs_bad(yy,xx)...
                        +double(data.segs.segs_label(yy,xx)==ii)));
                else
                    data.segs.score(ii) = 1;
                    data.segs.segs_good(yy,xx) = ...
                        double(~~(data.segs.segs_good(yy,xx)+...
                        double(data.segs.segs_label(yy,xx)==ii)));
                    data.segs.segs_bad(yy,xx) = ...
                        double(~~(data.segs.segs_bad(yy,xx)-...
                        double(data.segs.segs_label(yy,xx)==ii)));
                end
                
                % updates cell mask
                data.mask_cell = double((data.mask_bg - data.segs.segs_good - data.segs.segs_3n)>0);
                data.regs.regs_label = bwlabel(data.mask_cell);
                touch_list = [touch_list, ii];
            end
        elseif im_flag == 2
            tmp = tmp(26-x(2)+rrind,26-x(1)+ccind).*data.mask_cell(rrind,ccind);
            try
                [~,ind] = max( tmp(:) );
            catch ME
                printError(ME);
            end
            
            [sub1, sub2] = ind2sub( pointSize, ind );
            ii = data.regs.regs_label(sub1-1+rmin,sub2-1+cmin);
            plot( sub2-1+cmin, sub1-1+rmin, 'g.' );
            
            if ii
                data.regs.score(ii) = ~data.regs.score(ii);
            end
        end
        
        
    elseif FLAGS.whichButton == FLAGS.RemoveCellRadioButtonFlag
        %% Remove cell option
        
        ii = data.regs.regs_label(x(2),x(1));
        
        if ii
            data.mask_bg(data.regs.regs_label==ii) = 0;
            touch_list = [touch_list, ii];
            
        end
        intDoUpdate
        
        
    elseif FLAGS.whichButton == FLAGS.BackgroundRadioButtonFlag
        %% Background option
        
        data.mask_bg(x(2),x(1)) = false;
        intDoUpdate
        
    elseif FLAGS.whichButton == FLAGS.CellMaskRadioButtonFlag
        %% Cell Mask option
        
        data.mask_bg(x(2),x(1)) = true;
        intDoUpdate
    end
    
    
end

% updates cell mask
    function intDoUpdate
        ws = data.segs.segs_good + data.segs.segs_3n + data.segs.segs_bad;
        data_p = defineGoodSegs(data, ws, FLAGS.CONST, true );
        
        data =  intMapEdges( data_p, data );
        
        data.mask_cell = double((data.mask_bg - data.segs.segs_good - data.segs.segs_3n)>0);
        data.regs.regs_label = bwlabel(data.mask_cell);
        
        
    end
end




function data = intMapEdges( data_p, data )


ns = numel( data_p.segs.score );

for ii = 1:ns
    
    ind = unique(data.segs.segs_label( data_p.segs.segs_label==ii ));
    ind = ind(logical(ind));
    
    if ~isempty( ind )
        data_p.segs.score(ii) = data.segs.score(ind(1));
    end
end

data = data_p;

end