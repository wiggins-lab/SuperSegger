function mask = intRemovePillars(phase, CONST)



if exist( 'CONST' ) && ~isempty( CONST ) && ...
        isfield( CONST.superSeggerOpti, 'remove_pillars' )
    radius   = CONST.superSeggerOpti.remove_pillars.radius;
    cut      = CONST.superSeggerOpti.remove_pillars.cut;
    Area_Cut = CONST.superSeggerOpti.remove_pillars.Area_Cut;
    debug    = CONST.superSeggerOpti.remove_pillars.debug; 
    
else
    radius = 2;
    cut = 0.05;
    Area_Cut = 700;
    debug = false;
end


[~,~,~,D] = curveFilter(  double(phase), radius );

D = D/max(D(:));


D(D<cut) = cut;

ws = logical(watershed(D));

lab = bwlabel(ws);

props = regionprops( lab, {'Area'} );

A = [props.Area];



mask = ismember( lab, find(A<Area_Cut) );

se = strel('disk',1);
mask = imdilate(mask,se);


if debug
    figure( 'name', ['intRemovePillars: Area cut: A = ',num2str(Area_Cut)] );
    clf;
    comp( {phase}, {lab,'label',A} );
    drawnow;
    
    
    
    figure( 'name', ['intRemovePillars: Masked region' ] );
    clf;
    comp( {phase}, {mask,'r',.5} );
    drawnow;
end






end

