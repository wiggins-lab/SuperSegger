function [Kymo,ll1,f1mm,f2mm] = makeKymographC( data, disp_flag, CONST );

if ~isfield(CONST.view, 'falseColorFlag' )
    CONST.view.falseColorFlag = false;
end

%figure(1);
persistent colormap_;
if isempty( colormap_ )
    colormap_ = colormap( 'jet' );
    %colormap_ = colormap( 'hsv' );
end

if nargin < 2
    disp_flag = 0;
end

num_im = numel(data.CellA);

ss = [0,0];
ll = [0,0];

for ii = 1:num_im
    ss_tmp = size(data.CellA{ii}.phase);
    
    ss(1) = max([ss(1),ss_tmp(1)]);
    ss(2) = max([ss(2),ss_tmp(2)]);
    
    ll_tmp = data.CellA{ii}.length;
    
    ll(1) = max([ll(1),ll_tmp(1)]);
    ll(2) = max([ll(2),ll_tmp(2)]);
end

ss = ss + [5,5];

[XX,YY] = meshgrid( 1:ss(2), 1:ss(1) );
ll0 = ll;
ll = ceil(ll/2);

ll1 = [-ll(1):ll(1)];
ll2 = [-ll(2):ll(2)];

[LL1,LL2] = meshgrid( ll1,ll2 );

nn = numel( ll1 );

kymoR = zeros(nn,num_im);
kymoG = zeros(nn,num_im);
kymoB = zeros(nn,num_im);

e1old = [];

for ii = 1:num_im
    mask  = data.CellA{ii}.mask;
    
    back  = autogain(data.CellA{ii}.phase);
    
    if isfield( data.CellA{ii}, 'fluor1')
        fluor1  = data.CellA{ii}.fluor1;
        
        if isfield( data.CellA{ii}, 'fl1' ) && ...
                isfield( data.CellA{ii}.fl1, 'bg' )
            fluor1 = fluor1 - data.CellA{ii}.fl1.bg;
            fluor1(fluor1<0) = 0;
        else
            fluor1 = fluor1 - mean( fluor1(mask));
            fluor1(fluor1<0) = 0;
        end
    else
        fluor1 = 0*data.CellA{ii}.mask;
    end
    
    if isfield( data.CellA{ii}, 'fluor2')
        fluor2 = data.CellA{ii}.fluor2;
        
        if isfield( data.CellA{ii}, 'fl12' ) && ...
                isfield( data.CellA{ii}.fl2, 'bg' )
            fluor2 = fluor2 - data.CellA{ii}.fl2.bg;
            fluor2(fluor1<0) = 0;
        else
            fluor2 = fluor2 - mean( fluor2(mask));
            fluor2(fluor2<0) = 0;
            
        end
    else
        fluor2 = 0*data.CellA{ii}.mask;
    end
    
    sq = [1 1 1; 1 1 1; 1 1 1];
    mask_ = imdilate(data.CellA{ii}.mask,sq);
    mask  = data.CellA{ii}.mask;
    outline= mask_-mask;
    
    maski = autogain(outline);
    
    % Make all the images the same sizes
    [rChan,roffset] = (fixIm(double(fluor2).*double(mask),ss));
    [gChan,roffset] = (fixIm(double(fluor1).*double(mask),ss));
    [bChan,roffset] = fixIm(mask,ss);
    
    ro = data.CellA{ii}.r_offset;
    r = data.CellA{ii}.r;
    
    e1 = data.CellA{ii}.coord.e1;
    e2 = data.CellA{ii}.coord.e2;
    
    LL1x =  LL1*e1(1)+LL2*e2(1)+r(1)-ro(1)+1+roffset(1);
    LL2y =  LL1*e1(2)+LL2*e2(2)+r(2)-ro(2)+1+roffset(2);
    
    rChanp = (interp2(XX,YY,double(rChan),LL1x,LL2y));
    gChanp = (interp2(XX,YY,double(gChan),LL1x,LL2y));
    bChanp = (interp2(XX,YY,double(bChan),LL1x,LL2y));
    
    rChanps = sum( double(rChanp) );
    gChanps = sum( double(gChanp) );
    bChanps = sum( double(bChanp) );
    
    kymoR(:,ii) = rChanps';
    kymoG(:,ii) = gChanps';
    kymoB(:,ii) = bChanps';
end

Kymo = [];

if ~isfield(data.CellA{1}, 'pole');
    data.CellA{1}.pole.op_ori = 1;
end


if data.CellA{1}.pole.op_ori < 0
    Kymo.g = kymoG(end:-1:1,:);
    Kymo.b = kymoB(end:-1:1,:);
    Kymo.b(isnan(Kymo.b)) = 0;
    Kymo.r = kymoR(end:-1:1,:);
else
    Kymo.g = kymoG;
    Kymo.b = kymoB;
    Kymo.b(isnan(Kymo.b)) = 0;
    Kymo.r = kymoR;
    
end

f1mm(1) = min( Kymo.g(logical(Kymo.b)));
f1mm(2) = max( Kymo.g(logical(Kymo.b)));

f2mm(1) = min( Kymo.r(logical(Kymo.b)));
f2mm(2) = max( Kymo.r(logical(Kymo.b)));

if disp_flag
    
    if CONST.view.falseColorFlag
        clf;
        
        backer3 = double(cat(3, Kymo.b, Kymo.b, Kymo.b)>1);
        f1mm(1) = min( Kymo.g(logical(Kymo.b)));
        f1mm(2) = max( Kymo.g(logical(Kymo.b)));
        
        f2mm(1) = min( Kymo.r(logical(Kymo.b)));
        f2mm(2) = max( Kymo.r(logical(Kymo.b)));
        
        
        im = doColorMap( ag(Kymo.g,f1mm(1), f1mm(2)), colormap_ );
        
        imagesc( im.*backer3+.6*(1-backer3) );
        
    else
        
        clf;
        
        backer = autogain(Kymo.b);
        backer = 0.3*(max(backer(:))-backer);
        f1mm(1) = min( Kymo.g(logical(Kymo.b)));
        f1mm(2) = max( Kymo.g(logical(Kymo.b)));
        
        f2mm(1) = min( Kymo.r(logical(Kymo.b)));
        f2mm(2) = max( Kymo.r(logical(Kymo.b)));
        
        imagesc( cat(3, autogain(Kymo.r )+backer, ...
            autogain(Kymo.g)+backer,...
            backer ));
    end
end

end

function [imFix,roffset] = fixIm(im, ss)



ssOld = size(im);
imFix = zeros(ss);

offset = floor((ss-ssOld)/2)-[1,1];
if offset(1)<0
    offset(1) = offset(1) + 1;
end
if offset(2)<0
    offset(2) = offset(2) + 1;
end

try
    imFix(offset(1)+(1:ssOld(1)),offset(2)+(1:ssOld(2))) = im;
catch
    '';
end
roffset = offset(2:-1:1);
imFix = imFix;
end


