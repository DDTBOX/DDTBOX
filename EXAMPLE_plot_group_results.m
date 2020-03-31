% EXAMPLE_plot_group_results.m
%
% This script is used for plotting group-level results of 
% classifier accuracy/SVR performance and feature weight analyses.
% Group-level statistical analyses must be performed before running this script.
%
% More information about the settings in this script can be found in the
% DDTBOX wiki, available at: https://github.com/DDTBOX/DDTBOX/wiki
%
% Please make copies of this script for your own projects.
%
% This script calls display_group_results_erp and
% display_feature_weights_results, both of which are included in DDTBOX.
%
%
% Copyright (c) 2013-2020: DDTBOX has been developed by Stefan Bode 
% and Daniel Feuerriegel with contributions from Daniel Bennett and 
% Phillip M. Alday. 
%
% This file is part of DDTBOX and has been written by Daniel Feuerriegel
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



%% General Settings

% Full filepath of group results file
group_results_file = ['/Users/danielfeuerriegel/DDTBOX/Decoding Results/EXAMPLE_GROUPRES_NSBJ5_win10_steps10_av1_st1_SVM_LIBSVM_DCGA vs. C.mat'];

% Load the data file to get ANALYSIS parameters
load(group_results_file);

% Select whether to plot decoding performance and feature weights results
% 1 = plot / 0 = don't plot
PLOT.decoding_performance_results = 1; 
PLOT.feature_weights_results = 0;

% Background colour for the figure
PLOT.background_colour = [1, 1, 1]; % RGB values. Default [1, 1, 1] (white)

% Plotting style (options include 'cooper' and 'classic')
ANALYSIS.disp.plotting_mode = 'classic';



%% Settings For Group Decoding Performance Results (Classification Accuracy / SVR Performance)

ANALYSIS.permdisp = 1; % Display results from permuted labels analyses in the figure as separate line? 0 = no / 1 = yes
ANALYSIS.disp.sign = 1; % Mark statistically significant steps in results figure? 0 = no / 1 = yes
ANALYSIS.plot_robust = 0; % Choose estimate of location to plot. 0 = arithmetic mean / 1 = trimmed mean / 2 = median
% Note: You can plot the mean even if the data were originally plotted with
% the median or trimmed mean when performing group-level analyses.
% If you originally plotted the trimmed mean, then you can also plot the median in this script.

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

ANALYSIS.disp.temporal_decoding_colormap = 'jet'; % Colormap for temporal decoding results scalp maps

% Figure position on the screen
PLOT.FigPos = [100, 100, 800, 400];

% Figure title settings
PLOT.TitleFontSize = 18;
PLOT.TitleFontWeight = 'Bold'; % 'Normal' (Regular) or 'b' / 'Bold'

% Title text automatically generated based on the decoding method used
if ANALYSIS.stmode == 1 && ANALYSIS.analysis_mode ~=3 % Spatial SVM Classification
    
    PLOT.TitleString = 'Spatial SVM ';
    
elseif ANALYSIS.stmode == 2 && ANALYSIS.analysis_mode ~=3 % Temporal SVM Classification
    
    PLOT.TitleString = 'Temporal SVM ';
    
elseif ANALYSIS.stmode == 3 && ANALYSIS.analysis_mode ~=3 % Spatiotemporal SVM Classification
    
    PLOT.TitleString = 'Spatiotemporal SVM ';
    
elseif ANALYSIS.stmode == 1 && ANALYSIS.analysis_mode ==3 % Spatial SVR
    
    PLOT.TitleString = 'Spatial SVR';  
    
elseif ANALYSIS.stmode == 2 && ANALYSIS.analysis_mode ==3 % Temporal SVR
    
    PLOT.TitleString = 'Temporal SVR '; 
    
elseif ANALYSIS.stmode == 3 && ANALYSIS.analysis_mode ==3 % Spatiotemporal SVR
    
    PLOT.TitleString = 'Spatiotemporal SVR ';  
    
end % of if ANALYSIS.stmode




%% Decoding Performance X and Y Axis Properties

% Number of time steps per X axis tick label
% Set default of 5 time windows spacing
PLOT.x_tick_spacing = 10;

% Axis label properties
PLOT.xlabel.FontSize = 16;
PLOT.ylabel.FontSize = 16;
PLOT.xlabel.FontWeight = 'Bold'; % 'Normal' (Regular) or 'b' / 'Bold'
PLOT.ylabel.FontWeight = 'Bold'; % 'Normal' (Regular) or 'b' / 'Bold'

% Size of X tick labels
PLOT.XY_tick_labels_fontsize = 14;

% X axis label text
PLOT.xlabel.Text = 'Time-steps [ms]';

% Y axis label text
if ANALYSIS.analysis_mode ~= 3 % If not using SVR
    
    PLOT.ylabel.Text = 'Classification Accuracy [%]';
    
elseif ANALYSIS.analysis_mode == 3 % If using SVR
    
    PLOT.ylabel.Text = 'Fisher-transformed correlation coeff';
    
end % of if ANALYSIS.analysis_mode


% Define x/y-axis limits and tick marks

% Y-axis depends on analysis mode
if ANALYSIS.analysis_mode ~= 3 % If not using SVR
    
    PLOT.Y_min = 40; % Y axis lower bound (in percent accuracy)
    PLOT.Y_max = 80; % Y axis upper bound (in percent accuracy)
    PLOT.Ysteps = 5; % Interval between Y axis labels/tick marks
    
elseif ANALYSIS.analysis_mode == 3 % If using SVR
    
    PLOT.Y_min = -0.5; % Y axis lower bound (Fisher-Z-transformed correlation coefficient)
    PLOT.Y_max = 0.5; % Y axis upper bound (Fisher-Z-transformed correlation coefficient)
    PLOT.Ysteps = 0.1; % Interval between Y axis labels/tick marks
    
end % of if ANALYSIS.analysis_mode

PLOT.X_min = 1; % X axis lower bound (first time point)
PLOT.X_max = ANALYSIS.xaxis_scale(2,end); % Maximum value of X axis value. 
% Default is ANALYSIS.xaxis_scale(2,end) which is the last time window selected for group-level analyses.

% Automated calculations (no input required)
PLOT.Xsteps = ANALYSIS.step_width_ms;

% Determine Y axis ticks
PLOT.Ytick = [PLOT.Y_min : PLOT.Ysteps : PLOT.Y_max];

% Determine X axis ticks
PLOT.Xtick = [ANALYSIS.xaxis_scale(1,1) : PLOT.x_tick_spacing : ANALYSIS.xaxis_scale(1, end)];
PLOT.XtickLabel = ANALYSIS.xaxis_scale(2, 1 : PLOT.x_tick_spacing : end) - ANALYSIS.pointzero; 



%% Define Properties of Lines Showing Decoding Performance and Error Bars

% Actual (not permuted labels) decoding results

% Settings depend on plotting mode
if strcmpi(ANALYSIS.disp.plotting_mode, 'cooper')
    
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
    
    % Alpha level (0-1) for shading that depicts standard errors. Higher values
    % denote stronger (more opaque) shading
    PLOT.Res.ShadingAlpha = 0.3;

elseif strcmpi(ANALYSIS.disp.plotting_mode, 'classic')

    PLOT.Res.Line = '-ks'; % Line colour and style
    
    PLOT.Res.LineColour = 'black';
    
    % Error bar plotting settings
    PLOT.Res.Error = 'black'; % Line colour and style
    PLOT.Res.ErrorLineWidth = 0.5;
    PLOT.Res.ErrorLine = 'none'; % Disables lines between error bars across steps

    
end % of if strcmpi ANALYSIS.disp.plotting_mode

PLOT.Res.LineWidth = 2; % Default 2
PLOT.Res.MarkerEdgeColor = 'k'; % Default 'k' (black)
PLOT.Res.MarkerFaceColor = 'w'; % Default 'w' (white)
PLOT.Res.MarkerSize = 5; % Default 5

% Error bar plotting
PLOT.Res.Error = 'k'; % Line colour and style. Default 'k' (black)
PLOT.Res.ErrorLineWidth = 0.5; % Default 0.5
PLOT.Res.ErrorLine = 'none'; % Entering 'none' disables lines between error bars across steps

% Properties of line showing permuted labels / chance results
% Settings depend on plotting mode
if strcmpi(ANALYSIS.disp.plotting_mode, 'cooper')
    
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
    
elseif strcmpi(ANALYSIS.disp.plotting_mode, 'classic')

    PLOT.PermRes.Line = '-ks'; % Line colour and style
    
    PLOT.PermRes.LineColour = 'blue';
    
    % Error bar plotting settings
    PLOT.PermRes.Error = 'blue'; % Line colour and style
    PLOT.PermRes.ErrorLineWidth = 0.5;
    PLOT.PermRes.ErrorLine = 'none'; % Disables lines between error bars across steps
    
end % of if strcmpi ANALYSIS.disp.plotting_mode


PLOT.PermRes.LineWidth = 2; % Default 2
PLOT.PermRes.MarkerEdgeColor = 'b'; % Default 'b' (black)
PLOT.PermRes.MarkerFaceColor = 'w'; % Default 'w' (white)
PLOT.PermRes.MarkerSize = 5; % Default 5

% Error bars for chance/permuted labels results
PLOT.PermRes.Error = 'b'; % Line colour and style. Default 'b' (black)
PLOT.PermRes.ErrorLineWidth = 0.5; % Default 0.5
PLOT.PermRes.ErrorLine = 'none'; % Entering 'none' disables lines between error bars across steps




%% Decoding Performance Plot Annotations

% Define properties of line showing event onset
PLOT.PointZero.Color = [0.5, 0.5, 0.5]; % Colour of line denoting event onset. Default [0.5, 0.5, 0.5] (gray)
PLOT.PointZero.LineWidth = 3; % Width of line denoting event onset. Default 3
PLOT.PointZero.Point = find(ANALYSIS.data(3,:) == 1);

% Define properties of statistical significance markers
% PLOT.Sign.LineColor = 'y'; % Default 'y' (yellow)
PLOT.Sign.LineWidth = 10; % Default 10

% Positions of statistical significance markers
if ANALYSIS.analysis_mode ~= 3 % If not using SVR
    
    PLOT.Sign.LinePos = [PLOT.Y_min + 0.5, PLOT.Y_max - 0.5];
    
elseif ANALYSIS.analysis_mode == 3 % If using SVR
    
    PLOT.Sign.LinePos = [PLOT.Y_min, PLOT.Y_max];
    
end % of if ANALYSIS.analysis_mode




%% Feature Weights Results Plotting Settings

% Maps and stats for averaged analysis time windows
ANALYSIS.fw.display_average_zmap = 1; % z-standardised average FWs
ANALYSIS.fw.display_average_uncorr_threshmap = 1; % thresholded map uncorrected t-test results
ANALYSIS.fw.display_average_corr_threshmap = 1; % thresholded map t-test results corrected for multiple comparisons

% Maps and stats for each analysis time window
ANALYSIS.fw.display_all_zmaps = 1; % z-standardised average FWs
ANALYSIS.fw.display_all_uncorr_thresh_maps = 1; % thresholded map uncorrected t-test results
ANALYSIS.fw.display_all_corr_thresh_maps = 1; % thresholded map t-test results corrected for multiple comparisons

% Extra plotting options:
ANALYSIS.fw.colormap = 'jet'; % Colormap for plotting of feature weights scalp maps




%% Plot the Classification Accuracy / SVR Performance Results

if PLOT.decoding_performance_results
    
    fprintf('\n------------------------------------------------------------------------\nPlotting group decoding performance results\n------------------------------------------------------------------------\n');
    
    display_group_results_erp(ANALYSIS, PLOT);
    
end % of if PLOT.decoding_performance



%% Plot Feature Weights Results

if PLOT.feature_weights_results
    
    fprintf('\n------------------------------------------------------------------------\nPlotting feature weights results\n------------------------------------------------------------------------\n');
    
    display_feature_weights_results(ANALYSIS, FW_ANALYSIS);
     
end % of if PLOT.feature_weights