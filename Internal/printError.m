function [] = printError( ME )
%PRINTERROR Print message passed by catch statement
disp( getReport( ME, 'extended', 'hyperlinks', 'on' )); 
end

