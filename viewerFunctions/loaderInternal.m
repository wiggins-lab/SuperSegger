function data = loaderInternal(filename, clist)
data = load(filename);
ss = size(data.phase);
if isfield( data, 'mask_cell' )
    data.outline = xor(bwmorph( data.mask_cell,'dilate'), data.mask_cell);
end
if ~isempty(clist)
    clist = gate(clist);
    data.cell_outline = false(ss);
    if isfield( data, 'regs' ) && isfield( data.regs, 'ID' )
        ind = find(ismember(data.regs.ID,clist.data(:,1)));
        mask_tmp = ismember( data.regs.regs_label, ind );
        data.cell_outline = xor(bwmorph( mask_tmp, 'dilate' ), mask_tmp);       
    end
end