function [ poleSign ] = getPoleSign( data )
%GETPOLESIGN Returns the sign of the pole for a cell data structure
% or a data.CellA strcture.

poleSign = 1;

if  isfield(data,'CellA') && isfield(data.CellA{1},'pole') && isfield(data.CellA{1}.pole,'op_ori')
    poleSign = data.CellA{1}.pole.op_ori;
elseif  isfield(data,'pole') && isfield(data.pole,'op_ori')
    poleSign = data.pole.op_ori;
end

end

