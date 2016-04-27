function cm = hotcoldinv( numC )

dd = ceil((numC-1)/2);
cc = ((1:numC)-dd-1)'/dd;
cm = [abs(1+cc).*(cc<=0)+(cc>0),(1-cc).*(cc>0)+(cc<=0),1-abs(cc)];

end