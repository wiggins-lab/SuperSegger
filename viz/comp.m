function [ varargout ] = comp( varargin )
% comp : Makes composite image for the superSegger/trackOpti package.
%
% INPUT :
%
% comp( im_RGB, ... ): Compose im_RGB with other arguments
%
% comp( im_grey, ... ): Compose im_grey (greyscale) in the grey channel
%                       with other arguments
%
% comp( {im_grey,cc} ... ): Compose im_grey (greyscale) in the cc channel
%                           with other arguments. cc can be 'rygcbm....' or
%                           a double triplet
%
% comp( {im_grey,del,cc} ... ): Compose im_grey (greyscale) in the cc channel
%                               with other arguments. cc can be 'rygcbm....' or
%                               a double triplet. del is a double which modulates the
%                               intensity
%
% comp( {im_grey,cc} ... ): Compose im_grey (greyscale) in the cc channel
%                               with other arguments. cc also be false
%                               color
%
%
% comp( {im_grey,cc,'log'} ): Compose im_grey (greyscale) in the cc channel
%                             with other arguments. cc can be 'rygcbm....' or
%                             a double triplet. Log scale.
%
% comp( {im_grey,cc,'log',floor} ): Compose im_grey (greyscale) in the cc channel
%                                   with other arguments. cc can be 'rygcbm....' or
%                                   a double triplet. Log scale with floor floor.
%
% comp( {im_grey,'pow',.5} ): Compose im_grey (greyscale) in the grey channel
%                             Powlaw scale with power .5.
%
% comp( {mask,'r'},... ): Shows logical mask in red
%
% comp( im_grey, {mask,'r'},... ): Shows logical mask in red on top of
%                                  im_grey in the grey channel
%
% comp( im_grey, {regs_label,'label',birth} ):
%                                   Show regs_label regions with label
%                                   birth
%
% comp( {fluor1,'mask', mask,'back',[.3,.3,.3] } )
%                                   Show fluor1 masked by mask with
%                                   backgournd color [.3,.3,.3]
%
% comp( {fluor1,'mask', mask} )
%                                   Show fluor1 masked by mask
%
% comp( {fluor1,[min,max]} )
%                                   Show fluor1 autoscaled with min and max
%
% Copyright (C) 2016 Wiggins Lab
% Written by Paul Wiggins
% University of Washington, 2016
% This file is part of SuperSegger.
%
% SuperSegger is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version
%
% SuperSegger is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with SuperSegger.  If not, see <http://www.gnu.org/licenses/>.


label_flag = false;

im_comp = [];


% read the commands
% loop through all input arguments
for ii = 1:nargin
    
    data = varargin{ii};
    
    im   = [];
    del  = [];
    cc   = [];
    com  = [];

    com2 = [];
    
    min_ = [];
    max_ = [];
    
    % if the argument is a cell, then read the commands contained to format
    % the image
    if iscell( data )
        numin = numel( data );
        
        
        
        if numin == 0
            
        else
            % The first argument is always an image
            im = data{1};
            
            % set the cell argument counter to zer and get the next
            jj = 2;
            
            com  = {};
            com2 = {};
            ncom = 0;
            
            min_ = [];
            max_ = [];
            % loop through the arguments

            while jj<=numin
                
                % if the argument is a single char, it is a color
                if ischar(data{jj})
                    if numel( data{jj} ) == 1
                        cc = data{jj};
                    else
                        % if the argument is multiple characters, then it
                        % is a command not a color
                        
                        ncom = ncom + 1;
                        com{ncom} =  data{jj};
                        
                        % if there are no more entries, then put ID in com2
                        if jj+1 > numin
                            com2{ncom} = 'ID';
                        else
                            % if there are more entries, each the next
                            % entry as the argument.
                            com2{ncom} = data{jj+1};
                        end
                        
                        % advance the counter to compensate for eating the
                        % argument.
                        jj = jj + 1;
                        
                    end
                elseif all(isnumeric( data{jj} ))
                    % if the argument is numeric, it specifies the
                    % relative intensity
                    if numel(data{jj}) == 1
                        del = data{jj};
                        % if the argument is numeric, with two entries it is a
                        % min and a max
                    elseif numel(data{jj}) == 2
                        
                        min_ = data{jj}(1);
                        max_ = data{jj}(2);
                        % else it is a color or colormap
                    else
                        cc = data{jj};
                    end
                end
                
                % augment the counter
                jj = jj + 1;
                
            end
        end
    else
        % if the argeument isn't a cell, then it must be an image.
        im = data;
        del = [];
        cc = [];
    end
    
    % if the color isn't specified, make it white for argument 1 and
    % alternate the color automatically for later arguments.
    if isempty( cc )
        if ii == 1
            cc = [1,1,1];
        else
            cc = [0,0,0];
            
            ind = mod(ii-2,3)+1;
            
            cc( ind ) = 1;
        end
        % is the color is a char, make it a triplet
    elseif ischar( cc)
        cc = convert_color( cc );
    end
    
    if isempty( del )
        
        % make default intensity 1
        
        %if ~isempty( im ) && islogical( im )
        %    del = 0.2;
        %else
        del = 1;
        %end
        
    end
    
    % if the image isn't empty, go on
    if ~isempty( im )
        
        
        mask = [];
        back = [0,0,0];
        modx  = 0;
        log_flag = false;
        pow_flag = false;
        
        % process commands
        if ~isempty( com )
            
            for ii = 1:ncom
                
                com_  = com{ii};
                com2_ = com2{ii};
                
                if strcmp( com_, 'label' )
                    label_flag = true;
                    
                    
                    if ischar( com2 )
                        com2__ = com2;
                    else
                        com2__ = '';
                    end
                    
                    ID_flag = false;
                    if strcmp( com2__, 'ID' )
                        com2__ = '';
                        ID_flag = true;
                    end
                    
                    
                    if isempty( com2__ )
                        str = {'Centroid'};
                    else
                        str = {'Centroid',com2__};
                    end
                    
                    props = regionprops( im, str );
                    
                    
                    if ID_flag
                        vec = 1:numel(props);
                        
                    elseif ischar( com2_ )
                        vec = drill( props, ['.',com2__] );
                    else
                        vec = com2_;
                    end
                end
                
                
                if isnan( min_ )
                    min_ = [];
                end
                if isnan( max_ )
                    max_ = [];
                end
                
                if strcmp( com_,'log' )
                    log_flag = true;
                    
                    if isempty( com2_ ) || strcmp( com2_, 'ID' )
                        modx = 0;
                    else
                        modx = com2_;
                    end
                end
                
                if strcmp( com_,'pow' )
                    pow_flag = true;
                    
                    modx = com2_;
                end
                
                % if the image in masked, load a mask
                if strcmp( com_,'mask' )
                    mask = double(com2_);
                end
                
                if strcmp( com_,'back' )
                    back = double(com2_);
                end
            end
        end
        
        
        % Make the image here:
        
        if log_flag
            backer = double(ag( log(double(im+modx)) ));
        elseif pow_flag
            backer = double(ag( (double(im).^modx) ));
        elseif ndims( im ) == 2
            backer = double(ag( im, min_, max_ )); 
            %[min_,max_]
        end
        
        
        
        if ndims( im ) == 3
            
            
            % if the image is rgb already, keep it this way
            if strcmp( class(im), 'double' )
                if isempty(im_comp)
                    im_comp = im*255;
                else
                    im_comp = im_comp + im*255;
                end
            else
                if isempty(im_comp)
                    im_comp = uint8(im);
                else
                    im_comp = im_comp +  uint8(im);
                end
            end
            % if the number of entries in the vector is great than 3, cc is
            % a colormap
        elseif numel(cc)>3
            im_tmp = uint8(255*(doColorMap( backer, cc )));
            
            if isempty( im_comp )
                im_comp = im_tmp;
            else
                im_comp = im_comp + im_tmp;
            end
            
        else
            
            if isempty( im_comp )
                im_comp = uint8(cat(3, backer*del*cc(1), backer*del*cc(2), backer*del*cc(3) ));
            else
                %disp('new');
                for ii = 1:3
                    im_comp(:,:,ii) = im_comp(:,:,ii) + uint8(backer*del*cc(ii));%, backer*del*cc(2), backer*del*cc(3) );
                end
            end
            
            
        end
    end
    
    if exist( 'mask', 'var' ) && ~isempty( mask )
        for ii = 1:3;
            im_comp(:,:,ii) = uint8(double(im_comp(:,:,ii)).*mask)+uint8(255*(1-mask)*back(ii));
        end
    end
    
%    if isempty( im_comp )
%        im_comp = im_tmp;
%    else
%        im_comp = im_comp + im_tmp;
%    end
    
    
    
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