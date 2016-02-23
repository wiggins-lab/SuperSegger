function cm = makehotcold( p_flag,maxis )


if ~exist( 'p_flag' ) || isempty( p_flag )
    p_flag = false;
    disp( 'Set p flag false' );
end


if p_flag
    cm = hotcoldinv(256);
else
    cm = hotcold(256);
end


if ~exist( 'maxis','var' ) || isempty( maxis )
    cc = caxis;
    caxis( max(abs(cc))*[-1,1] );
else
    caxis( maxis*[-1,1] );
end


colormap(cm);

end