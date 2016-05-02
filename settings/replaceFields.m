function [ structReplaced ] = replaceFields( structOld, structNew )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

structReplaced = structOld;
fieldNamesInNew = fieldnamesr(structNew);
for i = 1:numel(fieldNamesInNew)  
    structReplaced.(fieldNamesInNew(i)) =  structNew.(fieldNamesInNew(i));
end
    
end



