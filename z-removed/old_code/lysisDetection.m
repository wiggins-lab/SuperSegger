function lysisDetection (dirname, CONST, header)
% unfinished - copied old methods of lysisDetection in case we want to add
% it back.


if(nargin<1 || isempty(dirname))
    dirname=uigetdir();
end

dirname = fixDir(dirname);

filt2 = 'err.mat'; % name of final files
contents=dir([dirname,filt]);

if numel(contents) >0 && CONST.trackOpti.LYSE_FLAG
    % load data files
    for i = 1 : numel(contents)-1
         data_c = load ([dirname,contents(i).name]);
         data_f = load ([dirname,contents(i+1).name]);
         data_c = lysisPerDataFile (data_c,data_f, CONST)
         save(contents(i).name,data_,c
    end    
end




    function data1 = lysisPerDataFile (data1,data2, CONST)
        
        % initialize
        data1.regs.lyse.errorColor1 = zeros(1,data1.regs.num_regs); % Fluor1 intensity change error in this frame
        data1.regs.lyse.errorColor1Cum = zeros(1,data1.regs.num_regs); % Cum fluor1 intensity change error
        data1.regs.lyse.errorColor2 = zeros(1,data1.regs.num_regs); % Fluor2 intensity change error in this frame
        data1.regs.lyse.errorColor2Cum = zeros(1,data1.regs.num_regs); % Cum fluor2 intensity change error
        data1.regs.lyse.errorColor1b = zeros(1,data1.regs.num_regs); % Fluor1 intensity change error in this frame
        data1.regs.lyse.errorColor1bCum = zeros(1,data1.regs.num_regs); % Cum fluor1 intensity change error
        data1.regs.lyse.errorColor2b = zeros(1,data1.regs.num_regs); % Fluor2 intensity change error in this frame
        data1.regs.lyse.errorColor2bCum = zeros(1,data1.regs.num_regs); % Cum fluor2 intensity change error
        data1.regs.lyse.errorShape = zeros(1,data1.regs.num_regs); % Fluor intensity change error in this frame
        data1.regs.lyse.errorShapeCum = zeros(1,data1.regs.num_regs); % Cum intensity change error
        
        
        % get the change in fluorescence
        
        
        % Calculate the change in mean fluor level in each channel
        % between the regions of max overlap.
        
        for ii = 1 : data1.regs.num_regs
            
            [xx,yy] = getBB( data1.regs.props(ii).BoundingBox );
            mask1 = (data1.regs.regs_label(yy,xx)==ii);
            
            [xx2,yy2] = getBB( data1.regs.props(ind).BoundingBox );
            mask2 = (data2.regs.regs_label(yy2,xx2)==ind);
            
            if isfield(data1, 'fluor1')
                fluor_d1 = data1.fluor1(yy,xx);
                fluor_d2 = data2.fluor1(yy2,xx2);
                mf1 = mean(fluor_d1(mask1))-m1back;
                mf2 = mean(fluor_d2(mask2))-m1back;
                mmax = max([mf1,mf2]);
                
                if mmax > s1back
                    dF1(ii) =  min([mf1,mf2])/max([mf1,mf2]);
                else
                    dF1(ii) = 1;
                end
                
                fluor_d1 = data1.fluor1(yy,xx);
                fluor_d2 = data2.fluor1(yy,xx);
                
                mf1 = mean( fluor_d1(mask1) )-m1back;
                mf2 = mean( fluor_d2(mask1) )-m1back;
                
                mmax = max([mf1,mf2]);
                
                if mmax > s1back
                    dF1b(ii) =  min([mf1,mf2])/max([mf1,mf2]);
                else
                    dF1b(ii) = 1;
                end
            end
            
            if isfield( data1, 'fluor2' )
                fluor_d1 = data1.fluor2(yy,xx);
                fluor_d2 = data2.fluor2(yy2,xx2);
                mf1 = mean( fluor_d1(mask1) )-m2back;
                mf2 = mean( fluor_d2(mask2) )-m2back;
                mmax = max([mf1,mf2]);
                
                if mmax > s2back
                    dF2(ii) =  min([mf1,mf2])/max([mf1,mf2]);
                else
                    dF2(ii) = 1;
                end
                
                fluor_d1 = data1.fluor2(yy,xx);
                fluor_d2 = data2.fluor2(yy,xx);
                
                mf1 = mean( fluor_d1(mask1) )-m2back;
                mf2 = mean( fluor_d2(mask1) )-m2back;
                
                mmax = max([mf1,mf2]);
                
                if mmax > s2back
                    dF2b(ii) =  min([mf1,mf2])/max([mf1,mf2]);
                else
                    dF2b(ii) = 1;
                end
            end
            
        end
        
        % forward mapping :
        % dF1_f, dF2_f,dF1b_f,dF2b_f]   ...
        %   = calcRegsInt( data,   data_f, CONST);
        % keep the forward mapping.
        data1.regs.dF1  = dF1;
        data1.regs.dF2  = dF2;
        data1.regs.dF1b = dF1b;
        data1.regs.dF2b = dF2b;
        
        
        % Fluor Ratio error is set if Fluor Ratio is less than
        % CONST.trackOpti.FLUOR1_CHANGE_MIN
        data1.regs.lyse.errorColor1 = ...
            ( data1.regs.dF1 < CONST.trackOpti.FLUOR1_CHANGE_MIN );
        data1.regs.lyse.errorColor2 = ...
            ( data1.regs.dF2 < CONST.trackOpti.FLUOR2_CHANGE_MIN );
        data1.regs.lyse.errorColor1b = ...
            ( data1.regs.dF1b < CONST.trackOpti.FLUOR1_CHANGE_MIN );
        data1.regs.lyse.errorColor2b = ...
            ( data1.regs.dF2b < CONST.trackOpti.FLUOR2_CHANGE_MIN );
        
        % Shape error is defined by having both a eccentricity lower than the
        % limit CONST.trackOpti.ECCENTRICITY and a minor axis length greater
        % than CONST.trackOpti.LSPHEREMIN and smaller than
        % CONST.trackOpti.LSPHEREMAX
        data1.regs.lyse.errorShape = ...
            and( (data1.regs.eccentricity > CONST.trackOpti.ECCENTRICITY), and(...
            ( drill(data1.regs.props,'.MinorAxisLength')' > CONST.trackOpti.LSPHEREMIN ),...
            ( drill(data1.regs.props,'.MajorAxisLength')' < CONST.trackOpti.LSPHEREMAX )));
    end
end
