function cm = makehotcold( p_flag,maxis )
% makehotcold : used to create a hotplot

if ~exist( 'p_flag' ) || isempty( p_flag )
    p_flag = false;
    disp( 'Set p flag false' );
end

if p_flag
    cm = hotcoldinv(256);
else
    cm = hotcold(256);
end

% creates axis for the colormap
if ~exist( 'maxis','var' ) || isempty( maxis )
    cc = caxis;
    caxis( max(abs(cc))*[-1,1] );
else
    caxis( maxis*[-1,1] );
end

colormap(cm);

end


