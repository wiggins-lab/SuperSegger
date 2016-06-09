function [ mask_bg_mod ] = intRemoveFalseMicroCol( mask_bg, phase )

mask_bg = logical( mask_bg );


mask_er = bwmorph(  mask_bg, 'erode',1 ) - bwmorph(  mask_bg, 'erode',2 );

label_bg = bwlabel( mask_bg );


mask_er = logical(mask_er);
label_er = label_bg;

label_er(~mask_er) = 0;


ind_bg = unique(label_bg(:));
ind_er = unique(label_er(:));

kill_l = ind_bg(~ismember( ind_bg, ind_er));


props = regionprops( label_er, double(phase), 'MeanIntensity' );

vals = [props.MeanIntensity];
mean_noncell = mean( phase( ~mask_bg ));

ind = find(vals > mean_noncell);

kill_list = [kill_l',ind];

mask_kill = ismember( label_bg, kill_list  );
mask_bg_mod = mask_bg;

mask_bg_mod(mask_kill) = 0;



end

