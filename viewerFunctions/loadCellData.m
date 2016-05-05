function [data_cell,cell_name] = loadCellData(num, dirname_cell, handles)
data_cell = [];
cell_name = [];
padStr = getPadSize(dirname_cell, handles);
if ~isempty( padStr )
    data_cell = [];
    filename_cell_C = [dirname_cell,'Cell',num2str(num,padStr),'.mat'];
    filename_cell_c = [dirname_cell,'cell',num2str(num,padStr),'.mat'];
else
    return;
end
if exist(filename_cell_C, 'file' )
    filename_cell = filename_cell_C;
    cell_name = ['Cell',num2str(num,padStr),'.mat'];
elseif exist(filename_cell_c, 'file' )
    filename_cell = filename_cell_c;
    cell_name = ['cell',num2str(num,padStr),'.mat'];
else
    if isempty(handles)
        disp(['Files: ',filename_cell_C,' and ',filename_cell_c,' do not exist.']);
    else
        handles.message.String = ['Files: ',filename_cell_C,' and ',filename_cell_c,' do not exist.'];
    end
    return;
end
try
    data_cell = load( filename_cell );
catch
    if isempty(handles)
        disp(['Error loading: ', filename_cell]);
    else
        handles.message.String = ['Error loading: ', filename_cell];
    end
end