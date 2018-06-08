function name_mod = intFixFileName( name, str_end) 
% Fixes a file name by adding the suffix str_end if it doesn't already
% exist
if str_end(1) ~= '.'
   str_end =  ['.',str_end];
end

ns = numel( str_end );
nn = numel( name );

% check file name length
if ns > nn
    name_mod = [ name, str_end];
elseif ~strcmp( name( [end-ns+1:end] ), str_end )
    name_mod = [ name, str_end];
else
    name_mod = [ name ];
end

end


