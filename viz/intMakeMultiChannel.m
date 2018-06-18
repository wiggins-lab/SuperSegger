function im = intMakeMultiChannel( data, FLAGS, CONST, clist, nc )
% intMakeMultiChannel: Code for making a multichannel compsite fluorescent
% image. 
% Notes: The long term goal is to implement this code for all the
% visualization modules... so updates will update all at once. This
% implementation isn't done yet... but will happen eventually.
%
% INPUT :
%       data : cell/frame data file
%       FLAGS: the flags struct from superSeggerViewerGui
%       CONST : segmentation parameters
%       clist : cell list
%       nc: Number of fluorescent channels
%
% OUTPUT :
%       composite 8 bit color image.
%
% Copyright (C) 2016 Wiggins Lab
% Written by Paul Wiggins
% University of Washington, 2018
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

im = [];

if (FLAGS.f_flag == 0  && ~FLAGS.composite ) || ...
        (FLAGS.phase_flag( FLAGS.f_flag +1 ) && ~FLAGS.composite) ...
        || (FLAGS.composite && FLAGS.include(1) );
    
    if FLAGS.manual_lut(1) && ~isnan( FLAGS.lut_min(1) ) && ~isnan( FLAGS.lut_max(1))
        minmax = [FLAGS.lut_min(1), FLAGS.lut_max(1)];
    elseif FLAGS.gbl_auto(1) && isfield( clist, 'imRangeGlobal')  
        minmax = clist.imRangeGlobal(:,1);
    else
        minmax = intMakeMinMax( data.phase );
    end
    
    im = comp( {data.phase, minmax, FLAGS.level(1)} );
end

% if you are in fluorescence mode (f_flag) draw the fluor channels
if FLAGS.f_flag && CONST.view.falseColorFlag
    ranger = FLAGS.f_flag;
elseif FLAGS.composite
   ranger = find(FLAGS.include(2:(nc+1)));
elseif ~FLAGS.f_flag
    ranger = [];
else
    ranger = FLAGS.f_flag;
end

for ii = ranger;
    
    flName    =  ['fl',num2str(ii),'bg'];

    filtName = ['fluor',num2str(ii),'_filtered'];
    
    if FLAGS.filt(ii) && isfield( data, filtName);
        flourName = filtName;
    else
        flourName = ['fluor',num2str(ii)];
    end
    
    im_tmp = data.(flourName);
    
    if FLAGS.filt(ii)
        minmax = intMakeMinMax( im_tmp );
        
    elseif FLAGS.manual_lut(ii+1) && ~isnan( FLAGS.lut_min(ii+1) ) && ~isnan( FLAGS.lut_max(ii+1))
        minmax = [FLAGS.lut_min(ii+1), FLAGS.lut_max(ii+1)];
    elseif FLAGS.gbl_auto(ii+1) && isfield( clist, 'imRangeGlobal')
        minmax = clist.imRangeGlobal(:,ii+1);
    else
        minmax = intMakeMinMax( im_tmp );
               
        if isfield( data, flName )     
            minmax(1) = data.(flName);
        end
        
    end
    
    if CONST.view.falseColorFlag && FLAGS.f_flag
        cc = jet(256);
    else
        cc = CONST.view.fluorColor{ii};
    end
    
    
    command = {im_tmp, cc, FLAGS.level(ii+1)};
    
    if FLAGS.log_view(ii)
        command = {command{:}, 'log'};
    else
        command = {command{:}, minmax };
    end
          
     im = comp( {im}, command );
  
  
end










end