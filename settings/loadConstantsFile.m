function CONST = loadConstantsFile( filename )
% Needed for back compatibility.
% fixes old loadConstants files...
%

CONST0 = [];

% view constants
CONST0.view.showFullCellCycleOnly = false; % only uses full cell cycle for analysis tools
CONST0.view.orientFlag = true; % to orient the cells along the horizontal axis for the analysis tools
CONST0.view.falseColorFlag = false;
CONST0.view.fluorColor = {'g','r','b','c','o','y'}; % order of channel colors to be used for display
CONST0.view.LogView = false;
CONST0.view.filtered = 1;
CONST0.view.maxNumCell = []; % maximum number of cells used for analysis tools
CONST0.view.background = [0.7, 0.7, 0.7];


if exist( filename, 'file' )
 CONST = load( filename );
 CONST = intFixFields( CONST, CONST0 );
else
    disp( ['File ',filename, ' does not exist.'] );
    CONST = [];
end


end