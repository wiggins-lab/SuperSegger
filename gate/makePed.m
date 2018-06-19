function data = makePed( data )

ID0  = data.ID;
ID   = sort( ID0 );

nc = numel( ID );

ped_vec = cell([1,nc]);

for jj = 1:nc
    
    id = ID(jj);
    
    ii = find( id==ID0, 1, 'first' );
    
    m = data.mother(ii);
    ped = '';
    
    if m == 0 || isnan(m)
        ped = '0';
    else
        ind = find( m==ID0 );
        
        if ~isempty(ind);
            ped = ped_vec{ind};
            
            if data.pole(ii) == 2
                ped = [ped,'1'];
            else
                ped = [ped,'0'];
            end
        end
    end
    
    ped_vec{ii} = ped;
    gen(ii)     = numel(ped);
end

data.ped = ped_vec;

end