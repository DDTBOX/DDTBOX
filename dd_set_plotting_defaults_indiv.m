function PLOT = dd_set_plotting_defaults_indiv(cfg)
%
% This function sets plotting defaults for displaying results of
% single subject decoding performance results.
% All settings are stored in a structure called PLOT. 
% These default values can be changed by modifying the hard-coded variables
% within this function.
% 
% This function is called by decoding_erp.
%
%
% Inputs:
% 
% cfg       Structure containing configuration settings used for decoding.
%           This includes variables that are used to customise plot
%           settings.
%
% Outputs:
%
% PLOT      Structure containing settings for plotting group-level decoding performance results
%
% Usage:   PLOT = dd_set_plotting_defaults_indiv
%
%
% Copyright (c) 2013-2019: DDTBOX has been developed by Stefan Bode 
% and Daniel Feuerriegel with contributions from Daniel Bennett and 
% Phillip M. Alday. 
%
% This file is part of DDTBOX and has been written by Stefan Bode
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



%% Figure Position on the Screen

PLOT.FigPos = [100, 100, 800, 400];



%% Plot Background Colour
PLOT.background_colour = [1, 1, 1];



%% Figure Title

PLOT.TitleFontSize = 18;
PLOT.TitleFontWeight = 'Bold'; % 'Normal' (Regular) or 'Bold'



%% X and Y Axis Properties

% Axis label properties
PLOT.xlabel.FontSize = 16;
PLOT.ylabel.FontSize = 16;
PLOT.xlabel.FontWeight = 'Bold'; % 'Normal' (Regular) or 'b' / 'Bold'
PLOT.ylabel.FontWeight = 'Bold'; % 'Normal' (Regular) or 'b' / 'Bold'

% Set font size for X and Y axis tick labels
PLOT.XY_tick_labels_fontsize = 14;


% Determine how many time steps between X axis ticks
% (e.g., with 10ms steps, a value of 5 means one X axis label every 50ms)
if isempty(cfg.x_tick_spacing_steps)

    % Set default of 5 time windows spacing
    PLOT.x_tick_spacing = 5;

else % If this has been set by user
    
    PLOT.x_tick_spacing = cfg.x_tick_spacing_steps;
    
end % of if isempty


% Y tick spacing for classification and regression
PLOT.y_tick_spacing = 10;
PLOT.y_tick_spacing_regress = 0.2;



%% Lines Showing Decoding Performance

% Actual decoding results
PLOT.Res.Line = '-'; % Line colour and style

PLOT.Res.LineColour = 'blue';
% Options for current dd_make_colour_maps function
% 'black'
% 'orange'
% 'skyblue'
% 'bluishgreen'
% 'yellow'
% 'blue'
% 'vermillion'
% 'reddishpurple'

PLOT.Res.LineWidth = 2;
PLOT.Res.MarkerEdgeColor = 'k';
PLOT.Res.MarkerFaceColor = 'w';
PLOT.Res.MarkerSize = 5;

% Properties of line showing permutation / chance results
PLOT.PermRes.Line = '-'; % Line colour and style

PLOT.PermRes.LineColour = 'orange';
% Options for current dd_make_colour_maps function
% 'black'
% 'orange'
% 'skyblue'
% 'bluishgreen'
% 'yellow'
% 'blue'
% 'vermillion'
% 'reddishpurple'

PLOT.PermRes.LineWidth = 2;
PLOT.PermRes.MarkerEdgeColor = 'b';
PLOT.PermRes.MarkerFaceColor = 'w';
PLOT.PermRes.MarkerSize = 5;



%% Line Marking Event Onset

% Define properties of line showing event onset
PLOT.PointZero.Color = [0.5, 0.5, 0.5]; % Colour of line denoting event onset
PLOT.PointZero.LineWidth = 3; % Width of line denoting event onset



%% Temporal Decoding Results Plotting Settings

PLOT.temporal_decoding_colormap = 'jet'; % Colormap for temporal decoding results scalp maps