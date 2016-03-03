function trackOptiCropMulti(dirname_)
% trackOptiCropMulti crops multiple images

if ~isempty(dirname_)
    file_filter = '*.tif';
    
    dirseperator = filesep;
    
    dirname = [dirname_,dirseperator];
    
    contents=dir([dirname file_filter]);
    num_im = numel( contents );
    
    nt  = [];
    nc  = [];
    nxy = [];
    nz  = [];
    
    for i = 1:num_im
        
        nameInfo = ReadFileName(contents(i).name);
        
        
        nt  = [nt, nameInfo.npos(1,1)];
        nc  = [nc, nameInfo.npos(2,1)];
        nxy = [nxy,nameInfo.npos(3,1)];
        nz  = [nz, nameInfo.npos(4,1)];
        
    end
    
    nt  = sort(unique(nt));
    nc  = sort(unique(nc));
    nxy = sort(unique(nxy));
    nz  = sort(unique(nz));
    
    if dirname(1) == '.'
        targetd = [dirname,'crop',dirseperator];
    else
        targetd = [dirname_,'_crop',dirseperator];
    end
    
    mkdir(targetd);
    
    for nnxy = nxy;
        
        nameInfo.npos(:,1) = [nt(1); nc(1); nnxy; nz(1)];
        im1   = imread( [dirname, MakeFileName(nameInfo) ]);
        
        nameInfo.npos(:,1) = [nt(end); nc(1); nnxy; nz(1)];
        imEnd = imread( [dirname, MakeFileName(nameInfo) ]);
        clf;
        
        im = cat(3, ag(im1), ag(imEnd), 0*ag(imEnd));
        
        imshow( im )
        
        disp('Pick the two corners of the crop region.')
        
        xy = ginput(2);
        
        ss = size(im);
        
        x = floor(sort(xy(:,1)));
        y = floor(sort(xy(:,2)));
        
        if x(1)<1
            x(1) = 1;
        elseif x(2)>ss(2)
            x(2) = ss(2);
        end
        
        if y(1)<1
            y(1) = 1;
        elseif y(2)>ss(1)
            y(2) = ss(1);
        end
        
        
        yy = y(1):y(2);
        xx = x(1):x(2);
        
        imshow( im( yy, xx, : ) );
        
        
        for it = nt;
            for ic = nc;
                for iz = nz;
                    
                    nameInfo.npos(:,1) = [it; ic; nnxy; iz];
                    in_name =  [dirname, MakeFileName(nameInfo)]
                    im = imread( in_name );
                    
                    out_name = [targetd, MakeFileName(nameInfo)];
                    imwrite( im(yy,xx), out_name, 'TIFF' );
                end
                
            end
        end
    end
end
end