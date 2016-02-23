function [touch_list] = segsTLEdit( dirname, frame_num )
% segsTLEdit : used to visually modify segments in a frame.
% Possible choices : q to quit
%                    []  to modify
%                    s  to save
%                    g: go to frame n
%                    1, 2, 3, & 4 are different image modes
%                    c  clear figure
%              
% INPUT :
%       dirname : xy directory
%       frame_num : frame number
% OUTPUT :
%       touch_list :


tmpdir = pwd;

cd(dirname);

dirname = '.';

if ~exist('disp_flag');
    disp_flag = 0;
end

touch_list = [];

if(nargin<1 || isempty(dirname))
    dirname=uigetdir()
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


data = loaderInternal([dirname,contents(i  ).name]);
ss = size( data.segs.phaseMagic );

while runFlag
    
    data.mask_cell   = double((data.mask_bg - data.segs.segs_good - ...
        data.segs.segs_3n)>0);
    
    showSegData( data, im_flag);
    figure(1);
    hold on;
    disp('q to quit');
    disp('[] to modify');
    disp('s to save' );
    disp('g: go to frame n');
    disp('1, 2, 3, & 4 are different image modes');
    disp('c clear the figure');
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
        [junk,ind] = max( tmp(:) );
        
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
        
        data.mask_cell   = double((data.mask_bg - data.segs.segs_good - data.segs.segs_3n)>0);
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
        
        data = loaderInternal([dirname,contents(i  ).name]);
        data.mask_cell   = double((data.mask_bg - data.segs.segs_good - data.segs.segs_3n)>0);
        
    elseif c(1) == 's' % save - why is it empty?
        
        
        
    elseif c(1) == '1' % image mode 1
        
        im_flag = 1;
        
    elseif c(1) == '2'
        
        im_flag = 2;
        
    elseif c(1) == '3'
        
        im_flag = 3;
        
    elseif c(1) == '4'
        
        im_flag = 4;
        
    elseif c(1) == 'c' % clear figure
        clf;
    end
    
    dataname=[dirname,contents(i).name];
    save(dataname,'-STRUCT','data');
end

tmp = pwd;
cd(tmpdir);
touch_list = unique(touch_list);

end

function data = loaderInternal( filename )

data = load( filename );
data.segs.segs_good   = double(data.segs.segs_label>0).*double(~data.mask_cell);
data.segs.segs_bad   = double(data.segs.segs_label>0).*data.mask_cell;

end