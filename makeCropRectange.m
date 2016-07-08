function pos = makeCropRectange ()


%imrect(handles.viewport_train);
Rect = imrect();
setColor(Rect,'green')
setFixedAspectRatioMode(Rect,1);
fcn = makeConstrainToRectFcn('imrect',get(gca,'XLim'),get(gca,'YLim'));
setPositionConstraintFcn(Rect,fcn); 
pos = getPosition(Rect);

