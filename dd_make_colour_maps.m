function cmap = dd_make_colour_maps(varargin)
%
% This function generates colour maps for the requested colours. The
% colours that can be requested include:
% 'black'
% 'orange'
% 'skyblue'
% 'bluishgreen'
% 'yellow'
% 'blue'
% 'vermillion'
% 'reddishpurple'
%
% Colour schemes are derived from https://jfly.uni-koeln.de/color/
%
% This function is called by display_group_results_erp and display_indiv_results_erp,
% but can also be called by custom plotting scripts such as
% EXAMPLE_plot_individual_results.
% 
%
% Inputs:
%
%   Strings containing the colours that are requested to be generated. See
%   the list of colours available above.
%
%
% Outputs:
% 
%   cmap    Colour map matrix containing the colours that were requested
%
%
%
% Usage:        cmap = dd_make_colour_maps(varargin)
%
%
% Example:      cmap = dd_make_colour_maps('blue', 'orange', 'reddishpurple')
%
%
% Copyright (c) 2013-2020: DDTBOX has been developed by Stefan Bode 
% and Daniel Feuerriegel with contributions from Daniel Bennett and 
% Phillip M. Alday, and others. 
%
% This file is part of DDTBOX and has been written by Patrick Cooper and
% has been adapted for DDTBOX by Daniel Feuerriegel
%
% DDTBOX is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.



%% Handling Variadic Inputs

if nargin == 1
    
    % Only one map selected
    map_mode = 'qual';
    map_names = varargin;
    
else
    
    if ~ismember(varargin,'mode')
        
        map_names = varargin;
        map_mode = 'qual';
        
    else
        
        % Find 'mode' position within list of arguments
        % Take the next argument as the mapMode
        mode_ind = find(ismember(varargin,'mode'));
        map_mode = varargin{mode_ind + 1};
        colour_inds = ~ismember(varargin, {'mode', varargin{mode_ind + 1}});
        map_names = varargin(colour_inds);
        n_colour_bins = 65; % Hard coded for now, can add code to change this if desired by user in a future release
        
    end % of if ~ismember
    
end % of if nargin



%% Create Colour Maps

if strcmpi(map_mode,'qual')
    
    cmap = zeros(length(map_names), 3);
    
elseif strcmpi(map_mode,'div')
    
    cmap = zeros(n_colour_bins, 3);
    mid_point = ceil(n_colour_bins / 2);
    cmap(mid_point,:) = [185, 185, 185];
    
end % of if strcmpi mapMode

switch map_mode
    
    case 'qual'
        
        for map_i = 1:length(map_names)
            
            current_map_name = lower(map_names{map_i}); % Ensure all lowercase, in case of accidental capitalisation
            map = assign_colour(current_map_name);
            cmap(map_i,:) = map;
            
        end % of for map_i
        
        cmap = cmap ./ 256;
        
    case 'div'
        
        % Create colour space moving from low colour to midpoint
        current_map_name = lower(map_names{1});
        map = assign_colour(current_map_name);
        
        % Create linearly spaced colour scheme
        for rgb_i = 1:3
            
            cmap(1:mid_point - 1, rgb_i) = linspace(map(1,rgb_i), cmap(mid_point,rgb_i), floor(n_colour_bins / 2));
            
        end % of for rgb_i
        
        % Create colour space moving from midpoint to high colour
        current_map_name = lower(map_names{end});
        map = assign_colour(current_map_name);
        
        % Create linearly spaced colour scheme
        for rgb_i = 1:3
            
            cmap(mid_point + 1 : end, rgb_i) = linspace(cmap(mid_point, rgb_i), map(1, rgb_i), floor(n_colour_bins / 2));
            
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