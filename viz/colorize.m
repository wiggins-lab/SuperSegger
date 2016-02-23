function  imTmp_ = colorize( im, mask, colormap_, back )

if ~exist( 'colormap_', 'var' ) || isempty( colormap_ )
    colormap_ = jet(256);
end

if ~exist( 'mask', 'var' ) || isempty( mask )
    mask = ones(size(im));
else
    mask = double( mask );
    mask = mask./(max(mask(:)));
end
    
if ~exist( 'back', 'var' ) || isempty( back )
    back = [0.5,0.5,0.5];
end


imTmp = double(255*doColorMap( ag(im, 0, max(im( mask>.95 )) ), colormap_ ));
mask3 = cat( 3, mask, mask, mask );
onez = ones(size(im));
imTmp_ = uint8(mask3.*imTmp + 255.0*(1-mask3).*cat(3, back(1)*onez, back(2)*onez, back(3)*onez ));


end