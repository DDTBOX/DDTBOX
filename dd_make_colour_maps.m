function cmap = dd_make_colour_maps(varargin)
%
% STILL TO MAKE DDTBOX COMPATIBLE HEADER
%
% STILL TO CONVERT VARIABLE NAMING STYLE
%
% cmap = colourFriendlyMaps(map1,varargin)
% Create colour-blind-friendly colour schemes for graphs
% To use, simply enter colour names you wish to stitch together for
% your colour map
% Example: cmap = colourFriendlyMaps('black','orange');
% Alternatively, if you wish to create a divergent colour map
% enter tag 'mode' followed by 'div'
% code will then extract first colour label as lower bound and
% final as upper bound
% Example: cmap = colourFriendlyMaps('mode','div','orange','blue')
% this will create a colour map where lower values are coloured shades of
% orange and higher values as shades of blue
% currently, the middle colour will always be grey
%
% % Potential colour scheme names are as follows:
% -----
% black, orange, skyBlue, yellow, blue, vermillion, reddishPurple
% -----
% Colour schemes are derived from https://jfly.uni-koeln.de/color/
% Patrick Cooper, November, 2019


if nargin == 1
    
    % Only one map selected
    mapMode = 'qual';
    mapNames = varargin;
    
else
    
    if ~ismember(varargin,'mode')
        
        mapNames = varargin;
        mapMode = 'qual';
        
    else
        
        % Find 'mode' position within list of arguments
        % Take the next argument as the mapMode
        modeInd = find(ismember(varargin,'mode'));
        mapMode = varargin{modeInd + 1};
        colourInds = ~ismember(varargin, {'mode', varargin{modeInd + 1}});
        mapNames = varargin(colourInds);
        nColourBins = 65; % Hard coded for now, can add code to change this if desired by user in a future release
        
    end % of if ~ismember
    
end % of if nargin

if strcmpi(mapMode,'qual')
    
    cmap = zeros(length(mapNames), 3);
    
elseif strcmpi(mapMode,'div')
    
    cmap = zeros(nColourBins, 3);
    midPoint = ceil(nColourBins / 2);
    cmap(midPoint,:) = [185, 185, 185];
    
end % of if strcmpi mapMode

switch mapMode
    
    case 'qual'
        
        for map_i = 1:length(mapNames)
            
            currentMapName = lower(mapNames{map_i}); % Ensure all lowercase, in case of accidental capitalisation
            map = assign_colour(currentMapName);
            cmap(map_i,:) = map;
            
        end % of for map_i
        
        cmap = cmap ./ 256;
        
    case 'div'
        
        %create colour space moving from low colour to midpoint
        currentMapName = lower(mapNames{1});
        map=assign_colour(currentMapName);
        
        % Create linearly spaced colour scheme
        for rgb_i = 1:3
            
            cmap(1:midPoint - 1, rgb_i) = linspace(map(1,rgb_i), cmap(midPoint,rgb_i), floor(nColourBins / 2));
            
        end % of for rgb_i
        
        % Create colour space moving from midpoint to high colour
        currentMapName = lower(mapNames{end});
        map = assign_colour(currentMapName);
        
        % Create linearly spaced colour scheme
        for rgb_i = 1:3
            
            cmap(midPoint + 1 : end, rgb_i) = linspace(cmap(midPoint,rgb_i), map(1,rgb_i), floor(nColourBins / 2));
            
        end % of for rgb_i
        
        cmap = cmap ./ 256;
        
end % of switch mapMode



% Helper function to quickly look up colour names and associated RGB values
function map = assign_colour(current_map_name)

    switch current_map_name

        case 'black'

            map = [0 0 0];

        case 'orange'

            map = [230 159 0];

        case 'skyblue'

            map = [86 180 233];

        case 'bluishgreen'

            map = [0 158 115];

        case 'yellow'

            map = [240 228 66];

        case 'blue'

            map = [0 114 178];

        case 'vermillion'

            map = [213 94 0];

        case 'reddishpurple'

            map = [204 121 167];

    end % of switch current_map_name

end % of function assign_colour



end % of function dd_make_colour_maps