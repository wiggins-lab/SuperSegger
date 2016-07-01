function [ varargout ] = comp( varargin )
% comp  : creates composite image

label_flag = false;

im_comp = [];

for ii = 1:nargin
    
    data = varargin{ii};

    im   = [];
    del  = [];
    cc   = [];
    com  = [];
    com2 = [];
    
    
    if iscell( data )
        numin = numel( data );
        

        
        if numin == 0
            
        else
            im = data{1};
            
            jj = 2;
            
            while jj<=numin
                
                if ischar(data{jj})
                    if numel( data{jj} ) == 1
                        cc = data{jj};
                    else
                        com =  data{jj};
                        
                        if jj+1 > numin
                            com2 = 'ID';
                        else
                            com2 = data{jj+1};
                        end
                        
                        jj = jj + 1;
                        
                    end
                elseif all(isnumeric( data{jj} ))
                    if numel(data{jj}) == 1
                        del = data{jj};
                    else
                        cc = data{jj};
                    end
                end
                
                jj = jj + 1;
                
            end
        end
    else
        im = data;
        del = [];
        cc = [];
    end
    
    if isempty( cc )
        if ii == 1
            cc = [1,1,1];
        else
            cc = [0,0,0];
            
            ind = mod(ii-2,3)+1;
            
            cc( ind ) = 1;
        end
    elseif ischar( cc)
        cc = convert_color( cc );
    end
    
    if isempty( del )
        
        if ~isempty( im ) && islogical( im )
            del = 0.2;
        else
            del = 1;
        end
        
    end
    
    if ~isempty( im )
        
        
        if ~isempty( com )
            
            if strcmp( com, 'label' )
               label_flag = true;

                
                if ischar( com2 )
                    com2_ = com2;
                else
                    com2_ = '';
                end
                
                ID_flag = false;
                if strcmp( com2_, 'ID' )
                    com2_ = '';
                    ID_flag = true;
                end
                
                
                if isempty( com2_ )
                    str = {'Centroid'};
                else
                    str = {'Centroid',com2_};
                end
                
                props = regionprops( im, str );
                
                
                if ID_flag
                    vec = 1:numel(props);
                    
                elseif ischar( com2 )
                    vec = drill( props, ['.',com2_] );
                else
                    vec = com2;
                end
            end
        end

        if strcmp( com,'log' )
            if isempty( com2 ) || strcmp( com2, 'ID' )
               com2 = 0;
            end
            
            backer = double(ag( log(double(im+com2)) ));
            
        elseif strcmp( com,'pow' )
            backer = double(ag( (double(im).^com2) ));
        else
            backer = double(ag( im ));
        end
        
        if numel(cc)>3
            im_tmp = (255*(doColorMap( backer, cc )));
        else
            im_tmp = cat(3, backer*del*cc(1), backer*del*cc(2), backer*del*cc(3) );
        end
        
        if isempty( im_comp )
            im_comp = im_tmp;
        else
            im_comp = im_comp + im_tmp;
        end
        
            
        
    end
end

im_comp = uint8(im_comp);

if nargout == 0
    imshow( im_comp );
    varargout = {};
    
    if label_flag 
        hold on;
        x = drill( props, '.Centroid(1)' );
        y = drill( props, '.Centroid(2)' );
        
        vec = reshape( vec, size(x) );
        text( x, y, num2str( vec, '%2.2g' ) );
        
    end
else
    varargout{1} = im_comp;
end

end


%% From the internet
% by Ben Mitch
% 06 Jun 2002 (Updated 07 Jun 2002)
% Convert colour names (blue,teal,pale green) into RGB triplets.

function outColor = convert_color(inColor)

  charValues = 'rgbcmywk'.';  %#'
  rgbValues = [eye(3); 1-eye(3); 1 1 1; 0 0 0];
  assert(~isempty(inColor),'convert_color:badInputSize',...
         'Input argument must not be empty.');

  if ischar(inColor)  %# Input is a character string

    [isColor,colorIndex] = ismember(inColor(:),charValues);
    assert(all(isColor),'convert_color:badInputContents',...
           'String input can only contain the characters ''rgbcmywk''.');
    outColor = rgbValues(colorIndex,:);

  elseif isnumeric(inColor) || islogical(inColor)  %# Input is a numeric or
                                                   %#   logical array
    assert(size(inColor,2) == 3,'convert_color:badInputSize',...
           'Numeric input must be an N-by-3 matrix');
    inColor = double(inColor);           %# Convert input to type double
    scaleIndex = max(inColor,[],2) > 1;  %# Find rows with values > 1
    inColor(scaleIndex,:) = inColor(scaleIndex,:)./255;  %# Scale by 255
    [isColor,colorIndex] = ismember(inColor,rgbValues,'rows');
    assert(all(isColor),'convert_color:badInputContents',...
           'RGB input must define one of the colors ''rgbcmywk''.');
    outColor = charValues(colorIndex(:));

  else  %# Input is an invalid type

    error('convert_color:badInputType',...
          'Input must be a character or numeric array.');

  end
  
  
end