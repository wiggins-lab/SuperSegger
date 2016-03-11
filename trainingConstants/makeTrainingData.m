function [data,touch_list] = makeTrainingData (data,FLAGS)
% makeTrainingData : user can click on segments or regions to change score
% from 0 to 1 or vice versa. It updates scores, cell mask, good and bad
% segs.


if ~exist('FLAGS','var') ||  ~isfield(FLAGS,'im_flag')
    FLAGS.im_flag  = 1;
end
im_flag = FLAGS.im_flag ;
touch_list = []
ss = size(data.phase);
selectMode = true;

% while goflag
%     
%     figure(1);
%     showSegRule( data, FLAGS )
%     
% %     prompt1 = ' mod to modify segments/regions, q to quit.';
% %     answer = input(prompt1,'s');
% %     if strcmp (answer,'mod')
% %         selectMode = true;
% %     elseif strcmp (answer,'q')
% %         selectMode = false;
% %         goflag = false;
% %     end
    
    while selectMode
        figure(1);
        showSegRule( data, FLAGS )
        disp ('Click on segment/region to modify. To exit press enter while image is selected.');
        x = floor(ginput(1));
        disp(x);
        
        if ~isempty(x)
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
                
                tmp = tmp(26-x(2)+rrind,26-x(1)+ccind).*...
                    (data.segs.segs_good(rrind,ccind) + ...
                    data.segs.segs_bad(rrind,ccind));
                
                [~,ind] = max( tmp(:) );
                
                % indices in point image for max / closest segment
                [sub1, sub2] = ind2sub( pointSize, ind );
                
                % closest segments id
                ii = data.segs.segs_label(rmin+sub1-1,cmin+sub2-1);
                
                if ii ~=0
                    
                    hold on;
                    plot( sub2-1+cmin, sub1-1+rmin, 'w.','MarkerSize', 30)
                    
                    % xx and yy are the segments coordinates
                    [xx,yy] = getBB( data.segs.props(ii).BoundingBox );
                    
                    if data.segs.score(ii) % score is 1
                        data.segs.score(ii) = 0; % set to 0
                        data.segs.segs_good(yy,xx) = 0;
                        data.segs.segs_bad(yy,xx) = 1;
                    else
                        data.segs.score(ii) = 1;
                        data.segs.segs_good(yy,xx) = 1;
                        data.segs.segs_bad(yy,xx) =  0;
                        
                    end
                    
                    % updates cell mask
                    data.mask_cell   = double((data.mask_bg - data.segs.segs_good - data.segs.segs_3n)>0);
                    
                    %% is this necessary? can i just do it at the end?
                    % image with 1 where a region had a good score = 1
                    %                 old_good_map = ismember(data.regs.regs_label, find(data.regs.score));
                    %
                    %                 %data = intMakeRegs( data, [], CONST );
                    %                 %data = intUpdateData( data, A, E ,CONST);
                    %
                    %                 % go through all the regions and update their scores?
                    %                 for hh = 1: data.regs.num_regs
                    %                     [xx,yy] = getBBpad( data.regs.props(hh).BoundingBox, ss, 1);
                    %                     tmp_old_good  = old_good_map(yy,xx);
                    %                     tmp_cell_mask = (hh==data.regs.regs_label(yy,xx));
                    %                     data.regs.score(hh) = any(tmp_old_good(tmp_cell_mask));
                    %                 end
                    %%
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
        else
            selectMode = 0;
        end
    end
    
end