function [data_r, data_c, data_f] = intLoadData(dirname, contents, nn, num_im, clist, FLAGS)
data_c = loaderInternal([dirname,contents(nn).name], clist);
data_r = [];
data_f = [];
if shouldLoadNeighborFrames(FLAGS)
    if nn > 1
        data_r = loaderInternal([dirname,contents(nn-1).name], clist);
    end
    if nn < num_im-1
        data_f = loaderInternal([dirname,contents(nn+1).name], clist);
    end
end

function value = shouldLoadNeighborFrames(FLAGS)
value = FLAGS.m_flag == 1 || FLAGS.showLinks == 1;


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