function [data_c] = merge2Regions (data_c, reg1, reg2, CONST)
% merge2Regions : merges reg1 and reg2 into one in the mask_cell
% regions need to be remade after this in order to have the right
% properties.
verbose = CONST.parallel.verbose;

if verbose
    disp (['Merging regions ', num2str(reg1), ' ', num2str(reg2)]);
end

mask1 = (data_c.regs.regs_label == reg1);
mask2 = (data_c.regs.regs_label == reg2);
masksum = (mask1+mask2);
masksum_  = imdilate(masksum,strel('square',3));
masksum__  = imerode(masksum_,strel('square',3));

segsInMask = data_c.segs.segs_label;
segsInMask(~masksum__) = 0;
segsInMask = logical(segsInMask);
data_c.segs.segs_good(segsInMask) = 0;
data_c.segs.segs_bad(segsInMask) = 1;
data_c.mask_cell = double((data_c.mask_cell + segsInMask)>0);


end