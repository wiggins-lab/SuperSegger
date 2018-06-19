function nnc = intGetChannelNum( data )
%% comp number of fluor channels

nc = numel(find(~cellfun('isempty',strfind(fieldnames(data),'fluor'))));
nnc = 0;

for jj = 1:nc
    
    fluorName =  ['fluor',num2str(jj)];
    
    if isfield( data, fluorName )
        nnc = nnc + 1;
    end
    
end

end