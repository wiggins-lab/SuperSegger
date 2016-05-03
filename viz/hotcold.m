function cm = hotcold( numC )
% hotcold : used for colormaps.
dd = ceil((numC-1)/2);
cc = ((1:numC)-dd-1)'/dd;
cm = [cc.*(cc>0),abs(cc).*(cc<0),0*cc];

end