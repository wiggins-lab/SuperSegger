function [region_id,x_point,y_point] = getClosestCellToPoint(data,point)
    ss = size(data.phase);
    
    % Creates a square around point that fades away
    tmp = zeros([51,51]);
    tmp(26,26) = 1;
    tmp = 8000-double(bwdist(tmp));
    rmin = max([1,point(2)-25]);
    rmax = min([ss(1),point(2)+25]);
    cmin = max([1,point(1)-25]);
    cmax = min([ss(2),point(1)+25]);
    rrind = rmin:rmax;
    ccind = cmin:cmax;
    pointSize = [numel(rrind),numel(ccind)];
    
    % Multiplies by cell mask
    tmp = tmp(26-point(2)+rrind,26-point(1)+ccind).*data.mask_cell(rrind,ccind);
    
     % Finds maximum value of faded-point & cell mask
    [~,ind] = max(tmp(:));
    [sub1, sub2] = ind2sub(pointSize, ind);
    % Label of the region (cell) for the maximum value.
    region_id = data.regs.regs_label(sub1-1+rmin,sub2-1+cmin);
    x_point = sub2-1+cmin;
    y_point = sub1-1+rmin;
end