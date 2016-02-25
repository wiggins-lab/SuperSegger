%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [spot] = compSpotPosDevFmin(image, ff, backer, back_int,... 
  Istd_, im_mask, MAX_NUM_SPOT, ...
    CONST, channel, disp_flag, fig_num, opt)


%disp_flag = 1;

%%

opt.MaxIter = 100;

backer = double( backer );

ddd = [max(image(im_mask)-back_int)/max(backer(im_mask)),back_int];

[ddd] = fminsearch( @do_the_fit_backer,ddd,opt);
ddd(1) = abs(ddd(1));


back = intMakeBacker( backer, ddd );


% make std local 
%image_back = medfilt2(double(image - back), [3,3],...
%    'symmetric' );
image_back = double(image - back);
%image_back(image_back<0) = 0;

%%
opt.MaxIter = 25;


gaussR = CONST.trackLoci.gaussR;
crop   = CONST.trackLoci.crop;


tmp = struct(...
    'r', NaN, ...
    'score', NaN, ...
    'intensity_score', NaN, ...
    'intensity', NaN, ...
    'b', NaN );

spot(MAX_NUM_SPOT) = tmp;

score_array(MAX_NUM_SPOT) = NaN;

persistent sdisk;
persistent gauss;
persistent Xpre;
persistent Ypre;
persistent crop_;



if isempty(sdisk)
    sdisk =  strel('disk',1);
    gauss  =  fspecial('gaussian',7,gaussR);
    %lap    = -fspecial('laplacian');
    %locusd =  imfilter(gauss, lap);
    crop_ = -crop:crop;
    [Xpre, Ypre] = meshgrid(crop_,crop_);

end


%%
%%---------------------------------------------------------%
% here we load the images and resize them
% the resizing is necessary because the fitting works better
% when there are many pixels per spot.
%
% im_mask_ is an enlarged cell mask to make the fitting
% more accurate when there are spots near the cell border
%---------------------------------------------------------


im_mask = logical(im_mask);

im_mask_dilated = imdilate(im_mask, sdisk);
im_mask_dilated(1,:) = 0;
im_mask_dilated(end,:) = 0;
im_mask_dilated(:,1) = 0;
im_mask_dilated(:,end) = 0;


imsize = size(ff);

if ~exist('disp_flag', 'var');
    disp_flag = 0;
end
if disp_flag
    if ~exist('fig_num','var')
        fig_num = 7;
    end
end

%---------------------------------------------------------
%
% pad the images to facilitate cropping around each spot
%
% there are two masks: one for watersheding and one for fitting.
% the fitting mask is slightly wider to accomodate spots near
% the cell boundary.
%
%---------------------------------------------------------

im  = zeros( imsize(1)+2*crop,imsize(2)+2*crop);
im0 = zeros( imsize(1)+2*crop,imsize(2)+2*crop);

mk = logical(im);
mk_for_fit = logical(im);

mk(crop+1:crop+imsize(1),crop+1:crop+imsize(2)) = im_mask;

mk_init = mk;
%mk(crop+1:crop+imsize(1),crop+1:crop+imsize(2)) = im_mask_dilated;
im(crop+1:crop+imsize(1),crop+1:crop+imsize(2)) = image_back;

d_im = im;
d_im2 = im;

im0(crop+1:crop+imsize(1),crop+1:crop+imsize(2)) = image;

mk_for_fit(crop+1:crop+imsize(1),crop+1:crop+imsize(2)) = im_mask_dilated;

% H     =  fspecial('gaussian',7,1); 
% %H     =  fspecial('gaussian',7,0.75); 
% H2    = fspecial('laplacian',.1);
% H3    = imfilter( H,-H2); 
% imLap = imfilter( double(im), H3, 'replicate' );

imLap = double(im);

Istd  = 1;
Imean = min( im( im_mask ) );
Imean = 0;



if disp_flag
figure(10);
imshow( imLap, [] );
hold on;
end
%---------------------------------------------------------
%
% mean and variance of the intensity within the cell
%
%---------------------------------------------------------

Ibar = Imean;
dI   = 1;



%---------------------------------------------------------
%
% here we segment the fluorescent image to obtain regions
% around each spot.
%
%---------------------------------------------------------



%im_smoothed = imfilter(im_smoothed,fspecial('gaussian',5,1/2),'replicate');
im_smoothed = imfilter(image,gauss,'replicate');
%im_smoothed = double(im_smoothed).*mk;



im_loc_raw = zeros( imsize(1)+2*crop,imsize(2)+2*crop);
im_loc_raw(crop+1:crop+imsize(1),crop+1:crop+imsize(2)) = im_smoothed;%imfilter( ff, gauss, 'replicate' );

Imin = 0;

thresh  = 0;
im_loc  = im_loc_raw-thresh;
im_loc(im_loc<0) = 0;
im_loc(~mk_for_fit) = 0;

L = watershed(-double(im_loc));

wr = (L == 0);
num_seg = max((L(:)));

xn = zeros(num_seg,1);
yn = zeros(num_seg,1);
fn = zeros(num_seg,1);
an = zeros(num_seg,1);

spot_num = 0;

LL = L;

LL(~mk_for_fit) = 0;

%---------------------------------------------------------
%
% here we look at each watershed region and record
% the intensity of its spot.
%
%---------------------------------------------------------

for j = 1:num_seg;
    
    mask = (LL==j);
    
    [maxValue,y] = max(double(im_loc(:)).*double(mask(:)));
    [y,x] = ind2sub(size(im),y);
    
    xn(j) = x;
    yn(j) = y;
    %
    %     bb=size(image);
    %     tmp = im(max(y-crop,1):min(y+crop,bb(1)),max(x-crop,1):min(x+crop,bb(2)));
    fn(j)=maxValue;
    
    an(j) = sum(mask(:));
    
end

%%
%---------------------------------------------------------
%
% plots for debugging
%
%---------------------------------------------------------
if disp_flag
    figure(fig_num); clf;
    if channel == 1
        imshow([cat(3,autogain(im),autogain(~mk)*.2,autogain(wr)/2),cat(3,autogain(im),autogain(~mk)*0,0*autogain(wr)/2)],'InitialMagnification','fit')
    elseif channel == 2
        imshow(cat(3,autogain(wr)/2,0.5*autogain(im.*mk),autogain(im.*mk)),'InitialMagnification','fit')
    else
        imshow(cat(3,autogain(im.*mk)*.75,autogain(im.*mk)*.75,autogain(wr)/2),'InitialMagnification','fit')
    end
    %    drawnow;
    hold on
    %   axis equal
end

%%
%---------------------------------------------------------
%
% now we fit a gaussian to locate the spot within each region
%
%---------------------------------------------------------


%background intensity set to zero
%I0 = sum( double(im(:)).*double(mk(:)) )/sum( double(mk(:)) );
I0 = Ibar;

% thresholds to determine which spots are real
fnn = fn;

%%%%%%%%%%%%%%%%%%%%%%

% MODIFICATION: ONLY FIT THE BRIGHTEST TWO WATERSHEDS

%%%%%%%%%%%%%%%%%%%%%%%%

MIN_AREA = 8;



[fnn_, ord] = sort(fnn, 'descend');
an = an(ord);

iis = find(  (fnn_>0) .* (an > MIN_AREA)  );



iis = iis(1:min([MAX_NUM_SPOT,numel(iis)]));
iis = reshape(iis,1,numel(iis));

if ~isempty(iis)
    for ii = iis
        
        i = ord(ii);
        spot_crop = 1;
        mk(yn(i)+(-spot_crop:spot_crop), xn(i)+(-spot_crop:spot_crop)) = 0;
        
    end
    
    
    %Ibar = mean(im(mk));
    dI = std(im(mk));
    
    %%
    if 0
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % clf;
        % back = autogain(im_smoothed);
        % wsag = autogain(mask_crop_for_fit);
        % imshow( cat(3,autogain(im_smoothed),autogain(mask_crop_for_fit),autogain(mask_crop_for_fit)), [] );
        % hold on;
        % for ii = iis'
        %     i = ord(ii);
        %     plot(xn(i),yn(i),'wo');
        %
        % end
        % 'hi'
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
    
    
    %%
    for ii = iis
        
        i = ord(ii);
        
        x = xn(i);
        y = yn(i);
        
        %     mask_crop = double(L==i).*mk;
        mask_crop_for_fit = and(bwmorph(LL==i,'dilate'),mk_for_fit);
        
        
        
        % this is the initial guess for the fit parameters
        IG = im(y,x)-I0;
        b = 1;
        %bmin = 1;
        %bmax = 6;
        
        ddd = [x,y,IG,b];
        
        % lower bound
        %lddd = [x-crop,y-crop,0,bmin];
        
        % upper bound
        %uddd = [x+crop,y+crop,100000,bmax];
        
        % make the coordinates for the cropped image
        ix2 = x+crop_;
        iy2 = y+crop_;
        
        xx2 = Xpre+x;
        yy2 = Ypre+y;
        
        %---------------------------------------------------------
        %
        % here we actually do the fit
        %
        %---------------------------------------------------------
        
        
        mkk = mask_crop_for_fit(iy2,ix2);
        imm = im(iy2,ix2);
        
        
        
        [ddd] = fminsearch( @do_the_fit,ddd,opt);
        
        gg_ = g_fit_fun(xx2,yy2,ddd(1),ddd(2),ddd(3),I0,ddd(4));

        d_im(yy2(:,1),xx2(1,:)) = d_im(yy2(:,1),xx2(1,:)) - gg_;
        
        
        sz = size(L);
        [X_mod, Y_mod] = meshgrid( 1:sz(2), 1:sz(1));
        
        gg_ = g_fit_fun(X_mod,Y_mod,ddd(1),ddd(2),ddd(3),I0,ddd(4));

        d_im2 = d_im2 - gg_;    
        %---------------------------------------------------------
        %
        % extract the position, width, and intensity of the fitted gaussian
        %
        %---------------------------------------------------------
        
        xpos = ddd(1);
        ypos = ddd(2);
        IG   = ddd(3);
        B    = ddd(4);
        
        
        position_score = mask_crop_for_fit(min(max(1,floor(ypos)),sz(1)), min(max(1,floor(xpos)),sz(2)));
        
        ssLap = size( imLap );
        intx = min([max([1,round(xpos)]),ssLap(2)]);
        
        inty = min([max([1,round(ypos)]),ssLap(1)]);
      
        
        lmk = 0*mk;
        lmk( inty, intx ) = 1;
        lmk = and(bwmorph(lmk,'dilate'),mk_init);
        
        
        Itotal0 = sum(im0( lmk ));
        Imin0   = min(im0( lmk ));
        Imax0   = max(im0( lmk ));

        score = max(im( lmk ));
        intensity_score = Itotal0-Imin0*sum(lmk(:));;
        position_score  = score;
      
        
        raw_intensity = Imax0-Imin0;
        
        
        
        %%
        %---------------------------------------------------------
        %
        % only record the spot if the fit looks good
        %
        %---------------------------------------------------------
        
        if score > 0
            
            spot_num = spot_num+1;
            
            rr(:,i) = [xpos,ypos];
            spot(spot_num).r = [xpos-crop,ypos-crop];
            spot(spot_num).score = score;
            spot(spot_num).intensity_score = intensity_score;
            spot(spot_num).intensity = raw_intensity;
            spot(spot_num).b = B;
            score_array(spot_num) = score;
        end
        
        %%
        %---------------------------------------------------------
        %
        % plots for debugging
        %
        %---------------------------------------------------------
        
        if disp_flag
            
            if score > 0;
                cc = 'w';
            else
                cc = 'b';
            end

            
            theta = 0;
            
            figure(fig_num);
            plot(xpos,ypos,[cc,'.']);
            plot(x,y,['y.']);

            text(xpos+2,ypos,['s:', num2str(score,3)],'Color',cc);
            %text(xpos+2,ypos,[num2str(round(intensity_score*100)/100),'::', num2str(round(score*100)/100)],'Color',cc);
            plot(xpos+B*[0,sin(theta)],ypos+B*[0,cos(theta)],[cc,':']);
            plot(xpos+B*[0,cos(theta)],ypos+B*[0,-sin(theta)],[cc,':']);
            
           
            figure(10);
            plot(xpos,ypos,[cc,'.']);
            plot(x,y,['y.']);
            text(xpos+2,ypos,['s:', num2str(score,3)],'Color','m');

'hi'            
            
            
            %             n=0:.01:1;
            %             theta = n*2*pi;
            %             yt = sin(theta);
            %             xt = cos(theta);
            %             plot(xpos+B*yt,ypos+B*xt,[cc,':']);
        end
        
        %% fix the mean.
        
       
        
    end
end


% % compute the std of the intensity once the loci have bee cropped from the
% % mask mk.
% Istd = std(imLap(mk));
% 
% nspot = numel(spot);
% score_array = zeros(1,nspot);
% 
%  for ii = 1:nspot
%      
%      if isempty(spot(ii).score)
%          spot(ii).score = -100;
%      end
%      score_array(ii) = spot(ii).score/Istd-1;
%      spot(ii).score = score_array(ii);
%      
%  end
 
 spot = spot(score_array>0);
 score_array = score_array(score_array>0);
     
     

%% Sort spots by score so that first spot has the highest score.


[a,b] = sort(score_array,'descend');
spot = spot(b);



%% loop through the im's and fix std


Istd_model = std( d_im2( mk_init ) );

for ii = 1:numel( spot )  
    spot(ii).score = spot(ii).score/Istd_model;
end


%'hi'


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function C = do_the_fit( ddd )
        
        gg = g_fit_fun(xx2,yy2,ddd(1),ddd(2),ddd(3),I0,ddd(4));
        
        %tmp = (im(iy2,ix2)-gg).*mask_crop(iy2,ix2);
        %tmp = (double(imm)-gg).*mask_crop(iy2,ix2);
        %tmp = (double(imm)-gg).*mask_crop(iy2,ix2);
        
        tmp = (double(imm)-gg);%.*mask_crop_for_fit(iy2,ix2);
        C = sum(tmp(logical(mkk)).^2);
        
        if disp_flag
            ddd(4)
         
                  figure(3);
                  imshow( cat(3,ag([gg,imm]),ag([~mkk,~mkk]),0*[mkk,mkk]));
                  '';
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    function C = do_the_fit_backer( ddd )
        
        gg = intMakeBacker( backer, ddd);
        
        C = sum((gg(im_mask)-image(im_mask)).^2);
        
         if disp_flag
         
                  figure(3);
                  imshow( cat(3,ag([gg,image]),ag([~im_mask,~im_mask]),0*[im_mask,im_mask]));
                  '';
                  
                  drawnow;
        end
        
    end

end

%%%%%%%%%%%%%%%%%%
%
% Gaussian Fit function
%
%%%%%%%%%%%%%%%%%%

function C = g_fit_fun(X,Y,x0,y0,IG,I0,b1)

C = I0 + IG*exp( -((X-x0).^2+(Y-y0).^2)/(2*b1^2) );

end

function im_backer = intMakeBacker( backer, ddd )

im_backer = abs(ddd(1)) * backer + ddd(2);

end



