% EXAMPLE_plot_indiv_results.m
%
% This script is used for plotting single subject classifier accuracy
% or SVR performance results. 
%
% More information about the plotting settings in this script can be found
% in the DDTBOX Wiki, available at: https://github.com/DDTBOX/DDTBOX/wiki
%
% Please make copies of this script for your own projects.
%
% This script calls display_indiv_results_erp
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



%% Housekeeping

% Clears the workspace and closes all figure windows
clear variables;
close all;



%% Filepaths of Single Subject Results Files

% The following variables are used to locate the saved single subject results files

% Select subject datasets to plot, e.g. sbj_todo = [1:10] for first ten subjects
sbj_todo = [1:10];

% Specify directory in which decoding results were saved
output_dir = '/Desktop/My Study/Decoding Results';

% Name of the study (used for finding single subject results files)
study_name = 'EXAMPLE';

% Name(s) of the discrimination groups used
dcg_labels{1} = 'Correct vs. Error';
dcg_labels{2} = ''; % Use this second entry when plotting cross-decoding results

% Decoding parameters
cross = 0; % Specify whether cross-decoding was performed (0 = no / 1 = yes)
analysis_mode = 1; % ANALYSIS mode (1 = SVC with LIBSVM / 2 = SVC with LIBLINEAR / 3 = SVR with LIBSVM)
stmode = 3; % SPACETIME mode (1 = spatial / 2 = temporal / 3 = spatio-temporal)
avmode = 1; % AVERAGE mode (1 = no averaging; single-trials / 2 = run averaged data)
window_width_ms = 10; % Width of the sliding analysis window in ms
step_width_ms = 10; % Step size with which the sliding analysis window was moved through the trial

% Create labels based on SVM method used (no input required)
switch analysis_mode
    
    case 1 % SVC with LIBSVM
        
        analysis_mode_label = 'SVM_LIBSVM';
        
    case 2 % SVC with LIBLINEAR
        
        analysis_mode_label = 'SVM_LIBLIN';
        
    case 3 % SVR with LIBSVM
        
        analysis_mode_label = 'SVR_LIBSVM';
        
end % of avmode switch




%% Settings for Plotting Decoding Performance Results

PLOT.perm_disp = 1; % display the results from permuted labels decoding in figure as separate line? 0 = no / 1 = yes
PLOT.pointzero = 1; % Time of the event of interest (e.g. stimulus presentation), relative to the start of the epoch (in ms)

cfg.plotting_mode = 'cooper'; % Plotting style. Current options are 'cooper' and 'classic'

% Temporal decoding results plotting settings
PLOT.channellocs = ['/Desktop/My Study/Channel Locations/']; % Path of directory containing channel information file
PLOT.channel_names_file = 'channel_information.mat'; % Name of .mat file containing channel labels and channel locations
PLOT.temporal_decoding_colormap = 'jet'; % Colormap for temporal decoding results scalp maps

% figure position on the screen
PLOT.FigPos = [100, 100, 800, 400]; % Default [100, 100, 800, 400]

% Background colour of the figure. Default is [1, 1, 1] white
PLOT.background_colour = [1, 1, 1]; 

% Figure title settings
PLOT.TitleFontSize = 18; % Default 18
PLOT.TitleFontWeight = 'Bold'; % 'Normal' (Regular) or 'Bold'



%% Decoding Performance X and Y Axis Properties

% Axis label properties
PLOT.xlabel.FontSize = 16; % Default 16
PLOT.ylabel.FontSize = 16; % Default 16
PLOT.xlabel.FontWeight = 'Bold'; % 'Normal' (Regular) or 'b' / 'Bold'
PLOT.ylabel.FontWeight = 'Bold'; % 'Normal' (Regular) or 'b' / 'Bold'

% Spacing of X and Y tick labels
PLOT.x_tick_spacing = 5; % Number of time steps between X ticks
PLOT.y_tick_spacing = 10; % Spacing of Y axis ticks (default 10)

% Font size of X and Y axis tick labels
PLOT.XY_tick_labels_fontsize = 14;



%% Define Properties of Lines Showing Decoding Performance

% Actual (not permuted labels) decoding results
% Settings depend on plotting mode
if strcmpi(cfg.plotting_mode, 'cooper')
    
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

elseif strcmpi(cfg.plotting_mode, 'classic')

    PLOT.Res.Line = '-ks'; % Line colour and style
    
    PLOT.Res.LineColour = 'black';
    
end % of if strcmpi ANALYSIS.disp.plotting_mode


PLOT.Res.LineWidth = 2; % Default 2
PLOT.Res.MarkerEdgeColor = 'k'; % Default 'k' (black)
PLOT.Res.MarkerFaceColor = 'w'; % Default 'w' (white)
PLOT.Res.MarkerSize = 5; % Default 5


% Properties of line showing permuted labels / chance results
% Properties of line showing permuted labels / chance results
% Settings depend on plotting mode
if strcmpi(cfg.plotting_mode, 'cooper')
    
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
    
elseif strcmpi(cfg.plotting_mode, 'classic')

    PLOT.PermRes.Line = '-ks'; % Line colour and style
    
    PLOT.PermRes.LineColour = 'blue';
    
end % of if strcmpi ANALYSIS.disp.plotting_mode

PLOT.PermRes.LineWidth = 2; % Default 2
PLOT.PermRes.MarkerEdgeColor = 'b'; % Default 'b' (blue)
PLOT.PermRes.MarkerFaceColor = 'w'; % Default 'w' (white)
PLOT.PermRes.MarkerSize = 5; % Default 5



%% Decoding Performance Plot Annotations

% Define properties of line showing event onset
PLOT.PointZero.Color = [0.5, 0.5, 0.5]; % Colour of line denoting event onset. Default [0.5, 0.5, 0.5] (gray)
PLOT.PointZero.LineWidth = 3; % Width of line denoting event onset. Default 3



%% Plot the Classification Accuracy/SVR Performance Results

for sbj = sbj_todo % Plot for all selected subjects

    if cross == 0 % If not using cross-decoding
        
        % Load single subject results file
        load([output_dir, '/', study_name, ...
            '_SBJ', int2str(sbj), ...
            '_win', int2str(window_width_ms), ...
            '_steps', int2str(step_width_ms), ...
            '_av', int2str(avmode), ...
            '_st', int2str(stmode), ...
            '_', analysis_mode_label, '_DCG', dcg_labels{1} '.mat']);
        
    elseif cross == 1 % If using cross-decoding
        
        load([output_dir, '/', study_name, ...
            '_SBJ', int2str(sbj), ...
            '_win', int2str(window_width_ms), ...
            '_steps', int2str(step_width_ms), ...
            '_av', int2str(avmode), ...
            '_st', int2str(stmode), ...
            '_', analysis_mode_label, '_DCG', dcg_labels{1}, 'toDCG', dcg_labels{2}, '.mat']);
        
    end % of if cross
    
    % Overwrite selected cfg settings related to plotting results
    cfg.perm_disp = PLOT.perm_disp;
    cfg.pointzero = PLOT.pointzero;
    
    % Plot the single subject results
    display_indiv_results_erp(cfg, RESULTS, PLOT);

end % of for sbj