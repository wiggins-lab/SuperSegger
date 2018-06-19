function CONST = intFixFields( CONST, CONST0 )
% This function adds fields that exist in CONST0 but do not exist in CONST
% to CONST
if isstruct( CONST0 )
    C0n = fieldnames( CONST0 );
    
    for ii = 1:numel( C0n )
        
        if isfield( CONST, C0n{ii} )
            CONST = setfield( CONST, C0n{ii}, ...
                intFixFields( getfield( CONST, C0n{ii} ),...
                              getfield( CONST0, C0n{ii}) ) );
        else
            CONST = setfield( CONST, C0n{ii},  getfield( CONST0, C0n{ii}));
        end
        
    end
%else
%    CONST = CONST0;
end

end