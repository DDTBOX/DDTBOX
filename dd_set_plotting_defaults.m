function PLOT = dd_set_plotting_defaults(ANALYSIS)
%
% This function sets plotting defaults for displaying results of
% group-level statistical analyses of decoding performance results.
% All settings are stored in a structure called PLOT. 
% These default values can be changed by modifying the hard-coded variables
% within this function.
% 
% This function is called by analyse_decoding_erp.
%
%
% Inputs:
% 
% ANALYSIS  Structure containing settings for group-level statistical
%           analyses and plotting.
%
%
% Outputs:
%
% PLOT      Structure containing settings for plotting group-level decoding performance results
%
%
% Usage:   PLOT = dd_set_plotting_defaults(ANALYSIS)
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



%% X/Y-Axis Limits and Tick Marks

% Set font size for X and Y axis tick labels
PLOT.XY_tick_labels_fontsize = 14;

% Y-axis depends on analysis mode
if ANALYSIS.analysis_mode ~= 3 % If not using SVR
    
    PLOT.Y_min = 40; % Y axis lower bound (in % accuracy)
    PLOT.Y_max = 80; % Y axis upper bound (in % accuracy)
    PLOT.Ysteps = 5; % Interval between Y axis labels/tick marks
    
elseif ANALYSIS.analysis_mode == 3 % If using SVR
    
    PLOT.Y_min = -0.5; % Y axis lower bound (Fisher-Z corr coeff)
    PLOT.Y_max = 0.5; % Y axis upper bound (Fisher-Z corr coeff)
    PLOT.Ysteps = 0.1; % Interval between Y axis labels/tick marks
    
end % of if ANALYSIS.analysis_mode

PLOT.X_min = 1; % X axis lower bound (first time point)
PLOT.X_max = ANALYSIS.xaxis_scale(2,end); % Maximum value of X axis value. 

% Determine how many time steps between X axis ticks
% (e.g., with 10ms steps, a value of 5 means one X axis label every 50ms)
if isempty(ANALYSIS.disp.x_tick_spacing_steps)

    % Set default of 5 time windows spacing
    PLOT.x_tick_spacing = 5;

else % If this has been set by user
    
    PLOT.x_tick_spacing = ANALYSIS.disp.x_tick_spacing_steps;
    
end % of if isempty

% Default is ANALYSIS.xaxis_scale(2,end) which is the last time window selected for group-level analyses.
PLOT.Xsteps = ANALYSIS.step_width_ms;

PLOT.Ytick = [PLOT.Y_min : PLOT.Ysteps : PLOT.Y_max];


PLOT.Xtick = [ANALYSIS.xaxis_scale(1,1) : PLOT.x_tick_spacing : ANALYSIS.xaxis_scale(1, end)];

PLOT.XtickLabel = ANALYSIS.xaxis_scale(2, 1 : PLOT.x_tick_spacing : end) - ANALYSIS.pointzero; 



%% Line Marking Event Onset

PLOT.PointZero.Color = [0.5, 0.5, 0.5]; % Colour of line denoting event onset
PLOT.PointZero.LineWidth = 3; % Width of line denoting event onset
PLOT.PointZero.Point = find(ANALYSIS.data(3,:) == 1);



%% Statistical Significance Markers

% Shading colour
PLOT.Sign.LineColor = 'reddishpurple';
% Options for current dd_make_colour_maps function
% 'black'
% 'orange'
% 'skyblue'
% 'bluishgreen'
% 'yellow'
% 'blue'
% 'vermillion'
% 'reddishpurple'


PLOT.Sign.LineWidth = 10;

if ANALYSIS.analysis_mode ~= 3 % If not using SVR
    
    PLOT.Sign.LinePos = [PLOT.Y_min + 0.5, PLOT.Y_max - 0.5];
    
elseif ANALYSIS.analysis_mode == 3 % If using SVR
    
    PLOT.Sign.LinePos = [PLOT.Y_min, PLOT.Y_max];
    
end % of if ANALYSIS.analysis_mode



%% Line Showing Decoding Performance and Error Bars

% Decoding performance results line
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

% Alpha level (0-1) for shading that depicts standard errors. Higher values
% denote stronger (more opaque) shading
PLOT.Res.ShadingAlpha = 0.3;



%% Line Showing Permutation / Chance Results

% Permutation results / chance line
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



%% Axis Labels

% X and Y axis labels
PLOT.xlabel.FontSize = 16;
PLOT.ylabel.FontSize = 16;
PLOT.xlabel.FontWeight = 'Bold'; % 'Normal' (Regular) or 'b' / 'Bold'
PLOT.ylabel.FontWeight = 'Bold'; % 'Normal' (Regular) or 'b' / 'Bold'

% X axis label text
PLOT.xlabel.Text = 'Time-steps [ms]';

% Y axis label text
if ANALYSIS.analysis_mode ~= 3 % If not using SVR
    
    PLOT.ylabel.Text = 'Classification Accuracy [%]';
    
elseif ANALYSIS.analysis_mode == 3 % If using SVR
    
    PLOT.ylabel.Text = 'Fisher-transformed correlation coeff';
    
end % of if ANALYSIS.analysis_mode



%% Figure Title Properties

PLOT.TitleFontSize = 18;
PLOT.TitleFontWeight = 'Bold'; % 'Normal' (Regular) or 'b' / 'Bold'

% Text specifying the decoding method used
if ANALYSIS.stmode == 1 && ANALYSIS.analysis_mode ~=3
    
    PLOT.TitleString = 'Spatial SVM ';
    
elseif ANALYSIS.stmode == 2 && ANALYSIS.analysis_mode ~=3
    
    PLOT.TitleString = 'Temporal SVM ';
    
elseif ANALYSIS.stmode == 3 && ANALYSIS.analysis_mode ~=3
    
    PLOT.TitleString = 'Spatiotemporal SVM ';
    
elseif ANALYSIS.stmode == 1 && ANALYSIS.analysis_mode ==3
    
    PLOT.TitleString = 'Spatial SVR';  
    
elseif ANALYSIS.stmode == 2 && ANALYSIS.analysis_mode ==3
    
    PLOT.TitleString = 'Temporal SVR '; 
    
elseif ANALYSIS.stmode == 3 && ANALYSIS.analysis_mode ==3
    
    PLOT.TitleString = 'Spatiotemporal SVR '; 
    
end % of if ANALYSIS.stmode
