    function minmax = intMakeMinMax( im )
        minner = medfilt2( im, [2,2], 'symmetric' );
        maxxer = max( minner(:));
        minner = min( minner(:));
        minmax = [minner,maxxer];
    end