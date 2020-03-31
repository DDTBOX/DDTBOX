function [patch_x, patch_y] = dd_make_error_bar_object(x_values, y_values, error_values)
%
% NEED TO INSERT DDTBOX COMPATIBLE HEADER HERE

% Define patch edges (y values +- error values)
upper_edges = y_values + error_values;
lower_edges = y_values - error_values;

% Make the patch
y_vals_patch = [lower_edges, fliplr(upper_edges)];
x_vals_patch = [x_values, fliplr(x_values)];

% Remove nans otherwise patch won't work
x_vals_patch(isnan(y_vals_patch)) = [];
y_vals_patch(isnan(y_vals_patch)) = [];

patch_x = x_vals_patch;
patch_y = y_vals_patch(1,:);