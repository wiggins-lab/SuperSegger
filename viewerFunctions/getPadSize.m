function padStr = getPadSize( dirname, handles )
contents = dir([dirname,'*ell*.mat']);
if numel(contents) == 0
    if isempty(handles)
        disp('No cell files' );
    else
        handles.message.String = 'No cell files';
    end
    padStr = [];
else
    num_num = sum(ismember(contents(1).name,'1234567890'));
    padStr = ['%0',num2str(num_num),'d'];
end