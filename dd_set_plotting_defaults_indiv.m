function PLOT = dd_set_plotting_defaults_indiv
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
%
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

PLOT.FigPos = [100 100 800 400];



%% Figure Title

PLOT.TitleFontSize = 14;
PLOT.TitleFontWeight = 'Bold'; % 'Normal' (Regular) or 'Bold'



%% X and Y Axis Properties

% Axis label properties
PLOT.xlabel.FontSize = 12;
PLOT.ylabel.FontSize = 12;
PLOT.xlabel.FontWeight = 'Bold'; % 'Normal' (Regular) or 'b' / 'Bold'
PLOT.ylabel.FontWeight = 'Bold'; % 'Normal' (Regular) or 'b' / 'Bold'



%% Lines Showing Decoding Performance

% Actual decoding results
PLOT.Res.Line = '-ks'; % Line colour and style
PLOT.Res.LineWidth = 2;
PLOT.Res.MarkerEdgeColor = 'k';
PLOT.Res.MarkerFaceColor = 'w';
PLOT.Res.MarkerSize = 5;

% Properties of line showing permutation / chance results
PLOT.PermRes.Line = '-ks'; % Line colour and style
PLOT.PermRes.LineWidth = 2;
PLOT.PermRes.MarkerEdgeColor = 'b';
PLOT.PermRes.MarkerFaceColor = 'w';
PLOT.PermRes.MarkerSize = 5;



%% Line Marking Event Onset

% Define properties of line showing event onset
PLOT.PointZero.Color = 'r'; % Colour of line denoting event onset
PLOT.PointZero.LineWidth = 3; % Width of line denoting event onset



%% Temporal Decoding Results Plotting Settings

PLOT.temporal_decoding_colormap = 'jet'; % Colormap for temporal decoding results scalp maps