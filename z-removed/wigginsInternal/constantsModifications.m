% modify something in all the constants..

[~,reslist] = getConstantsList();

for i = 1 : numel(reslist)
CONST = loadConstants(reslist{i});
CONST.regionOpti.MIN_LENGTH = CONST.regionOpti.MAX_LENGTH;
CONST.regionOpti = rmfield(CONST.regionOpti,'MAX_LENGTH');
save(reslist{i},'-struct', 'CONST')
end