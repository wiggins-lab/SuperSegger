function displayMap (data_c,data_r, rCellsFromC, cCellsTransp,cCellsFromR,rCellsTransp)
% intDisplay : displays linking - used for debugging.
% reg : maskF
% green : maskC
% blue : all cell masks  in c

%disp ([num2str(cCellsTransp), ' map to - > ' , num2str(rCellsFromC), ' and  maps to - > ', num2str(cCellsFromR), ' which maps to ' , num2str(rCellsTransp)]);
maskCtransp = data_c.regs.regs_label*0;
maskC = maskCtransp;
maskR = maskCtransp;
maskRtransp = maskCtransp;
   
for c = 1 : numel(cCellsTransp)
    maskCtransp = maskCtransp + (data_c.regs.regs_label == cCellsTransp(c))>0;
end

for c = 1 : numel(cCellsFromR)
    maskC = maskC + (data_c.regs.regs_label == cCellsFromR(c))>0;
end

if ~isempty (data_r)
 
    for f = 1 : numel(rCellsFromC)
        maskR = maskR + (data_r.regs.regs_label == rCellsFromC(f))>0;
    end
    
    for f = 1 : numel(rCellsTransp)
        maskRtransp = maskRtransp + (data_r.regs.regs_label == rCellsTransp(f))>0;
    end
end

 imshow (cat(3,0.5*ag(maskRtransp) + ag(maskR),0.8*ag(maskC)+0.5*ag(maskCtransp), ...
     0.8*ag(maskCtransp) + 0.8*ag(maskRtransp) +  0.2* ag(data_c.mask_cell)));

end

