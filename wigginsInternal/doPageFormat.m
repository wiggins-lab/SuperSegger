function doPageFormat( ss )


if ~exist( 'ss', 'var') || isempty( ss )
    ss = [5,3];
end

h = gcf;
set(h,'PaperPosition',[0 0, ss]);
set( h, 'PaperSize', ss );

%xx = get(h,'Position');

%set(h,'Position',[xx(1:2),ss*72]);


end