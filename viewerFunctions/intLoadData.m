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