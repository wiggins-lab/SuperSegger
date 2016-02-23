function im_ = doColorMap( im, colormap_ )

ss  = size( im );
im_ = im;
im_ = im_(:);
im_ = colormap_(im_+1,:);
im_ = reshape( im_, [ss,3]);

end