function [ mask_bg_mod ] = intRemoveFalseMicroCol( mask_bg, phase )

mask_bg = logical( mask_bg );


mask_er = bwmorph(  mask_bg, 'erode',1 ) - bwmorph(  mask_bg, 'erode',2 );
%mask_er = bwmorph(  mask_bg, 'dilate',1 ) - mask_bg;
%mask_er = bwmorph(  mask_bg, 'dilate',1 ) - mask_bg;


label_bg = bwlabel( mask_bg );


mask_er = logical(mask_er);
label_er = label_bg;

label_er(~mask_er) = 0;


ind_bg = unique(label_bg(:));
ind_er = unique(label_er(:));

kill_l = ind_bg(~ismember( ind_bg, ind_er));

[M,K,L1,L2] = curveFilter( -double(phase), 3 );
props = regionprops( label_er, double(L2), 'MeanIntensity' );
vals = [props.MeanIntensity];


props = regionprops( label_er, double(phase), 'MeanIntensity' );
vals0 = [props.MeanIntensity];


mean_noncell = mean( phase( ~mask_bg ));
mean_cell    = mean( phase( mask_bg ));

dI = mean_noncell-mean_cell;


ind = find(vals > mean_noncell+dI*.0);

kill_list = [kill_l',ind];

mask_kill = ismember( label_bg, kill_list  );
mask_bg_mod = mask_bg;

mask_bg_mod(mask_kill) = 0;



end

