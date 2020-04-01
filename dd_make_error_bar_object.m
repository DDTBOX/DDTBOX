function [patch_x, patch_y] = dd_make_error_bar_object(x_values, y_values, error_values)
%
% This function generates a shaded patch that represents the standard
% errors of group decoding accuracy estimates. Note that shaded regions are
% interpolated across adjacent timepoints. 
%
% This function is called by display_group_results_erp,
% but can also be called by custom plotting scripts such as
% EXAMPLE_plot_group_results.
% 
%
% Inputs:
%
%   x_values        X values corresponding to each time step
%
%   y_values        Measures of central tendency for group decoding accuracy 
%                   (e.g., mean decoding accuracy values) at each time step
%
%   error_values    Error magnitudes (standard errors) for each time step
%
%
% Outputs:
% 
%   patch_x         X values for the shading polygon depicting standard
%                   errors
%
%   patch_y         Y values for the shading polygon depicting standard
%                   errors
%
%
%
% Usage:        [patch_x, patch_y] = dd_make_error_bar_object(x_values, y_values, error_values)
%
%
% Copyright (c) 2013-2020: DDTBOX has been developed by Stefan Bode 
% and Daniel Feuerriegel with contributions from Daniel Bennett and 
% Phillip M. Alday, and others. 
%
% This file is part of DDTBOX and has been written by Patrick Cooper.
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



%% Create Error Shading Object

% Define patch edges (y values +- error values)
upper_edges = y_values + error_values;
lower_edges = y_values - error_values;

% Make the patch
y_vals_patch = [lower_edges, fliplr(upper_edges)];
x_vals_patch = [x_values, fliplr(x_values)];

% Remove nans otherwise patch won't work
x_vals_patch(isnan(y_vals_patch)) = [];
y_vals_patch(isnan(y_vals_patch)) = [];

% Assign values to the variables output by the function
patch_x = x_vals_patch;
patch_y = y_vals_patch(1,:);