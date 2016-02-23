function bb = addBB( bb1, bb2 );
% creates a bounding box

ymin = min([bb1(2),bb2(2)]);
xmin = min([bb1(1),bb2(1)]);
ymax = max([bb1(2)+bb1(4),bb2(2)+bb2(4)]);
xmax = max([bb1(1)+bb1(3),bb2(1)+bb2(3)]);

bb = [xmin, ymin, xmax-xmin, ymax-ymin];
end