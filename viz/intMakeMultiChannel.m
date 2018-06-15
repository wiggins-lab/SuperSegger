function im = intMakeMultiChannel( data, FLAGS, CONST, clist, nc )

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
        
        if isfield( data, flName )     
            minmax(1) = data.(flName);
        end
        
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