function intCheckForInstallLib

boxes = {'Curve Fitting Toolbox',...                                
'Global Optimization Toolbox',...                           
'Image Processing Toolbox', ...                             
'Neural Network Toolbox',...                                
'Optimization Toolbox',...                                  
'Parallel Computing Toolbox',...                            
'Statistics and Machine Learning Toolbox'};

tmp = ver;


for ii = 1:numel(boxes)
found = strfind({tmp.Name}, boxes{ii} );
if isempty(cell2mat( found ));
    warning( ['Toolbox "', boxes{ii}, '" is missing. This may cause errors.' ] );
end

end

end