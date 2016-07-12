%im = imread('/Users/Stella/Documents/MATLAB/2A_crop/raw_im/2016-06-16_zstack007t123xy2c1.tif');
%im4 = imresize(im,4);
img = imc;
factor =  4;
imNew = imresize(img, factor);

CONST = loadConstants('60xeclbResCurv25');

CONST4 = CONST;
CONST4.general.dataPixelSize = CONST4.general.trainedPixelSize/ factor;

data = superSeggerOpti (img,[],1,CONST);
%[data, err_flag] = ssoSegFunPerReg( img, CONST, '', [], [])


data4 = superSeggerOpti (imNew,[],0,CONST4);

subplot(1,2,1)
showSegDataPhase(data)
subplot(1,2,2)
showSegDataPhase(data4)